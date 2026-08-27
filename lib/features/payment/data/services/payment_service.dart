import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/payment_result_model.dart';
import '../models/payment_session_model.dart';
import '../../../../core/l10n/l10n.dart';

/// Talks to the buffet top-up endpoints over the shared [Dio] instance (base
/// URL and bearer token come from the interceptor).
abstract class PaymentService {
  Future<PaymentSessionModel> startTopUp(double amount);

  /// `POST /pay/{id}` — pays ONE extra fee.
  ///
  /// [feeId] is `fees[].id` from `GET /extra_fees` — the charge row itself,
  /// not the student and not `fee_id` (the shared fee definition). The server
  /// resolves the student from the fee, which is why nothing else is sent.
  ///
  /// Passing anything else here answers `Payment not found`: the route binds
  /// the id to a payment record before the controller runs.
  Future<PaymentSessionModel> startFeePayment({
    required int feeId,
    required double amount,
  });

  Future<PaymentResultModel> getStatus(String reference);
}

class PaymentServiceImpl implements PaymentService {
  final Dio dio;
  const PaymentServiceImpl(this.dio);

  @override
  Future<PaymentSessionModel> startTopUp(double amount) async {
    try {
      final response = await dio.post(
        '/payment/topup',
        data: {
          // The API validates 1..1000 and stores qəpik on its side; two
          // decimals is all it accepts back.
          'amount': double.parse(amount.toStringAsFixed(2)),
          'language': 'az',
        },
      );

      final data = response.data;

      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['success'] == true) {
        try {
          return PaymentSessionModel.fromJson(data);
        } on FormatException {
          throw ServerException(L.s.errPaymentLink);
        }
      }

      throw ServerException(_messageFrom(data, L.s.paymentCouldNotStart));
    } on DioException catch (e) {
      // 502 (gateway unreachable) lands here: validateStatus only lets 4xx
      // through, everything from 500 up throws.
      throw ServerException(
        _dioMessage(e, L.s.errPaymentGateway),
      );
    }
  }

  @override
  Future<PaymentSessionModel> startFeePayment({
    required int feeId,
    required double amount,
  }) async {
    try {
      final response = await dio.post(
        '/pay/$feeId',
        data: {
          // Same contract as the top-up endpoint: major units, two decimals,
          // and the language the bank page should render in.
          'amount': double.parse(amount.toStringAsFixed(2)),
          'language': 'az',
        },
      );

      final data = response.data;

      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['success'] != false) {
        try {
          return PaymentSessionModel.fromJson(data);
        } on FormatException {
          throw ServerException(L.s.errPaymentLink);
        }
      }

      throw ServerException(_messageFrom(data, L.s.paymentCouldNotStart));
    } on DioException catch (e) {
      throw ServerException(
        _dioMessage(e, L.s.errPaymentGateway),
      );
    }
  }

  @override
  Future<PaymentResultModel> getStatus(String reference) async {
    try {
      final response = await dio.get(
        '/payment/status',
        queryParameters: {'reference': reference},
      );

      final data = response.data;

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        return PaymentResultModel.fromJson(data);
      }

      throw ServerException(_messageFrom(data, L.s.paymentStatusUnavailable));
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e, L.s.paymentStatusUnavailable));
    }
  }

  /// Laravel answers either `{message: ...}` or a 422 with
  /// `{errors: {amount: [...]}}`; both carry the text worth showing.
  String _messageFrom(dynamic data, String fallback) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first != null) return first.toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    return fallback;
  }

  String _dioMessage(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return L.s.errNoConnection;
    }
    return _messageFrom(e.response?.data, fallback);
  }
}
