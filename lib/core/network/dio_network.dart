import 'package:dio/dio.dart';

class DioNetwork {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://laravel.bsb.edu.az/api/v2',
      headers: {
        'Content-Type':'application/json'
      }
    )
  );
}