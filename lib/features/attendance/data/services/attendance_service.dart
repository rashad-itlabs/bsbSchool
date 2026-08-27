import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/attendance_content_model.dart';
import '../../../../core/l10n/l10n.dart';

/// Talks to the attendance endpoint over the shared [Dio] instance (base URL
/// and bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class AttendanceService {
  /// [studentId] scopes the request to one of a parent's students. Omitted the
  /// endpoint falls back to the student the token belongs to.
  Future<AttendanceContentModel> getAttendance({int? studentId});
}

class AttendanceServiceImpl implements AttendanceService {
  final Dio dio;
  const AttendanceServiceImpl(this.dio);

  @override
  Future<AttendanceContentModel> getAttendance({int? studentId}) async {
    try {
      final response = await dio.get(
        '/attendance',
        queryParameters: {'student_id': ?studentId},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return AttendanceContentModel.fromJson(data);
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
    return L.s.errAttendanceLoad;
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
