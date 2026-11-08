import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'habesha_hub_channel';
  static const _channelName = 'Habesha Hub';
  static const _channelDesc = 'Habesha Hub varsler';

  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Create notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Save FCM token to Firestore. On iPhone this can fail in the first seconds (no APNs token
    // yet); don't let that stop the rest of the setup, try again shortly.
    // Runs in the background: on iPhone it may wait for the APNs token, the app must not wait.
    _saveToken().catchError((_) {
      Future.delayed(const Duration(seconds: 15), () => _saveToken().catchError((_) {}));
    });

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateToken);
    // the app starts before the login is restored: save the token again when the user is known
    FirebaseAuth.instance.authStateChanges().listen((u) { if (u != null && !u.isAnonymous) _saveToken().catchError((_) {}); });

    // iPhone: show the banner also while the app is open (Android uses the local notification below)
    await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  // ── News topics: new providers / new videos, in the user's language ──
  static const _topics = {'English': 'news_en', 'Tigrinya': 'news_ti', 'Amharic': 'news_am'};
  static String? _currentTopic;

  /// Subscribe to the news topic for [language] and unsubscribe from the others.
  static Future<void> syncNewsTopic(String language, {int attempt = 0}) async {
    final topic = _topics[language] ?? 'news_en';
    if (topic == _currentTopic) return;
    try {
      // iPhone: topics only work once Apple has given the app its push token (APNs),
      // which can take a few seconds after start. Wait for it instead of failing silently.
      if (Platform.isIOS) {
        String? apns;
        for (var i = 0; i < 10 && apns == null; i++) {
          apns = await _messaging.getAPNSToken();
          if (apns == null) await Future.delayed(const Duration(seconds: 2));
        }
        if (apns == null) throw StateError('no APNs token yet');
      }
      for (final t in _topics.values) {
        if (t != topic) await _messaging.unsubscribeFromTopic(t);
      }
      await _messaging.subscribeToTopic(topic);
      _currentTopic = topic;
    } catch (_) {
      // try again later (no internet, or no APNs token yet), a few times
      if (attempt < 5) {
        Future.delayed(Duration(minutes: 1 + attempt * 2),
            () => syncNewsTopic(language, attempt: attempt + 1));
      }
    }
  }

  static Future<void> _saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // iPhone/iPad: getToken fails until Apple has given the push token (APNs); wait for it
    if (Platform.isIOS) {
      String? apns;
      for (var i = 0; i < 10 && apns == null; i++) {
        apns = await _messaging.getAPNSToken();
        if (apns == null) await Future.delayed(const Duration(seconds: 2));
      }
      if (apns == null) {
        // so admin can see why an iPhone gets no push (no personal data, only the state)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {'pushStatus': 'ios: no APNs token'}, SetOptions(merge: true));
        return;
      }
    }
    final token = await _messaging.getToken();
    if (token == null) return;
    final settings = await _messaging.getNotificationSettings();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'pushStatus': '${Platform.isIOS ? 'ios' : 'android'}: ok, ${settings.authorizationStatus.name}'},
        SetOptions(merge: true));
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': token, 'fcmTokens': FieldValue.arrayUnion([token]), 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  static Future<void> _updateToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': token, 'fcmTokens': FieldValue.arrayUnion([token])}, SetOptions(merge: true));
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    if (Platform.isIOS) return; // iOS shows it itself (presentation options above)

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  // Send notification to a specific user via Firestore trigger
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // Save notification to Firestore — Cloud Function will send FCM
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'data': data ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'sent': false,
    });
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Handle background messages
}
