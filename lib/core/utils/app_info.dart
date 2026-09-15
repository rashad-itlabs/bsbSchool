import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';

/// What this binary is, as the update gate needs to know it.
///
/// An interface rather than a direct `PackageInfo` call so the gate can be
/// tested without a platform channel underneath it.
abstract class AppInfo {
  /// `2.0.7` — `CFBundleShortVersionString` on iOS, `versionName` on Android.
  /// Both come from `pubspec.yaml`'s `version:` at build time, so that line is
  /// the single place a release is numbered.
  Future<String> get version;

  /// `ios` / `android` — the key the backend keeps its values under.
  String get platform;
}

class PackageAppInfo implements AppInfo {
  /// Read once: the value cannot change while the process is alive, and the
  /// gate asks for it again on every resume.
  String? _cached;

  @override
  Future<String> get version async {
    final cached = _cached;
    if (cached != null) return cached;

    final info = await PackageInfo.fromPlatform();
    return _cached = info.version;
  }

  @override
  String get platform => Platform.isAndroid ? 'android' : 'ios';
}
