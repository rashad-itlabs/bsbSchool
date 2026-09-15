import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/app_version_model.dart';

/// Reads the version gate the backend publishes. No token: it is asked before
/// the login screen, and a signed-out parent can be on an unsupported build
/// just as easily as a signed-in one.
abstract class AppVersionService {
  Future<AppVersionModel> fetch({required String platform});
}

class AppVersionServiceImpl implements AppVersionService {
  /// Backend route behind the config values in `config/app_version.php`.
  static const String appVersionPath = '/appVersion';

  final Dio dio;
  const AppVersionServiceImpl(this.dio);

  @override
  Future<AppVersionModel> fetch({required String platform}) async {
    try {
      final response = await dio.get(
        appVersionPath,
        queryParameters: {'platform': platform},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        if (data['success'] == false) throw const ServerException();
        return AppVersionModel.fromJson(data);
      }

      throw const ServerException();
    } on DioException {
      // Offline, a timeout, a 500 — the caller carries on regardless, so
      // there is nothing to word for the parent here.
      throw const ServerException();
    }
  }
}
