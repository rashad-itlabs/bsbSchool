import 'dart:typed_data';

import 'package:bsbschool/core/error/exceptions.dart';
import 'package:bsbschool/features/payment/data/services/payment_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What `POST /pay/{id}` answers with — the same body as the top-up endpoint.
const _sessionBody = '''
{
    "success": true,
    "reference": "MOB-abc",
    "amount": 20,
    "currency": "AZN",
    "payment_url": "https://bank.example/checkout/abc",
    "return_urls": {
        "success": "https://laravel.bsb.edu.az/payment/return/success",
        "fail": "https://laravel.bsb.edu.az/payment/return/fail"
    }
}
''';

/// Answers every request from a canned body while recording what was asked,
/// so the test can pin the path and payload the service actually sends.
class _RecordingAdapter implements HttpClientAdapter {
  final String body;
  final int statusCode;

  RequestOptions? request;

  _RecordingAdapter({this.body = _sessionBody, this.statusCode = 200});

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
      baseUrl: 'https://laravel.bsb.edu.az/api/v2',
      // Mirrors ApiClient: 4xx bodies are read, not thrown away.
      validateStatus: (status) => status != null && status < 500,
    ),
  )..httpClientAdapter = adapter;
  return (PaymentServiceImpl(dio), adapter);
}

void main() {
  test('posts to /pay/{feeId} with the fee row id, not the student', () async {
    final (service, adapter) = _service();

    final session = await service.startFeePayment(feeId: 3, amount: 20);

    // `fees[].id` from GET /extra_fees. The student id (2570) here is what
    // made the API answer "Payment not found".
    expect(adapter.request?.path, '/pay/3');
    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.data, {'amount': 20.0, 'language': 'az'});
    expect(session.reference, 'MOB-abc');
    expect(session.paymentUrl.host, 'bank.example');
  });

  test('sends the amount with two decimals, the way the API stores it', () async {
    final (service, adapter) = _service();

    await service.startFeePayment(feeId: 7, amount: 19.999);

    expect(adapter.request?.path, '/pay/7');
    expect((adapter.request?.data as Map)['amount'], 20.0);
  });

  test('surfaces the server message when the id does not resolve', () async {
    final (service, _) = _service(
      body: '{"message": "Payment not found"}',
      statusCode: 404,
    );

    expect(
      () => service.startFeePayment(feeId: 2570, amount: 20),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          'Payment not found',
        ),
      ),
    );
  });

  test('a 200 body without a payment url is still an error', () async {
    final (service, _) = _service(body: '{"success": true}');

    expect(
      () => service.startFeePayment(feeId: 3, amount: 20),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          'Ödəniş linki alınmadı',
        ),
      ),
    );
  });
}
