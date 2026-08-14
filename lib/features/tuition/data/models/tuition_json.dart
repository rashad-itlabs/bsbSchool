/// Coercions shared by the tuition models.
///
/// The API is loose about types — an amount can arrive as `1600`, `1600.00` or
/// `"1600.00"`, and any field can be null. Every helper degrades to a neutral
/// value instead of throwing, so one odd row can never take the screen down.
library;

int? asIntOrNull(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

int asInt(dynamic value) => asIntOrNull(value) ?? 0;

/// Null and empty both mean "the server has nothing to say here".
String? asString(dynamic value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

double asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

bool asBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == '1' || text == 'true';
}

/// Handles both shapes the payload uses: `2026-09-05` and
/// `2026-08-08 13:42:50`. A value that parses as neither degrades to null.
DateTime? asDate(dynamic value) {
  final text = asString(value);
  if (text == null) return null;
  return DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

/// Maps a JSON array of objects through [fromJson], skipping anything that is
/// not an object.
List<T> asList<T>(dynamic value, T Function(Map<String, dynamic>) fromJson) {
  if (value is! List) return <T>[];
  return value
      .whereType<Map>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
