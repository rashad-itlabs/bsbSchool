import '../../domain/entities/app_version.dart';

class AppVersionModel extends AppVersion {
  const AppVersionModel({
    required super.minVersion,
    required super.latestVersion,
    required super.storeUrl,
    super.message,
  });

  /// `{"success": true, "min_version": "2.0.7", "latest_version": "2.0.7",
  /// "store_url": "https://apps.apple.com/...", "message": null}`
  ///
  /// A missing version reads as an empty string rather than a zero: the
  /// comparison treats "not a version" as "nothing to compare", so a
  /// half-configured backend cannot lock anyone out.
  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      minVersion: _asString(json['min_version']),
      latestVersion: _asString(json['latest_version']),
      storeUrl: _asString(json['store_url']),
      message: _asNullableString(json['message']),
    );
  }

  static String _asString(dynamic value) => value?.toString().trim() ?? '';

  static String? _asNullableString(dynamic value) {
    final text = _asString(value);
    return text.isEmpty ? null : text;
  }
}
