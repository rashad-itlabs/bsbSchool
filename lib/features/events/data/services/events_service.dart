import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/school_event_model.dart';
import '../../../../core/l10n/l10n.dart';

/// Talks to the events endpoint over the shared [Dio] instance (base URL and
/// bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to `Failure`s.
abstract class EventsService {
  /// The whole school year in one call — the endpoint is not paginated.
  Future<List<SchoolEventModel>> getEvents();
}

class EventsServiceImpl implements EventsService {
  final Dio dio;
  const EventsServiceImpl(this.dio);

  @override
  Future<List<SchoolEventModel>> getEvents() async {
    try {
      final response = await dio.get('/getEvent');

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        final raw = data['data'];
        if (raw is! List) return const [];

        return raw
            .whereType<Map>()
            .map((e) => SchoolEventModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
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
    return L.s.errEventsLoad;
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
