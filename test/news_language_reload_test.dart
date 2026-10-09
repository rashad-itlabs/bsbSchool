import 'package:bsbschool/core/error/failures.dart';
import 'package:bsbschool/features/news/domain/entities/news_item.dart';
import 'package:bsbschool/features/news/domain/entities/news_page.dart';
import 'package:bsbschool/features/news/domain/repositories/news_repository.dart';
import 'package:bsbschool/features/news/domain/usecases/get_news.dart';
import 'package:bsbschool/features/news/presentation/bloc/news_bloc.dart';
import 'package:bsbschool/features/news/presentation/widgets/news_language_reload.dart';
import 'package:bsbschool/l10n/app_localizations.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const _titles = {'az': 'Kembric imtahanları', 'en': 'Cambridge Examinations'};

/// A backend that predates `translations`: each entry comes only in the
/// language the feed was requested in — here, whatever the app is showing at
/// the moment of the request, as `NewsService` sends it.
class _OldBackend implements NewsRepository {
  final ValueNotifier<Locale> locale;
  _OldBackend(this.locale);

  final requests = <String>[];

  @override
  Future<Either<Failure, NewsPage>> getNews({int page = 1}) async {
    final language = locale.value.languageCode;
    requests.add(language);
    return Right(NewsPage(items: [NewsItem(id: 3, title: _titles[language]!)]));
  }
}

Widget _feed(ValueNotifier<Locale> locale, _OldBackend backend) {
  return ValueListenableBuilder<Locale>(
    valueListenable: locale,
    builder: (_, value, _) => MaterialApp(
      locale: value,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: BlocProvider(
        create: (_) =>
            NewsBloc(getNews: GetNews(backend))..add(const NewsFetched()),
        child: NewsLanguageReload(
          child: BlocBuilder<NewsBloc, NewsState>(
            builder: (context, state) => Text(
              state.items.isEmpty
                  ? ''
                  : state.items.first.titleIn(
                      Localizations.localeOf(context).languageCode,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a language switch reloads the feed in the new language',
      (tester) async {
    final locale = ValueNotifier(const Locale('az'));
    final backend = _OldBackend(locale);

    await tester.pumpWidget(_feed(locale, backend));
    await tester.pumpAndSettle();

    // Mounting fetches once, through the bloc's own `NewsFetched`.
    expect(backend.requests, ['az']);
    expect(find.text('Kembric imtahanları'), findsOneWidget);

    locale.value = const Locale('en');
    await tester.pumpAndSettle();

    expect(backend.requests, ['az', 'en']);
    expect(find.text('Cambridge Examinations'), findsOneWidget);
  });
}
