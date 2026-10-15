import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// A message as the app needs it: what to show and where a tap goes.
class PushMessage {
  final String? id;
  final String? title;
  final String? body;

  /// The backend's `data` object — `kind`, `type`, `homework_id`… FCM
  /// delivers every value as a string.
  final Map<String, dynamic> data;

  const PushMessage({this.id, this.title, this.body, this.data = const {}});

  factory PushMessage.fromRemote(RemoteMessage message) => PushMessage(
        id: message.messageId,
        title: message.notification?.title,
        body: message.notification?.body,
        data: message.data,
      );
}

/// The slice of Firebase Messaging [FirebasePushService] uses.
///
/// Behind an interface so the service can be tested without a platform
/// channel; [FirebasePushMessaging] is the only real implementation.
abstract class PushMessaging {
  /// True until the parent has answered the system dialog either way.
  Future<bool> permissionUndecided();

  /// Shows the system dialog. Answers immediately, without a dialog, once the
  /// choice has been made — a parent who said no is not asked again here.
  Future<void> requestPermission();

  /// This install's FCM token, or null when there is none yet.
  Future<String?> getToken();

  /// Invalidates the token, so nothing sent to it arrives any more.
  Future<void> deleteToken();

  Stream<String> get onTokenRefresh;

  /// Messages that arrive while the app is open — the system shows nothing
  /// for them on its own.
  Stream<PushMessage> get onForegroundMessage;

  /// A notification tapped while the app was in the background.
  Stream<PushMessage> get onOpened;

  /// The notification whose tap started the app, if one did.
  Future<PushMessage?> initialMessage();
}

class FirebasePushMessaging implements PushMessaging {
  /// How long iOS may take to hand over the APNs token after launch. FCM
  /// cannot issue its own token before it, and asking early throws
  /// `apns-token-not-set`.
  static const int apnsAttempts = 10;
  static const Duration apnsDelay = Duration(seconds: 1);

  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  @override
  Future<bool> permissionUndecided() async {
    final settings = await _fm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.notDetermined;
  }

  @override
  Future<void> requestPermission() async {
    // On Android 13+ this is the POST_NOTIFICATIONS runtime prompt.
    await _fm.requestPermission();
  }

  @override
  Future<String?> getToken() async {
    try {
      if (Platform.isIOS && !await _apnsReady()) {
        debugPrint('[push] no APNs token after ${apnsAttempts}s — no FCM token yet');
        return null;
      }
      return await _fm.getToken();
    } catch (e) {
      debugPrint('[push] getToken failed: $e');
      return null;
    }
  }

  Future<bool> _apnsReady() async {
    for (var attempt = 0; attempt < apnsAttempts; attempt++) {
      if (await _fm.getAPNSToken() != null) return true;
      await Future<void>.delayed(apnsDelay);
    }
    return false;
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _fm.deleteToken();
    } catch (e) {
      debugPrint('[push] deleteToken failed: $e');
    }
  }

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(PushMessage.fromRemote);

  @override
  Stream<PushMessage> get onOpened =>
      FirebaseMessaging.onMessageOpenedApp.map(PushMessage.fromRemote);

  @override
  Future<PushMessage?> initialMessage() async {
    final message = await _fm.getInitialMessage();
    return message == null ? null : PushMessage.fromRemote(message);
  }
}
