import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/news_page_model.dart';

/// Talks to the news endpoint over the shared [Dio] instance (base URL and
/// bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class NewsService {
  /// [page] is 1-based; the endpoint paginates at 20 entries per page.
  Future<NewsPageModel> getNews({int page});
}

class NewsServiceImpl implements NewsService {
  final Dio dio;
  const NewsServiceImpl(this.dio);

  @override
  Future<NewsPageModel> getNews({int page = 1}) async {
    try {
      final response = await dio.get(
        '/getNews',
        queryParameters: {'page': page},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return NewsPageModel.fromJson(data);
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
    return 'Xəbərlər yüklənmədi';
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
