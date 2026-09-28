import 'dart:typed_data';

import 'package:bsbschool/core/error/exceptions.dart';
import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/features/payment/data/services/payment_service.dart';
import 'package:bsbschool/features/payment/domain/entities/payment_result.dart';
import 'package:bsbschool/features/payment/domain/entities/payment_session.dart';
import 'package:bsbschool/features/payment/domain/repositories/payment_repository.dart';
import 'package:bsbschool/features/payment/domain/usecases/get_payment_status.dart';
import 'package:bsbschool/features/payment/domain/usecases/get_tuition_payment_status.dart';
import 'package:bsbschool/features/payment/domain/usecases/start_fee_payment.dart';
import 'package:bsbschool/features/payment/domain/usecases/start_top_up.dart';
import 'package:bsbschool/features/payment/domain/usecases/start_tuition_payment.dart';
import 'package:bsbschool/features/payment/presentation/cubit/payment_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What `POST /tuition/pay` answers with.
const _sessionBody = '''
{
    "success": true,
    "reference": "TUI-abc",
    "amount": 350,
    "currency": "AZN",
    "payment_url": "https://pay.yigim.az/checkout/abc",
    "status_url": "https://online.bsb.edu.az/api/v1/tuition/payment/status?reference=TUI-abc",
    "reused": false,
    "return_urls": {
        "success": "https://online.bsb.edu.az/api/v1/tuition/payment/return/success",
        "fail": "https://online.bsb.edu.az/api/v1/tuition/payment/return/fail"
    }
}
''';

/// Answers every request from a canned body while recording what was asked.
class _RecordingAdapter implements HttpClientAdapter {
  final String body;
  final int statusCode;
  RequestOptions? request;

  _RecordingAdapter({required this.body, this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(PaymentServiceImpl, _RecordingAdapter) _service({
  String body = _sessionBody,
  int statusCode = 200,
}) {
  final adapter = _RecordingAdapter(body: body, statusCode: statusCode);
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://online.bsb.edu.az/api/v1',
      validateStatus: (status) => status != null && status < 500,
    ),
  )..httpClientAdapter = adapter;
  return (PaymentServiceImpl(dio), adapter);
}

/// Records which status route the cubit asked.
class _FakeRepository implements PaymentRepository {
  final asked = <String>[];

  PaymentResult _result(String reference) => PaymentResult(
        reference: reference,
        status: PaymentStatus.success,
        amount: 350,
        currency: 'AZN',
        message: 'OK',
      );

  @override
  Future<Either<Failure, PaymentResult>> getStatus(String reference) async {
    asked.add('payment');
    return Right(_result(reference));
  }

  @override
  Future<Either<Failure, PaymentResult>> getTuitionStatus(
      String reference) async {
    asked.add('tuition');
    return Right(_result(reference));
  }

  @override
  Future<Either<Failure, PaymentSession>> startTuitionPayment(
      double amount) async {
    asked.add('start-tuition:$amount');
    return Right(PaymentSession(
      reference: 'TUI-abc',
      amount: amount,
      currency: 'AZN',
      paymentUrl: Uri.parse('https://pay.yigim.az/checkout/abc'),
      successReturnUrl: '',
      failReturnUrl: '',
    ));
  }

  @override
  Future<Either<Failure, PaymentSession>> startTopUp(double amount) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, PaymentSession>> startFeePayment({
    required int feeId,
    required double amount,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('POST /tuition/pay', () {
    test('sends the amount, the active student and the language', () async {
      final (service, adapter) = _service();

      final session =
          await service.startTuitionPayment(amount: 350, studentId: 3789);

      expect(adapter.request?.path, '/tuition/pay');
      expect(adapter.request?.method, 'POST');
      expect(adapter.request?.data,
          {'amount': 350.0, 'student_id': 3789, 'lang': 'az'});
      expect(session.reference, 'TUI-abc');
      expect(session.paymentUrl.host, 'pay.yigim.az');
      expect(session.successReturnUrl, endsWith('/tuition/payment/return/success'));
      expect(session.failReturnUrl, endsWith('/tuition/payment/return/fail'));
    });

    test('rounds the amount to qəpik and leaves out a missing student',
        () async {
      final (service, adapter) = _service();

      await service.startTuitionPayment(amount: 120.456);

      expect(adapter.request?.data, {'amount': 120.46, 'lang': 'az'});
    });

    test('a refusal surfaces the server\'s own message', () async {
      final (service, _) = _service(
        statusCode: 422,
        body: '{"message": "x", "errors": {"amount": ["Məbləğ borcdan çoxdur"]}}',
      );

      expect(
        () => service.startTuitionPayment(amount: 99999),
        throwsA(isA<ServerException>().having(
            (e) => e.message, 'message', 'Məbləğ borcdan çoxdur')),
      );
    });
  });

  test('GET /tuition/payment/status reads the outcome of a reference',
      () async {
    final (service, adapter) = _service(
      body: '{"reference": "TUI-abc", "status": "success", "amount": 350, '
          '"receipt_no": "R-17", "balance": 850, "message": "Ödəniş uğurludur"}',
    );

    final result = await service.getTuitionStatus('TUI-abc');

    expect(adapter.request?.path, '/tuition/payment/status');
    expect(adapter.request?.queryParameters, {'reference': 'TUI-abc'});
    expect(result.isSuccess, isTrue);
    expect(result.amount, 350);
  });

  test('a tuition checkout is confirmed through the tuition status route',
      () async {
    final repository = _FakeRepository();
    final cubit = PaymentCubit(
      startTopUp: StartTopUp(repository),
      startFeePayment: StartFeePayment(repository),
      startTuitionPayment: StartTuitionPayment(repository),
      getPaymentStatus: GetPaymentStatus(repository),
      getTuitionPaymentStatus: GetTuitionPaymentStatus(repository),
    );
    addTearDown(cubit.close);

    final session = await cubit.startTuition(350);
    final result = await cubit.confirm(
      session!.reference,
      bankSaidSuccess: true,
      tuition: true,
    );

    expect(repository.asked, ['start-tuition:350.0', 'tuition']);
    expect(result?.isSuccess, isTrue);
  });
}
