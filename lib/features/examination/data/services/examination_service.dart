import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/examination_content_model.dart';
import '../../../../core/l10n/l10n.dart';

/// Talks to the examinations endpoint over the shared [Dio] instance (base URL
/// and bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class ExaminationService {
  /// [studentId] scopes the request to one of a parent's students; omitted,
  /// the endpoint resolves the student from the session token. Either way it
  /// echoes the `student_id` it used back in the body.
  Future<ExaminationContentModel> getExaminations({int? studentId});
}

class ExaminationServiceImpl implements ExaminationService {
  final Dio dio;
  const ExaminationServiceImpl(this.dio);

  @override
  Future<ExaminationContentModel> getExaminations({int? studentId}) async {
    try {
      final response = await dio.get(
        '/examinations',
        queryParameters: {'student_id': ?studentId},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return ExaminationContentModel.fromJson(data);
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
    return L.s.errExamLoad;
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
