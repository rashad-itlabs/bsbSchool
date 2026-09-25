import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/l10n/l10n.dart';
import '../models/weekly_feedback_content_model.dart';

/// Talks to the weekly feedback endpoint over the shared [Dio] instance (base
/// URL and bearer token come from the interceptor). Throws typed exceptions so
/// the repository can map them to [Failure]s.
abstract class WeeklyFeedbackService {
  /// [studentId] scopes the request to one of a parent's students; [week]
  /// picks the week whose feedback comes back. Either omitted, the endpoint
  /// falls back to the token's student and the current week.
  Future<WeeklyFeedbackContentModel> getWeeklyFeedback({
    int? studentId,
    int? week,
  });
}

class WeeklyFeedbackServiceImpl implements WeeklyFeedbackService {
  /// Backend route. Kept here so a rename on the Laravel side is a one-line
  /// change.
  static const String path = '/weekly_feedback';

  final Dio dio;
  const WeeklyFeedbackServiceImpl(this.dio);

  @override
  Future<WeeklyFeedbackContentModel> getWeeklyFeedback({
    int? studentId,
    int? week,
  }) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: {'student_id': ?studentId, 'week': ?week},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        // A 200 can still carry a refusal in the body.
        if (data['success'] == false) {
          throw ServerException(_messageFrom(data));
        }
        return WeeklyFeedbackContentModel.fromJson(data);
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
    return L.s.errWeeklyFeedbackLoad;
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
