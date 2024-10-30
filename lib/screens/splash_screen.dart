import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/Constant.dart';
import '../main.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    startTimer();
  }

  startTimer() async {
    var duration = const Duration(seconds: 3);
    SharedPreferences pref = await SharedPreferences.getInstance();
    return Timer(duration, () async {
      try {
        var fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null && pref.getString("fcmToken") == null) {
          pref.setString("fcmToken", fcmToken);
        }

        print('--------fcmToken:$fcmToken');
      } on Exception catch (e) {
        print(e);
      }
      navigatorKey.currentState!.pushReplacement(MaterialPageRoute(
          builder: (_) => MyHomePage(
                webUrl: pref.getString("deepLink") != null
                    ? pref.getString("deepLink")!
                    : webinitialUrl,
              )));
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark));
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 178 / 844,
        ),
        Image.asset(
          'assets/images/splash_content.png',
          height: MediaQuery.of(context).size.height * 100 / 844,
        )
      ]),
    );
  }
}
