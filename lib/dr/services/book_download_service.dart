import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/library/domain/entities/book.dart';

/// Downloads library PDFs to app-private storage so a student can read them
/// offline. Files live under `<app documents>/books/<id>.pdf`; the book URL is
/// public, so a bare [Dio] is used with no auth interceptors.
class BookDownloadService {
  BookDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<File> _fileFor(Book book) async {
    final dir = await getApplicationDocumentsDirectory();
    final books = Directory('${dir.path}/books');
    if (!await books.exists()) {
      await books.create(recursive: true);
    }
    return File('${books.path}/${book.id}.pdf');
  }

  /// The on-device copy if it has already been downloaded, else null.
  Future<File?> localFile(Book book) async {
    final file = await _fileFor(book);
    return await file.exists() ? file : null;
  }

  /// Downloads [book]'s PDF, reporting progress as a 0..1 fraction. Throws on
  /// failure; leaves no partial file behind.
  Future<File> download(
    Book book, {
    void Function(double progress)? onProgress,
  }) async {
    final url = book.fileUrl;
    if (url == null) {
      throw StateError('Bu kitabın faylı yoxdur');
    }
    final file = await _fileFor(book);
    // Download to a `.part` file first and rename on success, so an aborted
    // download can never be mistaken for a complete one.
    final tmp = File('${file.path}.part');
    try {
      await _dio.download(
        url,
        tmp.path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      return await tmp.rename(file.path);
    } catch (_) {
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    }
  }

  /// Removes the downloaded copy of [book] if one exists.
  Future<void> delete(Book book) async {
    final file = await _fileFor(book);
    if (await file.exists()) await file.delete();
  }
}
