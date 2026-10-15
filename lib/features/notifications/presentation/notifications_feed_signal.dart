import 'package:flutter/foundation.dart';

/// Tells the notifications tab that a push came in, and — after a tap on a
/// school announcement — which one to open.
///
/// The tab sits in the shell's `IndexedStack` with the feed it loaded at
/// start-up, so without this a parent who taps an announcement lands on a
/// list that does not have it yet. The push service has no `BuildContext`
/// and the tab's bloc is created by the tab itself, hence a plain notifier in
/// between, the same way `PushRouter` carries the tab switch.
///
/// The id to open is held until the tab takes it: a tap that cold-starts the
/// app arrives before the tab exists.
class NotificationsFeedSignal extends ChangeNotifier {
  NotificationsFeedSignal._();

  static final NotificationsFeedSignal instance = NotificationsFeedSignal._();

  int? _openPushId;

  /// True while a tapped announcement is still waiting to be opened.
  bool get hasPendingOpen => _openPushId != null;

  /// A message arrived or was tapped: the feed may have a new entry. A tap on
  /// an admin push names it, so the tab can open it once the feed is in.
  void pushReceived({int? openPushId}) {
    if (openPushId != null) _openPushId = openPushId;
    notifyListeners();
  }

  /// Reads the announcement to open and clears it, so one tap opens it once.
  int? takeOpenPushId() {
    final id = _openPushId;
    _openPushId = null;
    return id;
  }
}
