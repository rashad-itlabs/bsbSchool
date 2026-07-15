import 'package:dio/dio.dart';

/// Abstraction over connectivity so repositories can decide between
/// remote and cached data without depending on a concrete package.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Dio dio;
  const NetworkInfoImpl(this.dio);

  @override
  Future<bool> get isConnected async {
    // A lightweight reachability check. Swap for `connectivity_plus`
    // or `internet_connection_checker` in production.
    try {
      final response = await dio.get(
        'https://clients3.google.com/generate_204',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
