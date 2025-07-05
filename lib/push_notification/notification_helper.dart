import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/screens/auth_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/screens/order_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/wallet/screens/wallet_screen.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/push_notification/models/notification_body.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class NotificationHelper {
  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    try {
      // Initialize notification channels
      await _initializeNotificationChannels(flutterLocalNotificationsPlugin);

      var androidInitialize = const AndroidInitializationSettings('@mipmap/ic_launcher');
      var iOSInitialize = const DarwinInitializationSettings();
      var initializationsSettings = InitializationSettings(android: androidInitialize, iOS: iOSInitialize);

      // Request notification permissions
      if (Platform.isAndroid) {
        await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      }

      await flutterLocalNotificationsPlugin.initialize(
        initializationsSettings,
        onDidReceiveNotificationResponse: (NotificationResponse load) async {
          try {
            if (load.payload?.isNotEmpty ?? false) {
              final payload = NotificationBody.fromJson(jsonDecode(load.payload!));
              _handleNotificationTap(payload);
            }
          } catch (e) {
            log('Notification tap error: $e');
          }
        },
      );

      // Set up Firebase message listeners
      _setupFirebaseMessageListeners(flutterLocalNotificationsPlugin);
    } catch (e) {
      log('Notification initialization error: $e');
    }
  }

  static Future<void> _initializeNotificationChannels(FlutterLocalNotificationsPlugin fln) async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // Same as in AndroidManifest
        'High Importance Notifications',
        importance: Importance.max,
        playSound: false,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      );
      await fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    }
  }

  static void _handleNotificationTap(NotificationBody payload) {
    try {
      switch (payload.type) {
        case 'order':
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderId: payload.orderId, isNotification: true)));
          break;
        case 'wallet':
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => const WalletScreen()));
          break;
        case 'notification':
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => const NotificationScreen(fromNotification: true)));
          break;
        case 'block':
          Provider.of<AuthController>(Get.context!, listen: false).clearSharedData();
          Provider.of<AddressController>(Get.context!, listen: false).getAddressList();
          Navigator.of(Get.context!).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false);
          break;
        default:
          Navigator.of(Get.context!).pushReplacement(MaterialPageRoute(builder: (context) => const InboxScreen(isBackButtonExist: true)));
      }
    } catch (e) {
      log('Notification navigation error: $e');
    }
  }

  static void _setupFirebaseMessageListeners(FlutterLocalNotificationsPlugin fln) {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Foreground message received: ${message.notification?.title}");

      // Always show notification when in foreground
      showNotification(message, fln, false);

      // Handle special cases like block notifications
      if (message.data['type'] == "block") {
        _handleBlockNotification();
      }
    });

    // Background/opened app messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("App opened from notification: ${message.notification?.title}");
      try {
        if (message.data.isNotEmpty) {
          final notificationBody = convertNotification(message.data);
          _handleNotificationTap(notificationBody);
        }
      } catch (e) {
        log('Message opened error: $e');
      }
    });
  }

  static Future<void> showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin fln, bool isBackground) async {
    try {
      final notificationBody = convertNotification(message.data);
      String? title, body, orderID, image;

      // Get content from either data or notification payload
      title = message.notification?.title ?? message.data['title'];
      body = message.notification?.body ?? message.data['body'];
      orderID = message.notification?.titleLocKey ?? message.data['order_id'];

      if (title == null || body == null) {
        log('Incomplete notification data');
        return;
      }

      // Get image if available
      image = message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['image'];

      if (image != null && image.isNotEmpty) {
        try {
          await showBigPictureNotificationHiddenLargeIcon(title, body, orderID, notificationBody, image, fln);
        } catch (e) {
          log('Big picture notification failed: $e');
          await showBigTextNotification(title, body, orderID, notificationBody, fln);
        }
      } else {
        await showBigTextNotification(title, body, orderID, notificationBody, fln);
      }
    } catch (e) {
      log('Show notification error: $e');
    }
  }

  static String? _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    return imagePath.startsWith('http') ? imagePath : '${AppConstants.baseUrl}/storage/app/public/notification/$imagePath';
  }

  static String? _getNotificationImage(RemoteNotification? notification) {
    if (notification == null) return null;

    if (Platform.isAndroid) {
      return _getImageUrl(notification.android?.imageUrl);
    } else if (Platform.isIOS) {
      return _getImageUrl(notification.apple?.imageUrl);
    }
    return null;
  }

  static Future<void> showBigTextNotification(String? title, String body, String? orderID, NotificationBody? notificationBody, FlutterLocalNotificationsPlugin fln) async {
    try {
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: false, // Disable sound
        styleInformation: BigTextStyleInformation(body, htmlFormatBigText: true, contentTitle: title, htmlFormatContentTitle: true),
      );

      await fln.show(0, title, body, NotificationDetails(android: androidPlatformChannelSpecifics), payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null);
    } catch (e) {
      log('Big text notification error: $e');
    }
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(String? title, String? body, String? orderID, NotificationBody? notificationBody, String image, FlutterLocalNotificationsPlugin fln) async {
    try {
      const String sound = 'notification_sound'; // Match your raw resource name

      final largeIconPath = await _downloadAndSaveFile(image, 'largeIcon');
      final bigPicturePath = await _downloadAndSaveFile(image, 'bigPicture');

      final bigPictureStyleInformation = BigPictureStyleInformation(FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true, contentTitle: title, htmlFormatContentTitle: true, summaryText: body, htmlFormatSummaryText: true);

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'high_importance_channel', // Match your channel ID
        'High Importance Notifications',
        largeIcon: FilePathAndroidBitmap(largeIconPath),
        priority: Priority.max,
        playSound: true,
        styleInformation: bigPictureStyleInformation,
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound(sound),
      );

      final platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

      await fln.show(0, title, body, platformChannelSpecifics, payload: notificationBody != null ? jsonEncode(notificationBody.toJson()) : null);
    } catch (e) {
      log('Big picture notification error: $e');
      rethrow;
    }
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final response = await http.get(Uri.parse(url));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      log('File download error: $e');
      rethrow;
    }
  }

  static NotificationBody convertNotification(Map<String, dynamic> data) {
    try {
      switch (data['type']) {
        case 'notification':
          return NotificationBody(type: 'notification');
        case 'order':
          return NotificationBody(type: 'order', orderId: int.tryParse(data['order_id'] ?? '0') ?? 0);
        case 'wallet':
          return NotificationBody(type: 'wallet');
        case 'block':
          return NotificationBody(type: 'block');
        default:
          return NotificationBody(type: 'chatting');
      }
    } catch (e) {
      log('Notification conversion error: $e');
      return NotificationBody(type: 'notification');
    }
  }

  static void _handleBlockNotification() {
    try {
      Provider.of<AuthController>(Get.context!, listen: false).clearSharedData();
      Provider.of<AddressController>(Get.context!, listen: false).getAddressList();
      Navigator.of(Get.context!).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false);
    } catch (e) {
      log('Block notification handling error: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Minimal initialization for background
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('notification_icon');

  await flutterLocalNotificationsPlugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));

  try {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: false, // Explicitly disable sound
    );

    await flutterLocalNotificationsPlugin.show(0, message.notification?.title, message.notification?.body, const NotificationDetails(android: androidPlatformChannelSpecifics));
  } catch (e) {
    log('Background notification error: $e');
  }
}
