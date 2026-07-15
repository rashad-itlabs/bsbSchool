import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/homework_content_model.dart';

/// Talks to the homework endpoint over the shared [Dio] instance (base URL and
/// bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class HomeworkService {
  /// [classId] comes from the login response. The endpoint falls back to the
  /// student's own session when it is omitted.
  Future<HomeworkContentModel> getHomeworks({int? classId});
}

class HomeworkServiceImpl implements HomeworkService {
  final Dio dio;
  const HomeworkServiceImpl(this.dio);

  @override
  Future<HomeworkContentModel> getHomeworks({int? classId}) async {
    try {
      final response = await dio.get(
        '/homework',
        queryParameters: {'class_id': ?classId},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return HomeworkContentModel.fromJson(data);
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
    return 'Tapşırıqlar yüklənmədi';
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
