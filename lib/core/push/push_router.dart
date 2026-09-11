import 'package:flutter/foundation.dart';

/// Where a tapped notification wants the app to land.
///
/// Only the primary tabs are listed: they are what `HomeShell` can switch to
/// without a named route, and the app has none.
enum PushTarget { dashboard, foodCard, tuition, notifications, profile }

/// Carries a notification tap from the OneSignal listener to `HomeShell`.
///
/// The tap routinely lands before the shell exists — opening the app *from* a
/// notification is the whole point — so the target is held until something
/// takes it, rather than fired into a widget tree that isn't built yet.
class PushRouter extends ChangeNotifier {
  PushRouter._();

  static final PushRouter instance = PushRouter._();

  PushTarget? _pending;

  /// True while a tap is still waiting to be handled.
  bool get hasPending => _pending != null;

  void request(PushTarget target) {
    _pending = target;
    notifyListeners();
  }

  /// Reads the pending target and clears it, so one tap moves the app once.
  PushTarget? take() {
    final target = _pending;
    _pending = null;
    return target;
  }

  /// Maps the `data` object the backend attaches to a notification onto a tab.
  ///
  /// Laravel sends e.g. `{"type": "tuition"}`. Anything unknown — or absent —
  /// falls back to the notifications tab, which lists the message that was
  /// just tapped, so an unrecognised type still lands somewhere sensible.
  static PushTarget parse(Map<String, dynamic>? data) {
    final raw = (data?['type'] ?? data?['screen'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return switch (raw) {
      'home' || 'dashboard' => PushTarget.dashboard,
      'food_card' || 'foodcard' || 'cafeteria' || 'buffet' =>
        PushTarget.foodCard,
      'tuition' || 'payment' || 'fee' => PushTarget.tuition,
      'profile' || 'settings' => PushTarget.profile,
      _ => PushTarget.notifications,
    };
  }
}
