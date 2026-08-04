import 'package:bsbschool/dr/services/book_download_service.dart';
import 'package:bsbschool/features/library/domain/entities/book.dart';
import 'package:flutter_test/flutter_test.dart';

Book book(String title, {int id = 7}) => Book(id: id, title: title);

void main() {
  group('publicFileName', () {
    test('keeps a normal title as the file name', () {
      expect(BookDownloadService.publicFileName(book('Riyaziyyat 5')),
          'Riyaziyyat 5.pdf');
    });

    test('drops characters a file system would reject', () {
      expect(BookDownloadService.publicFileName(book('Fizika: I/II hissə')),
          'Fizika I II hissə.pdf');
    });

    test('falls back to the id when nothing usable is left', () {
      expect(BookDownloadService.publicFileName(book('///', id: 12)),
          'kitab-12.pdf');
    });

    test('does not produce a hidden file', () {
      expect(BookDownloadService.publicFileName(book('.gizli kitab')),
          'gizli kitab.pdf');
    });

    test('shortens a very long title', () {
      final name = BookDownloadService.publicFileName(book('Ə' * 200));
      expect(name, 'Ə' * 80 + '.pdf');
    });
  });
}
