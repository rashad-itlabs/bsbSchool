import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/examination_content_model.dart';

/// Talks to the examinations endpoint over the shared [Dio] instance (base URL
/// and bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class ExaminationService {
  /// The endpoint resolves the student from the session token and echoes the
  /// `student_id` back in the body, so no parameters are needed here.
  Future<ExaminationContentModel> getExaminations();
}

class ExaminationServiceImpl implements ExaminationService {
  final Dio dio;
  const ExaminationServiceImpl(this.dio);

  @override
  Future<ExaminationContentModel> getExaminations() async {
    try {
      final response = await dio.get('/examinations');

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return ExaminationContentModel.fromJson(data);
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
    return 'İmtahan nəticələri yüklənmədi';
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
