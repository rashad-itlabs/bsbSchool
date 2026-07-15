import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/attendance_content_model.dart';

/// Talks to the attendance endpoint over the shared [Dio] instance (base URL
/// and bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class AttendanceService {
  Future<AttendanceContentModel> getAttendance();
}

class AttendanceServiceImpl implements AttendanceService {
  final Dio dio;
  const AttendanceServiceImpl(this.dio);

  @override
  Future<AttendanceContentModel> getAttendance() async {
    try {
      final response = await dio.get('/attendance');

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return AttendanceContentModel.fromJson(data);
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
    return 'Davamiyyət yüklənmədi';
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
