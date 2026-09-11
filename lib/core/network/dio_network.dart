import 'package:dio/dio.dart';

class DioNetwork {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://online.bsb.edu.az//api/v1',
      headers: {
        'Content-Type':'application/json'
      }
    )
  );
}