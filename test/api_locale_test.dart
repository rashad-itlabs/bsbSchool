import 'dart:typed_data';

import 'package:bsbschool/core/l10n/l10n.dart';
import 'package:bsbschool/core/network/api_client.dart';
import 'package:bsbschool/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the request instead of sending it.
class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '{"success": true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _RecordingAdapter adapter;
  late Dio dio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    adapter = _RecordingAdapter();
    // The app's own client: the language has to ride on every service, the
    // login included, without each one remembering to add it.
    dio = ApiClient(TokenStorageImpl(prefs)).dio..httpClientAdapter = adapter;
  });

  // `L` is process-wide; leave it on the school's language for other tests.
  tearDown(() => L.current = lookupAppL10n(const Locale('az')));

  test('a login names the app language, so the error comes back in it',
      () async {
    L.current = lookupAppL10n(const Locale('ru'));

    await dio.post('/login', data: {'email': 'a@b.c', 'password': 'x'});

    expect(adapter.request!.queryParameters['lang'], 'ru');
    expect(adapter.request!.uri.query, contains('lang=ru'));
    // The body is the login's own — nothing added to it.
    expect(adapter.request!.data, {'email': 'a@b.c', 'password': 'x'});
  });

  test('follows a language switch on the next request', () async {
    L.current = lookupAppL10n(const Locale('en'));
    await dio.get('/homework');
    expect(adapter.request!.queryParameters['lang'], 'en');

    L.current = lookupAppL10n(const Locale('az'));
    await dio.get('/homework');
    expect(adapter.request!.queryParameters['lang'], 'az');
  });

  test("keeps a service's own query and its own lang", () async {
    L.current = lookupAppL10n(const Locale('ru'));

    await dio.get('/homework', queryParameters: {'class_id': 95});
    expect(adapter.request!.queryParameters, {'class_id': 95, 'lang': 'ru'});

    await dio.get('/news', queryParameters: {'lang': 'en'});
    expect(adapter.request!.queryParameters['lang'], 'en');
  });
}
