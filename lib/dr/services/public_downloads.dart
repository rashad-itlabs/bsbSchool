import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Puts a finished download where the student can find it with the phone's own
/// file browser instead of only inside the app:
///
/// * Android — the public `Downloads` folder, written by [MainActivity]'s
///   `DownloadsHandler` (MediaStore on Android 10+).
/// * iOS — the app's documents folder, which shows up in the Files app under
///   "On My iPhone" because `UIFileSharingEnabled` is set.
class PublicDownloads {
  static const _channel = MethodChannel('bsbschool/public_downloads');

  /// Name of the destination as the student sees it, for messages.
  static String get locationName => Platform.isIOS ? 'Fayllar' : 'Yükləmələr';

  /// Copies [source] out under [fileName], replacing an earlier copy of the
  /// same name. Throws if the copy cannot be written.
  Future<void> save(
    File source,
    String fileName, {
    String mimeType = 'application/pdf',
  }) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<String>('save', {
        'sourcePath': source.path,
        'fileName': fileName,
        'mimeType': mimeType,
      });
      return;
    }
    if (Platform.isIOS) {
      await source.copy('${await _visibleDir()}/$fileName');
    }
  }

  /// Removes the copy written by [save], if it is still there.
  Future<void> remove(String fileName) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('delete', {'fileName': fileName});
      return;
    }
    if (Platform.isIOS) {
      final file = File('${await _visibleDir()}/$fileName');
      if (await file.exists()) await file.delete();
    }
  }

  Future<String> _visibleDir() async =>
      (await getApplicationDocumentsDirectory()).path;
}
