import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wwwow_mobile/provider/routeProvider.dart';
import 'package:wwwow_mobile/provider/webviewURLProvider.dart';
import 'package:wwwow_mobile/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/navigationBarProvider.dart';
import '../screens/splash_screen.dart';
import '../helpers/Constant.dart';
import '../provider/theme_provider.dart';
import 'firebase_options.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await activeRequestPermissionFCM();
  } on Exception catch (e) {
    print(e);
  }

  return runApp(
    MyApp(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? initialMessage;

  @override
  void initState() {
    super.initState();
    try {
      setupFlutterNotifications();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        showFlutterNotification(message);
      });
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        onMessageOpenApp(message);
      });
    } on Exception catch (e) {
      print(e);
    }
  }

  void onMessageOpenApp(RemoteMessage message) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    if (message.data['notiType'] == "deepLink") {
      if (message.data['url'] != null) {
        pref.setString("deepLink", message.data['url']);
        print("-----deepLink");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NavigationBarProvider>(
            create: (_) => NavigationBarProvider()),
        ChangeNotifierProvider(create: (context) => RouteProvider()),
        ChangeNotifierProvider(create: (context) => WebviewURLProvider())
      ],
      builder: ((providerContext, child) {
        try {
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            if (message.data['notiType'] == "deepLink") {
              if (message.data['url'] != null &&
                  providerContext.read<RouteProvider>().route != "webscreen") {
                Navigator.push(
                    navigatorKey.currentState!.context,
                    MaterialPageRoute(
                        builder: (context) => HomeScreen(
                              message.data['url'],
                            )));
              }
            }
          });
        } on Exception catch (e) {
          print(e);
        }

        return MaterialApp(
            title: appName,
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            navigatorKey: navigatorKey,
            onGenerateRoute: (RouteSettings settings) {},
            home: SplashScreen());
      }),
    );
  }
}

final navigatorKey = GlobalKey<NavigatorState>();
late SharedPreferences pref;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Platform.isAndroid) {
    if (message.data["android_badge"] != null) {
      FlutterAppBadger.updateBadgeCount(
          int.parse(message.data["android_badge"]));
    }
  }
}

late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

Future<void> setupFlutterNotifications() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.getAPNSToken();
  }
  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

Future<void> activeRequestPermissionFCM() async {
  NotificationSettings settings;
  settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("====== Active FCM: AuthorizationStatus.authorized ======");
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    print("====== Active FCM: AuthorizationStatus.denied ======");
  }
}

void showFlutterNotification(RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(channel.id, channel.name,
            channelDescription: channel.description,
            icon: '@drawable/ic_stat_wwwow_icon_noti',
            color: Color(0xff02D3AE)),
      ),
    );
  }
}

late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
enableStoragePermision() async {
  try {
    if (Platform.isIOS) {
      bool permissionGiven = await Permission.storage.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.storage.request()).isGranted;
        return permissionGiven;
      }
      return permissionGiven;
    }
    final deviceInfoPlugin = DeviceInfoPlugin();
    final androidDeviceInfo = await deviceInfoPlugin.androidInfo;

    if (androidDeviceInfo.version.sdkInt < 33) {
      bool permissionGiven = await Permission.storage.isGranted;
      if (!permissionGiven) {
        permissionGiven = (await Permission.storage.request()).isGranted;
        return permissionGiven;
      }

      return permissionGiven;
    } else {
      bool permissionGiven = await Permission.photos.isGranted;

      if (!permissionGiven) {
        permissionGiven = (await Permission.photos.request()).isGranted;

        return permissionGiven;
      }
      return permissionGiven;
    }
  } on Exception catch (e) {
    print(e);
  }
}
