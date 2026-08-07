import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/payment_result_model.dart';
import '../models/payment_session_model.dart';

/// Talks to the buffet top-up endpoints over the shared [Dio] instance (base
/// URL and bearer token come from the interceptor).
abstract class PaymentService {
  Future<PaymentSessionModel> startTopUp(double amount);
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
          throw const ServerException('Ödəniş linki alınmadı');
        }
      }

      throw ServerException(_messageFrom(data, 'Ödəniş başladıla bilmədi'));
    } on DioException catch (e) {
      // 502 (gateway unreachable) lands here: validateStatus only lets 4xx
      // through, everything from 500 up throws.
      throw ServerException(
        _dioMessage(e, 'Ödəniş sistemi ilə əlaqə qurulmadı'),
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

      throw ServerException(_messageFrom(data, 'Ödənişin statusu alınmadı'));
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e, 'Ödənişin statusu alınmadı'));
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
      return 'Serverə qoşulmaq mümkün olmadı';
    }
    return _messageFrom(e.response?.data, fallback);
  }
}
