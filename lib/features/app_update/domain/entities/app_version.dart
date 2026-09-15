import 'package:equatable/equatable.dart';

/// Where the installed build stands against what the backend publishes.
enum UpdateRequirement {
  /// Nothing to say — the build is current enough.
  none,

  /// A newer build exists, but this one still works. The parent is asked, not
  /// told, and can put it off.
  recommended,

  /// Below the minimum the backend supports: the app is unusable until the
  /// store copy is installed.
  forced,
}

/// What `/appVersion` publishes for one platform.
class AppVersion extends Equatable {
  /// Anything below this is blocked outright.
  final String minVersion;

  /// The newest build on the store. Between this and [minVersion] the update
  /// is merely offered.
  final String latestVersion;

  /// Where the update is installed from — the App Store / Play listing. Kept
  /// server-side so a moved listing needs no app release.
  final String storeUrl;

  /// What the school wants to say about this release, if anything.
  final String? message;

  const AppVersion({
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    this.message,
  });

  /// Where [current] — the version this binary reports — stands.
  ///
  /// Fails open at every step: an unreadable or absent version on either side
  /// counts as "nothing to do" rather than locking the parent out of an app
  /// that works.
  UpdateRequirement requirementFor(String current) {
    if (_compare(current, minVersion) < 0) return UpdateRequirement.forced;
    if (_compare(current, latestVersion) < 0) return UpdateRequirement.recommended;
    return UpdateRequirement.none;
  }

  /// Negative when [a] is older than [b], positive when newer, zero when they
  /// match — or when either cannot be read as a version at all.
  ///
  /// The parts are compared as numbers because `2.0.10` is newer than
  /// `2.0.9`, which string comparison gets backwards.
  static int _compare(String a, String b) {
    final left = _parts(a);
    final right = _parts(b);
    // Nothing trustworthy to compare: nobody is blocked on a guess.
    if (left.isEmpty || right.isEmpty) return 0;

    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l < r ? -1 : 1;
    }
    return 0;
  }

  /// `2.0.7` → `[2, 0, 7]`. The build suffix pubspec carries (`2.0.7+7`) and
  /// any pre-release tail are dropped: the store only ever shows the three
  /// numbers, so they are what both sides can agree on.
  static List<int> _parts(String version) {
    final head = version.trim().split(RegExp(r'[+\-\s]')).first;
    if (head.isEmpty) return const [];

    final parsed = head.split('.').map(int.tryParse).toList();
    // A leading part that isn't a number means this is not a version string.
    if (parsed.isEmpty || parsed.first == null) return const [];
    return parsed.map((part) => part ?? 0).toList();
  }

  @override
  List<Object?> get props => [minVersion, latestVersion, storeUrl, message];
}
