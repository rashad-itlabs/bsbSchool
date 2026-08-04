import 'dart:convert';

import 'package:bsbschool/features/news/data/models/news_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The real `GET /getNews` response.
const _newsBody = '''
{
    "news": {
        "data": [
            {
                "id": 3,
                "title": "Cambridge Examinations",
                "description": "Registration deadline for upcoming Cambridge IGCSE exams",
                "image": "https://laravel.bsb.edu.az/uploads/news/1784796873_slider_desk.jpg",
                "created_at": "2026-07-23 12:54:33"
            },
            {
                "id": 2,
                "title": "Welcome to School!",
                "description": "The new academic year has officially started at British School in Baku.",
                "image": "https://laravel.bsb.edu.az/uploads/news/1784796154_slider_welcome.jpg",
                "created_at": "2026-07-23 12:42:34"
            }
        ],
        "current_page": 1,
        "per_page": 20,
        "total": 2,
        "last_page": 1
    }
}
''';

NewsPageModel _parse(String body) =>
    NewsPageModel.fromJson(jsonDecode(body) as Map<String, dynamic>);

void main() {
  test('unwraps the news paginator and keeps the API order', () {
    final page = _parse(_newsBody);

    expect(page.items, hasLength(2));
    expect(page.items.first.id, 3);
    expect(page.items.first.title, 'Cambridge Examinations');
    expect(page.currentPage, 1);
    expect(page.perPage, 20);
    expect(page.total, 2);
    expect(page.lastPage, 1);
    expect(page.hasMore, isFalse);
  });

  // `created_at` is a space-separated timestamp, not ISO-8601 with a 'T'.
  test('parses the created_at timestamp', () {
    final item = _parse(_newsBody).items.first;

    expect(item.createdAt, DateTime(2026, 7, 23, 12, 54, 33));
    expect(item.hasImage, isTrue);
  });

  test('a missing image degrades to null instead of an empty string', () {
    final page = _parse('''
{"news": {"data": [{"id": 7, "title": "No photo", "image": null}]}}
''');

    expect(page.items.single.hasImage, isFalse);
    expect(page.items.single.description, '');
    expect(page.items.single.createdAt, isNull);
    // Absent paginator fields fall back rather than throwing.
    expect(page.currentPage, 1);
    expect(page.total, 1);
  });

  test('an empty feed parses to no items', () {
    final page = _parse('{"news": {"data": [], "total": 0, "last_page": 1}}');

    expect(page.items, isEmpty);
    expect(page.total, 0);
  });
}
