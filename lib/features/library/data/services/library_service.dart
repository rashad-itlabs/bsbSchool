import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/library_content_model.dart';

/// Talks to the library endpoint over the shared [Dio] instance (base URL and
/// bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class LibraryService {
  /// [classId] comes from the login response. The endpoint falls back to the
  /// student's own session when it is omitted.
  Future<LibraryContentModel> getLibrary({int? classId});
}

class LibraryServiceImpl implements LibraryService {
  final Dio dio;
  const LibraryServiceImpl(this.dio);

  @override
  Future<LibraryContentModel> getLibrary({int? classId}) async {
    try {
      final response = await dio.get(
        '/library',
        queryParameters: {'class_id': ?classId},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return LibraryContentModel.fromJson(data);
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
    return 'Kitabxana məlumatları yüklənmədi';
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
