import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/buffet_card_content_model.dart';

/// Talks to the buffet-card endpoint over the shared [Dio] instance (base URL
/// and bearer token come from the interceptor). Throws typed exceptions so the
/// repository can map them to [Failure]s.
abstract class BuffetCardService {
  Future<BuffetCardContentModel> getBuffetCard();
}

class BuffetCardServiceImpl implements BuffetCardService {
  final Dio dio;
  const BuffetCardServiceImpl(this.dio);

  @override
  Future<BuffetCardContentModel> getBuffetCard() async {
    try {
      final response = await dio.get('/getBuffetCart');

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        return BuffetCardContentModel.fromJson(data);
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
    return 'Bufet kartı yüklənmədi';
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
