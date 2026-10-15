import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_messaging.dart';

/// Puts a message that arrived while the app was open into the notification
/// shade. FCM does that by itself only in the background; in the foreground
/// both platforms hand the message to the app and show nothing.
abstract class ForegroundNotifier {
  /// [onTap] receives the message's `data` when one of these is tapped.
  Future<void> init({
    required String channelName,
    required void Function(Map<String, dynamic> data) onTap,
  });

  /// Android lists the channel by name in the app's system settings; it
  /// follows the app's language.
  Future<void> renameChannel(String name);

  Future<void> show(PushMessage message);
}

class LocalForegroundNotifier implements ForegroundNotifier {
  /// The one channel everything goes through. The same id is the FCM default
  /// in `AndroidManifest.xml`, so background and foreground notifications land
  /// in one place in the system settings.
  static const String channelId = 'bsb_default';

  /// `res/drawable/ic_stat_notification.xml`. Android draws a status bar icon
  /// from its alpha alone, so it has to be a silhouette — the launcher icon is
  /// opaque and would show as a white square.
  static const String icon = 'ic_stat_notification';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  String _channelName = '';
  int _nextId = 0;

  @override
  Future<void> init({
    required String channelName,
    required void Function(Map<String, dynamic> data) onTap,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(icon),
        // All false: the plugin's default is to ask on initialize, i.e. on the
        // launch screen. Permission is asked after sign-in (see PushService).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap(_decode(response.payload)),
    );
    await renameChannel(channelName);

    // One of ours tapped after the app was killed in the meantime.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      onTap(_decode(launch?.notificationResponse?.payload));
    }
  }

  @override
  Future<void> renameChannel(String name) async {
    _channelName = name;
    // Creating an existing channel again only updates its name; importance is
    // fixed at first creation.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          channelId,
          name,
          importance: Importance.high,
        ));
  }

  @override
  Future<void> show(PushMessage message) {
    return _plugin.show(
      id: _nextId++,
      title: message.title,
      body: message.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelName,
          icon: icon,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Map<String, dynamic> _decode(String? payload) {
    if (payload == null || payload.isEmpty) return const {};
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (e) {
      debugPrint('[push] unreadable notification payload: $e');
      return const {};
    }
  }
}
