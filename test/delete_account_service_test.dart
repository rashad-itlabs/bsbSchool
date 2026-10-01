import 'dart:typed_data';

import 'package:bsbschool/core/error/exceptions.dart';
import 'package:bsbschool/features/auth/data/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers from a canned body while recording what was asked.
class _RecordingAdapter implements HttpClientAdapter {
  final String body;
  final int statusCode;
  RequestOptions? request;

  _RecordingAdapter(this.statusCode, this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(AuthServiceImpl, _RecordingAdapter) _service(int status, String body) {
  final adapter = _RecordingAdapter(status, body);
  final dio = Dio(BaseOptions(
    baseUrl: 'https://online.bsb.edu.az/api/v1',
    // Mirrors ApiClient: 4xx bodies are read, 5xx throw.
    validateStatus: (s) => s != null && s < 500,
  ))
    ..httpClientAdapter = adapter;
  return (AuthServiceImpl(dio), adapter);
}

void main() {
  test('posts the password to /deleteAccount and returns the message',
      () async {
    final (service, adapter) =
        _service(200, '{"success": true, "message": "Hesab silindi"}');

    final message = await service.deleteAccount(password: 'secret123');

    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.path, '/deleteAccount');
    expect(adapter.request?.data, {'password': 'secret123'});
    expect(message, 'Hesab silindi');
  });

  test('a wrong password (422) is reported under the password field',
      () async {
    final (service, _) = _service(422,
        '{"success": false, "errors": {"password": ["Cari şifrə yanlışdır"]}}');

    expect(
      () => service.deleteAccount(password: 'nope'),
      throwsA(isA<FieldValidationException>().having(
        (e) => e.fieldErrors['password'],
        'password error',
        'Cari şifrə yanlışdır',
      )),
    );
  });

  test('a non-parent (403) gets the server message as a plain error',
      () async {
    final (service, _) = _service(403,
        '{"success": false, "message": "Yalnız valideyn hesabı silinə bilər"}');

    expect(
      () => service.deleteAccount(password: 'secret123'),
      throwsA(isA<ServerException>().having(
        (e) => e.message,
        'message',
        'Yalnız valideyn hesabı silinə bilər',
      )),
    );
  });

  test('a rolled-back failure (500) carries the server message', () async {
    final (service, _) = _service(500,
        '{"success": false, "message": "Hesab silinmədi, yenidən cəhd edin"}');

    expect(
      () => service.deleteAccount(password: 'secret123'),
      throwsA(isA<ServerException>().having(
        (e) => e.message,
        'message',
        'Hesab silinmədi, yenidən cəhd edin',
      )),
    );
  });
}
