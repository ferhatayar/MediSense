import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  static Future<void> initialize() async {
    print('NotificationService: Initializing...');
    
    // Timezone verilerini yükle
    tz.initializeTimeZones();
    
    // Bildirim izinlerini iste
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('NotificationService: Permission status - ${settings.authorizationStatus}');

    // Android için bildirim kanalı oluştur
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medisense_channel',
      'MediSense Bildirimleri',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    print('NotificationService: Notification channel created');

    // Token'ı al ve Firestore'a kaydet
    String? token = await _messaging.getToken();
    print('NotificationService: FCM Token - $token');
    
    if (token != null) {
      await _firestore.collection('users').doc(currentUserId).update({
        'fcmToken': token,
      });
      print('NotificationService: Token saved to Firestore');
    }

    // Arka plan mesaj işleyicisi
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('NotificationService: Background handler set');
    
    // Bildirime tıklandığında
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('NotificationService: Notification clicked');
      _handleNotificationClick(message);
    });

    // Bildirim geldiğinde
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('NotificationService: Notification received');
      _handleNotification(message);
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('NotificationService: Background notification received');
    await _handleNotification(message);
  }

  static Future<void> _handleNotification(RemoteMessage message) async {
    print('NotificationService: Handling notification');
    // Bildirimi Firestore'a kaydet
    await _firestore.collection('notifications').add({
      'userId': currentUserId,
      'title': message.notification?.title ?? 'İlaç Hatırlatıcı',
      'body': message.notification?.body ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'medication',
    });
    print('NotificationService: Notification saved to Firestore');
  }

  static Future<void> _handleNotificationClick(RemoteMessage message) async {
    print('NotificationService: Handling notification click');
    // Bildirime tıklanınca ilgili ilacın logundaki isRead alanını true yap
    final userId = currentUserId;
    final medicineId = message.data['medicineId'];
    final logDate = message.data['logDate']; // yyyy-MM-dd
    final time = message.data['time']; // "3:25 PM" gibi
    if (userId != null && medicineId != null && logDate != null && time != null) {
      final logRef = _firestore
          .collection('medications')
          .doc(userId)
          .collection('medicines')
          .doc(medicineId)
          .collection('logs')
          .doc(logDate);
      final logDoc = await logRef.get();
      if (logDoc.exists) {
        final logData = logDoc.data();
        if (logData != null && logData['times'] != null) {
          final List<dynamic> times = logData['times'];
          final updatedTimes = times.map((t) {
            if (t['time'] == time) {
              return {...t, 'isRead': true};
            }
            return t;
          }).toList();
          await logRef.update({'times': updatedTimes});
          print('NotificationService: Log içindeki isRead true yapıldı');
        }
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayNotifications() async {
    final startOfDay = DateTime.now().subtract(const Duration(days: 1));
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .where('timestamp', isGreaterThan: startOfDay)
        .orderBy('timestamp', descending: true)
        .get();

    return notifications.docs.map((doc) => doc.data()).toList();
  }
} 