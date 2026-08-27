import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/extra_fees_content_model.dart';
import '../../../../core/l10n/l10n.dart';

/// Talks to the extra-fees endpoint over the shared [Dio] instance (base URL
/// and bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class ExtraFeesService {
  /// [studentId] scopes the request to one of a parent's students. Omitted, the
  /// endpoint falls back to the student the token belongs to.
  Future<ExtraFeesContentModel> getExtraFees({int? studentId});
}

class ExtraFeesServiceImpl implements ExtraFeesService {
  final Dio dio;
  const ExtraFeesServiceImpl(this.dio);

  @override
  Future<ExtraFeesContentModel> getExtraFees({int? studentId}) async {
    try {
      final response = await dio.get(
        '/extra_fees',
        queryParameters: {'student_id': ?studentId},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      // `success: false` with a 200 is how the API reports a student it will
      // not answer for, so the flag is checked alongside the status code.
      if (status == 200 &&
          data is Map<String, dynamic> &&
          data['success'] != false) {
        return ExtraFeesContentModel.fromJson(data);
      }

      if (status == 401) {
        throw ServerException(L.s.errSessionExpired);
      }

      throw ServerException(_messageFrom(data));
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  String _messageFrom(dynamic data) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return L.s.errExtraFeesLoad;
  }

  String _dioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return L.s.errNoConnection;
    }
    return _messageFrom(e.response?.data);
  }
}
