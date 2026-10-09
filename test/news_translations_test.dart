import 'dart:convert';

import 'package:bsbschool/features/news/data/models/news_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /getNews?lang=en` once the endpoint began sending `translations`
/// (09.10.2026). The backend fills a missing translation with the Azerbaijani
/// text, so `ru` here repeats `az`.
const _body = '''
{
    "news": {
        "data": [
            {
                "id": 3,
                "title": "Cambridge Examinations",
                "description": "<p>Results are out.</p>",
                "translations": {
                    "az": {"title": "Kembric imtahanları", "description": "<p>Nəticələr açıqlandı.</p>"},
                    "en": {"title": "Cambridge Examinations", "description": "<p>Results are out.</p>"},
                    "ru": {"title": "Kembric imtahanları", "description": "<p>Nəticələr açıqlandı.</p>"}
                },
                "image": null,
                "created_at": "2026-10-09 12:00:00"
            }
        ],
        "current_page": 1,
        "per_page": 20,
        "total": 1,
        "last_page": 1
    }
}
''';

/// The same entry from a backend that predates `translations`.
const _oldBody = '''
{
    "news": {
        "data": [
            {"id": 3, "title": "Cambridge Examinations", "description": null, "image": null, "created_at": null}
        ],
        "current_page": 1, "per_page": 20, "total": 1, "last_page": 1
    }
}
''';

void main() {
  test('picks the entry in the language being rendered', () {
    final item = NewsPageModel.fromJson(jsonDecode(_body)).items.single;

    expect(item.titleIn('az'), 'Kembric imtahanları');
    expect(item.titleIn('en'), 'Cambridge Examinations');
    expect(item.descriptionIn('az'), '<p>Nəticələr açıqlandı.</p>');
    // Backfilled by the backend, not left empty.
    expect(item.titleIn('ru'), 'Kembric imtahanları');
  });

  test('an unknown language falls back to the request language', () {
    final item = NewsPageModel.fromJson(jsonDecode(_body)).items.single;

    expect(item.titleIn('de'), 'Cambridge Examinations');
  });

  test('an older backend without translations still shows the entry', () {
    final item = NewsPageModel.fromJson(jsonDecode(_oldBody)).items.single;

    expect(item.translations, isEmpty);
    expect(item.titleIn('ru'), 'Cambridge Examinations');
    expect(item.descriptionIn('ru'), '');
  });
}
