import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/timetable_content_model.dart';

/// Talks to the class-timetable endpoint over the shared [Dio] instance (base
/// URL and bearer token come from the interceptor). Throws typed exceptions so
/// the repository can map them to [Failure]s.
abstract class TimetableService {
  /// [classId] comes from the login response. The endpoint falls back to the
  /// student's own session when it is omitted.
  Future<TimetableContentModel> getTimetable({int? classId});
}

class TimetableServiceImpl implements TimetableService {
  final Dio dio;
  const TimetableServiceImpl(this.dio);

  @override
  Future<TimetableContentModel> getTimetable({int? classId}) async {
    try {
      final response = await dio.get(
        '/classtimetable',
        queryParameters: {'class_id': ?classId},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return TimetableContentModel.fromJson(data);
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
    return 'Dərs cədvəli yüklənmədi';
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
