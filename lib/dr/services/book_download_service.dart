import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/library/domain/entities/book.dart';
import 'public_downloads.dart';
import '../../core/l10n/l10n.dart';

/// Raised when the book was downloaded but could not be copied to the phone's
/// public Downloads / Files location. The offline [file] is usable either way,
/// so the reader keeps working and only the "saved to Downloads" promise fails.
class BookExportException implements Exception {
  const BookExportException(this.file, this.cause);

  final File file;
  final Object cause;

  @override
  String toString() => 'BookExportException(${file.path}: $cause)';
}

/// Downloads library PDFs so a student can read them offline. Each book is kept
/// twice on purpose: a private copy under `<app support>/books/<id>.pdf` that
/// the reader opens (stable name, never touched by the student), and a copy in
/// the phone's public Downloads folder — Files app on iOS — named after the
/// book so it can be found outside the app. The book URL is public, so a bare
/// [Dio] is used with no auth interceptors.
class BookDownloadService {
  BookDownloadService({Dio? dio, PublicDownloads? publicDownloads})
      : _dio = dio ?? Dio(),
        _public = publicDownloads ?? PublicDownloads();

  final Dio _dio;
  final PublicDownloads _public;

  /// The name the student sees in Downloads / Files: the book's title, minus
  /// anything a file system would object to.
  static String publicFileName(Book book) {
    final cleaned = book.title
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[.\s]+|[.\s]+$'), '');
    if (cleaned.isEmpty) return 'kitab-${book.id}.pdf';
    // Trimmed by runes so a long title can't be cut mid-character.
    final name = String.fromCharCodes(cleaned.runes.take(80)).trimRight();
    return '$name.pdf';
  }

  Future<File> _fileFor(Book book) async {
    final dir = await getApplicationSupportDirectory();
    final books = Directory('${dir.path}/books');
    if (!await books.exists()) {
      await books.create(recursive: true);
    }
    return File('${books.path}/${book.id}.pdf');
  }

  /// The on-device copy if it has already been downloaded, else null.
  Future<File?> localFile(Book book) async {
    final file = await _fileFor(book);
    if (await file.exists()) return file;
    return _adoptLegacyCopy(book, file);
  }

  /// Earlier versions kept the reader's copy in the documents directory, which
  /// iOS now exposes in the Files app. Move such a copy into private storage so
  /// the student only sees the nicely named public one.
  Future<File?> _adoptLegacyCopy(Book book, File target) async {
    final documents = await getApplicationDocumentsDirectory();
    final legacyDir = Directory('${documents.path}/books');
    final legacy = File('${legacyDir.path}/${book.id}.pdf');
    if (!await legacy.exists()) return null;
    final moved = await legacy.rename(target.path);
    if (await legacyDir.list().isEmpty) await legacyDir.delete();
    return moved;
  }

  /// Downloads [book]'s PDF, reporting progress as a 0..1 fraction, and copies
  /// it to the phone's Downloads / Files location. Throws on failure and leaves
  /// no partial file behind; throws [BookExportException] when only that last
  /// copy fails.
  Future<File> download(
    Book book, {
    void Function(double progress)? onProgress,
  }) async {
    final url = book.fileUrl;
    if (url == null) {
      throw StateError(L.s.bookNoFile);
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
      await tmp.rename(file.path);
    } catch (_) {
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    }

    try {
      await _public.save(file, publicFileName(book));
    } catch (e) {
      throw BookExportException(file, e);
    }
    return file;
  }

  /// Removes both copies of [book] — the reader's and the public one.
  Future<void> delete(Book book) async {
    final file = await _fileFor(book);
    if (await file.exists()) await file.delete();
    await _public.remove(publicFileName(book));
  }
}
