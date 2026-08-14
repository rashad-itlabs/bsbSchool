import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/tuition_content_model.dart';

/// Talks to the tuition endpoint over the shared [Dio] instance (base URL and
/// bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class TuitionService {
  /// [studentId] scopes the request to one of a parent's students. Omitted, the
  /// endpoint falls back to the student the token belongs to.
  Future<TuitionContentModel> getTuition({int? studentId});
}

class TuitionServiceImpl implements TuitionService {
  final Dio dio;
  const TuitionServiceImpl(this.dio);

  @override
  Future<TuitionContentModel> getTuition({int? studentId}) async {
    try {
      final response = await dio.get(
        '/tuition',
        queryParameters: {'student_id': ?studentId},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      // `success: false` with a 200 is how the API reports a student it will
      // not answer for, so the flag is checked alongside the status code.
      if (status == 200 &&
          data is Map<String, dynamic> &&
          data['success'] != false) {
        return TuitionContentModel.fromJson(data);
      }

      if (status == 401) {
        throw const ServerException('Sessiya bitib, yenidən daxil olun');
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
    return 'Ödəniş məlumatları yüklənmədi';
  }

  String _dioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Serverə qoşulmaq mümkün olmadı';
    }
    return _messageFrom(e.response?.data);
  }
}
