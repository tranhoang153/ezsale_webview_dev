import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wwwow_mobile/services/rest_api/fcm_api.dart';
import '../../provider/navigationBarProvider.dart';

class WebviewHandle {
  final messageOnDeviceTokenNull = '';

  Future<bool> exitApp(
      {required BuildContext context,
      required bool mounted,
      required bool validURL,
      required InAppWebViewController? webViewController,
      required void Function() setState}) async {
    if (mounted) {
      context.read<NavigationBarProvider>().animationController.reverse();
    }
    if (!validURL) {
      return Future.value(true);
    }
    if (await webViewController!.canGoBack()) {
      setState();
      webViewController!.goBack();
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }

  webviewPostMessage(InAppWebViewController controller, value) {
    controller.postWebMessage(
        message: WebMessage(data: value),
        targetOrigin: WebUri.uri(Uri.parse("*")));
  }

  handleMessage(InAppWebViewController controller, message) async {
    try {
      var messageJSON = json.decode(message);
      if (messageJSON['messageName'] != null) {
        if (messageJSON['messageName'] == "send_user_id") {
          if (messageJSON['loginStatus'] == "login_success") {
            print(messageJSON['uid']);
          } else {
            print("logout");
          }
        }
      }
    } on Exception catch (e) {
      webviewPostMessage(controller, messageOnDeviceTokenNull);
    }
  }

  handleDownload({required String url, required BuildContext context}) async {
    try {
      Dio dio = Dio();
      String fileName;
      if (url.toString().lastIndexOf('?') > 0) {
        fileName = url.toString().substring(url.toString().lastIndexOf('/') + 1,
            url.toString().lastIndexOf('?'));
      } else {
        fileName =
            url.toString().substring(url.toString().lastIndexOf('/') + 1);
      }
      String savePath = await getFilePath(fileName);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Downloading file..'),
      ));
      await dio.download(url.toString(), savePath,
          onReceiveProgress: (rec, total) {});

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Download Complete'),
      ));
    } on Exception catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Downloading failed'),
      ));
    }
  }

  Future<String> getFilePath(uniqueFileName) async {
    String path = '';
    var externalStorageDirPath;
    if (Platform.isAndroid) {
      try {
        externalStorageDirPath = '/storage/emulated/0/Download';
      } catch (e) {
        final directory = await getExternalStorageDirectory();
        externalStorageDirPath = directory?.path;
      }
    } else if (Platform.isIOS) {
      externalStorageDirPath =
          (await getApplicationDocumentsDirectory()).absolute.path;
    }
    path = '$externalStorageDirPath/$uniqueFileName';
    return path;
  }

  void saveDeviceToken(String fcmToken, String uidx) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final formData =
        FormData.fromMap({"fcm_token": fcmToken, "uidx": int.parse(uidx)});
    final response = await FcmAPI().saveFCMToken(formData);
    final myResponse = json.decode(response.data);
    if (myResponse["RESULTCD"] == 0) {
      pref.setString('uidx', uidx);
      print(myResponse["RESULTCD"]);
    }
    print(formData.fields);
    print(response.data);
  }
}
