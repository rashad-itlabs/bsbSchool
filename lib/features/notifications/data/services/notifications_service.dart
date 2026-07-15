import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/notifications_content_model.dart';

/// Talks to the notifications endpoint over the shared [Dio] instance (base URL
/// and bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class NotificationsService {
  /// [classId] comes from the login response. The endpoint falls back to the
  /// student's own session when it is omitted.
  Future<NotificationsContentModel> getNotifications({int? classId});
}

class NotificationsServiceImpl implements NotificationsService {
  final Dio dio;
  const NotificationsServiceImpl(this.dio);

  @override
  Future<NotificationsContentModel> getNotifications({int? classId}) async {
    try {
      final response = await dio.get(
        '/notifications',
        queryParameters: {'class_id': ?classId},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return NotificationsContentModel.fromJson(data);
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
    return 'Bildirişlər yüklənmədi';
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
