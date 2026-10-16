import 'package:dio/dio.dart';

import '../l10n/l10n.dart';

/// Names the app's language on every request (`?lang=az|en|ru`).
///
/// The backend writes its messages — a wrong password at login, a validation
/// error, an expired code — in the language a request names, and in
/// Azerbaijani when it names none (`ApiLocale` middleware). Only a few services
/// used to send it, so the rest showed a Russian- or English-speaking parent
/// an Azerbaijani error. A service that sets `lang` itself keeps its own.
class LocaleInterceptor extends Interceptor {
  /// The language to name — the app's current one, [L.s], by default.
  /// Injectable for tests.
  final String Function() language;

  LocaleInterceptor({String Function()? language})
      : language = language ?? (() => L.s.localeName);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.queryParameters.containsKey('lang')) {
      options.queryParameters = {
        ...options.queryParameters,
        'lang': language(),
      };
    }
    handler.next(options);
  }
}
