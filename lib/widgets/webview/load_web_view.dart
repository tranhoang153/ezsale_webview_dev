import 'dart:io';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wwwow_mobile/helpers/Themes.dart';
import 'package:wwwow_mobile/helpers/icons.dart';
import 'package:wwwow_mobile/provider/webviewURLProvider.dart';
import '../../main.dart';
import '../bottom_menu.dart';
import '../no_internet_widget.dart';
import '../../helpers/Constant.dart';
import 'package:provider/src/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../helpers/Strings.dart';
import '../../provider/navigationBarProvider.dart';
import '../not_found.dart';
import '../../helpers/Colors.dart';
import './webview_handle.dart';

class LoadWebView extends StatefulWidget {
  String url = '';
  bool webUrl = true;

  LoadWebView({required this.url, required this.webUrl, Key? key})
      : super(key: key);

  @override
  _LoadWebViewState createState() => _LoadWebViewState();
}

class _LoadWebViewState extends State<LoadWebView>
    with SingleTickerProviderStateMixin {
  final GlobalKey webViewKey = GlobalKey();

  late PullToRefreshController _pullToRefreshController;
  CookieManager cookieManager = CookieManager.instance();
  InAppWebViewController? webViewController;
  double progress = 0;
  double windowprogress = 0;
  String url = '';
  int _previousScrollY = 0;
  bool isLoading = false;
  bool isNewWindowLoading = false;
  bool showErrorPage = false;
  bool slowInternetPage = false;
  bool noInternet = false;
  late AnimationController animationController;
  late Animation<double> animation;
  final expiresDate =
      DateTime.now().add(Duration(days: 7)).millisecondsSinceEpoch;
  bool _validURL = false;
  bool canGoBack = false;
  bool _allowClosePopUp = true;

  BuildContext? dialogContext;
  bool isOpenDialog = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    removeDeepLink();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (webViewController != null) {
        webViewController!.loadUrl(
            urlRequest: URLRequest(url: WebUri.uri(message.data['url'])));
      }
    });
    _validURL = Uri.tryParse(widget.url)?.isAbsolute ?? false;
    try {
      _pullToRefreshController = PullToRefreshController(
        options: PullToRefreshOptions(color: primaryColor),
        onRefresh: () async {
          if (Platform.isAndroid) {
            webViewController!.reload();
          } else if (Platform.isIOS) {
            webViewController!.loadUrl(
                urlRequest: URLRequest(url: await webViewController!.getUrl()));
          }
        },
      );
    } on Exception catch (e) {
      print(e);
    }

    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat();
    animation = Tween(begin: 0.0, end: 1.0).animate(animationController)
      ..addListener(() {});
  }

  void removeDeepLink() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.remove("deepLink");
  }

  @override
  void dispose() {
    animationController.dispose();
    webViewController = null;
    super.dispose();
  }

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          useOnDownloadStart: true,
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
          cacheEnabled: true,
          supportZoom: true,
          preferredContentMode: UserPreferredContentMode.MOBILE,
          userAgent: "random",
          verticalScrollBarEnabled: false,
          horizontalScrollBarEnabled: false,
          transparentBackground: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true),
      android: AndroidInAppWebViewOptions(
        thirdPartyCookiesEnabled: true,
        allowFileAccess: true,
        useHybridComposition: true,
        supportMultipleWindows: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        bottomNavigationBar: BottomMenu(
            webViewController: webViewController, setState: setState),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: GestureDetector(
                    onHorizontalDragEnd: (dragEndDetails) async {
                      if (dragEndDetails.primaryVelocity! > 0) {
                        if (await webViewController!.canGoBack()) {
                          webViewController!.goBack();
                        } else {}
                      }
                    },
                    child: WillPopScope(
                      onWillPop: () => WebviewHandle().exitApp(
                          context: context,
                          mounted: mounted,
                          validURL: _validURL,
                          webViewController: webViewController,
                          setState: () => setState(() {
                                noInternet = false;
                              })),
                      child: !widget.webUrl
                          ? emptyURL()
                          : Stack(
                              alignment: AlignmentDirectional.topStart,
                              clipBehavior: Clip.hardEdge,
                              children: [
                                _validURL
                                    ? InAppWebView(
                                        initialUrlRequest: URLRequest(
                                            url: WebUri.uri(
                                                Uri.parse(widget.url))),
                                        initialOptions: options,
                                        pullToRefreshController:
                                            _pullToRefreshController,
                                        gestureRecognizers: <Factory<
                                            OneSequenceGestureRecognizer>>{
                                          Factory<OneSequenceGestureRecognizer>(
                                              () => EagerGestureRecognizer()),
                                        },
                                        onWebViewCreated: (controller) async {
                                          webViewController = controller;

                                          await cookieManager.setCookie(
                                            url: WebUri.uri(
                                                Uri.parse(widget.url)),
                                            name: "myCookie",
                                            value: "myValue",
                                            expiresDate: expiresDate,
                                            isHttpOnly: false,
                                            isSecure: true,
                                          );

                                          await controller
                                              .addWebMessageListener(
                                                  WebMessageListener(
                                            jsObjectName: "messageHandler",
                                            onPostMessage: (message,
                                                sourceOrigin,
                                                isMainFrame,
                                                replyProxy) {
                                              print(message);

                                              WebviewHandle().handleMessage(
                                                  controller, message);
                                            },
                                          ));
                                        },
                                        onScrollChanged:
                                            (controller, x, y) async {
                                          int currentScrollY = y;
                                          if (currentScrollY >
                                              _previousScrollY) {
                                            _previousScrollY = currentScrollY;
                                            if (!context
                                                .read<NavigationBarProvider>()
                                                .animationController
                                                .isAnimating) {
                                              context
                                                  .read<NavigationBarProvider>()
                                                  .animationController
                                                  .forward();
                                            }
                                          } else {
                                            _previousScrollY = currentScrollY;

                                            if (!context
                                                .read<NavigationBarProvider>()
                                                .animationController
                                                .isAnimating) {
                                              context
                                                  .read<NavigationBarProvider>()
                                                  .animationController
                                                  .reverse();
                                            }
                                          }
                                        },
                                        onLoadStart: (controller, url) async {
                                          print('----------GET URL: ${url}');
                                          setState(() {
                                            isLoading = true;
                                            showErrorPage = false;
                                            slowInternetPage = false;
                                          });
                                          if (isOpenDialog == true &&
                                              dialogContext != null) {
                                            Navigator.of(dialogContext!).pop();
                                          }
                                          setState(() {
                                            this.url = url.toString();
                                          });
                                          context
                                              .read<WebviewURLProvider>()
                                              .setCurrentURL(url.toString());
                                        },
                                        onLoadStop: (controller, url) async {
                                          _pullToRefreshController
                                              .endRefreshing();
                                          setState(() {
                                            this.url = url.toString();
                                            isLoading = false;
                                          });
                                          if (hideHeader == true) {
                                            webViewController!
                                                .evaluateJavascript(
                                                    source: "javascript:(function() { " +
                                                        "var head = document.getElementsByTagName('header')[0];" +
                                                        "head.parentNode.removeChild(head);" +
                                                        "})()")
                                                .then((value) => debugPrint(
                                                    'Page finished loading Javascript'))
                                                .catchError((onError) =>
                                                    debugPrint('$onError'));
                                          }
                                          if (hideFooter == true) {
                                            webViewController!
                                                .evaluateJavascript(
                                                    source: "javascript:(function() { " +
                                                        "var footer = document.getElementsByTagName('footer')[0];" +
                                                        "footer.parentNode.removeChild(footer);" +
                                                        "})()")
                                                .then((value) => debugPrint(
                                                    'Page finished loading Javascript'))
                                                .catchError((onError) =>
                                                    debugPrint('$onError'));
                                          }
                                          SharedPreferences pref =
                                              await SharedPreferences
                                                  .getInstance();
                                          String? myDeviceToken =
                                              pref.getString("fcmToken");
                                          cookieManager
                                              .getCookie(
                                                  url: url!, name: "wwwow_uidx")
                                              .then((cookie) {
                                            if (cookie != null &&
                                                cookie.value != null) {
                                              if (pref.getString('uidx') !=
                                                      cookie.value.toString() &&
                                                  myDeviceToken != null) {
                                                WebviewHandle().saveDeviceToken(
                                                    myDeviceToken,
                                                    cookie.value);
                                              } else {
                                                print("the same uid");
                                              }
                                            } else {}
                                          }).onError((error, stackTrace) {
                                            print(error);
                                          });
                                        },
                                        onLoadError: (controller, url, code,
                                            message) async {
                                          _pullToRefreshController
                                              .endRefreshing();

                                          setState(() {
                                            isLoading = false;
                                            if (Platform.isAndroid &&
                                                code == -2 &&
                                                message ==
                                                    'net::ERR_INTERNET_DISCONNECTED') {
                                              noInternet = true;
                                              return;
                                            }
                                            if (Platform.isIOS &&
                                                code == -1009 &&
                                                message ==
                                                    'The Internet connection appears to be offline.') {
                                              noInternet = true;
                                              return;
                                            }
                                            if (code != 102) {
                                              slowInternetPage = true;
                                            }
                                          });
                                        },
                                        onLoadHttpError: (controller, url,
                                            statusCode, description) {
                                          _pullToRefreshController
                                              .endRefreshing();
                                          setState(() {
                                            showErrorPage = true;
                                            isLoading = false;
                                          });
                                        },
                                        onReceivedServerTrustAuthRequest:
                                            (controller, challenge) async {
                                          return ServerTrustAuthResponse(
                                              action:
                                                  ServerTrustAuthResponseAction
                                                      .PROCEED);
                                        },
                                        androidOnGeolocationPermissionsShowPrompt:
                                            (controller, origin) async {
                                          await Permission.location.request();
                                          return Future.value(
                                              GeolocationPermissionShowPromptResponse(
                                                  origin: origin,
                                                  allow: true,
                                                  retain: true));
                                        },
                                        androidOnPermissionRequest: (controller,
                                            origin, resources) async {
                                          if (resources.contains(
                                              'android.webkit.resource.AUDIO_CAPTURE')) {
                                            await Permission.microphone
                                                .request();
                                          }
                                          if (resources.contains(
                                              'android.webkit.resource.VIDEO_CAPTURE')) {
                                            await Permission.camera.request();
                                          }

                                          return PermissionRequestResponse(
                                              resources: resources,
                                              action:
                                                  PermissionRequestResponseAction
                                                      .GRANT);
                                        },
                                        onProgressChanged:
                                            (controller, progress) {
                                          if (progress == 100) {
                                            _pullToRefreshController
                                                .endRefreshing();
                                            isLoading = false;
                                          }
                                          setState(() {
                                            this.progress = progress / 100;
                                          });
                                        },
                                        shouldOverrideUrlLoading: (controller,
                                            navigationAction) async {
                                          var url = navigationAction.request.url
                                              .toString();
                                          var uri = Uri.parse(url);

                                          if (Platform.isIOS &&
                                              url.contains("geo")) {
                                            url = url.replaceFirst('geo://',
                                                'http://maps.apple.com/');
                                          } else if (url.contains("tel:") ||
                                              url.contains("mailto:") ||
                                              url.contains("play.google.com") ||
                                              url.contains("maps") ||
                                              url.contains("messenger.com")) {
                                            url = Uri.encodeFull(url);
                                            try {
                                              if (await canLaunchUrl(uri)) {
                                                launchUrl(uri);
                                              } else {
                                                launchUrl(uri);
                                              }
                                              return NavigationActionPolicy
                                                  .CANCEL;
                                            } catch (e) {
                                              launchUrl(uri);
                                              return NavigationActionPolicy
                                                  .CANCEL;
                                            }
                                          } else if (![
                                            "http",
                                            "https",
                                            "file",
                                            "chrome",
                                            "data",
                                            "javascript",
                                          ].contains(uri.scheme)) {
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(
                                                uri,
                                              );
                                              return NavigationActionPolicy
                                                  .CANCEL;
                                            }
                                          }

                                          return NavigationActionPolicy.ALLOW;
                                        },
                                        onCreateWindow: (controller,
                                            createWindowRequest) async {
                                          if (Platform.isIOS &&
                                              createWindowRequest.request.url
                                                  .toString()
                                                  .contains(
                                                      'snsLogin?sns=apple')) {
                                            setState(
                                              () => _allowClosePopUp = false,
                                            );
                                          }
                                          createWindow(
                                              createWindowRequest.windowId);
                                          return true;
                                        },
                                        onDownloadStartRequest: (controller,
                                            downloadStartRrquest) async {
                                          enableStoragePermision()
                                              .then((status) async {
                                            String url = downloadStartRrquest
                                                .url
                                                .toString();

                                            if (status == true) {
                                              WebviewHandle().handleDownload(
                                                  url: url, context: context);
                                            } else {
                                              openAppSettings();
                                            }
                                          });
                                        },
                                        onUpdateVisitedHistory: (controller,
                                            url, androidIsReload) async {
                                          setState(() {
                                            this.url = url.toString();
                                          });
                                        },
                                        onConsoleMessage:
                                            (controller, message) {
                                          print(
                                              '------console-log: ${message.message}');
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                        'Url is not valid',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      )),
                                noInternet
                                    ? Center(
                                        child: NoInternetWidget(),
                                      )
                                    : SizedBox(height: 0, width: 0),
                                showErrorPage
                                    ? Center(
                                        child: NotFound(
                                            webViewController:
                                                webViewController!,
                                            url: url,
                                            title1: CustomStrings.pageNotFound1,
                                            title2:
                                                CustomStrings.pageNotFound2))
                                    : SizedBox(height: 0, width: 0),
                                slowInternetPage
                                    ? Center(
                                        child: NotFound(
                                            webViewController:
                                                webViewController!,
                                            url: url,
                                            title1: CustomStrings.incorrectURL1,
                                            title2:
                                                CustomStrings.incorrectURL2))
                                    : SizedBox(height: 0, width: 0),
                                progress < 1.0 && _validURL
                                    ? SizeTransition(
                                        sizeFactor: animation,
                                        axis: Axis.horizontal,
                                        child: Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: 5.0,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context)
                                                    .progressIndicatorTheme
                                                    .color!,
                                                Theme.of(context)
                                                    .progressIndicatorTheme
                                                    .refreshBackgroundColor!,
                                                Theme.of(context)
                                                    .progressIndicatorTheme
                                                    .linearTrackColor!,
                                              ],
                                              stops: const [0.1, 1.0, 0.1],
                                            ),
                                          ),
                                        ),
                                      )
                                    : SizedBox.shrink(),
                              ],
                            ),
                    ),
                  )),
            ),
          ],
        ));
  }

  Widget emptyURL() {
    return InAppWebView(
      initialData: InAppWebViewInitialData(
          data: widget.url, mimeType: 'text/html', encoding: "utf8"),
      initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            useShouldOverrideUrlLoading: true,
            cacheEnabled: true,
            verticalScrollBarEnabled: false,
            horizontalScrollBarEnabled: false,
            transparentBackground: true,
            allowFileAccessFromFileURLs: true,
          ),
          android: AndroidInAppWebViewOptions(
              useHybridComposition: true, defaultFontSize: 32),
          ios: IOSInAppWebViewOptions(
            allowsInlineMediaPlayback: true,
          )),
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(
          () => EagerGestureRecognizer(),
        ),
      },
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onLoadStart: (controller, url) {
        print('onloadstart');
        setState(() {
          this.url = url.toString();
        });
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        return NavigationActionPolicy.ALLOW;
      },
    );
  }

  createWindow(windowId) async {
    final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
      Factory(() => EagerGestureRecognizer())
    };

    UniqueKey _key = UniqueKey();
    print('true');
    print('onCreateWindow');
    setState(() {
      isOpenDialog = true;
      isNewWindowLoading = true;
    });
    Future.delayed(
        Duration(seconds: 3),
        (() => {
              setState(
                () {
                  _allowClosePopUp = true;
                },
              )
            }));
    showModalBottomSheet<void>(
      isDismissible: _allowClosePopUp,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10))),
      builder: (BuildContext context) {
        dialogContext = context;
        return StatefulBuilder(builder: (context, setState) {
          return InkWell(
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              _allowClosePopUp ? Navigator.of(context).pop() : null;
            },
            child: Container(
              alignment: Alignment.bottomCenter,
              height: fullHeight(context),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10))),
                height: fullHeight(context) * 0.83,
                width: fullWidth(context),
                child: Stack(alignment: Alignment.bottomCenter, children: [
                  InkWell(
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      _allowClosePopUp ? Navigator.of(context).pop() : null;
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding:
                                EdgeInsets.only(right: perHeight(context, 20)),
                            child: SvgPicture.asset(
                                Theme.of(context).colorScheme.closeIcon,
                                width: 20,
                                height: 20,
                                color: Colors.white),
                          ),
                        ),
                        SizedBox(
                          height: perHeight(context, 20),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.8,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10))),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: perHeight(context, 50),
                                    width: perHeight(context, 50),
                                    child: (isNewWindowLoading == true)
                                        ? Center(
                                            child: CircularProgressIndicator(),
                                          )
                                        : SizedBox(height: 0, width: 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(
                        const Radius.circular(10.0),
                      ),
                      child: InAppWebView(
                        key: _key,
                        initialUrlRequest:
                            URLRequest(url: WebUri.uri(Uri.parse(url))),
                        gestureRecognizers: gestureRecognizers,
                        windowId: windowId,
                        initialOptions: options,
                        onWebViewCreated: (InAppWebViewController controller) {
                          print('false');
                        },
                        onCloseWindow: (controller) => {print('close window')},
                        onLoadStart: (windowController, loadUrl) {
                          print(loadUrl);
                        },
                        shouldOverrideUrlLoading:
                            (controller, navigationAction) async {
                          var url = navigationAction.request.url.toString();

                          return NavigationActionPolicy.ALLOW;
                        },
                        onLoadStop: (controller, loadUrl) async {
                          if (loadUrl.toString().contains("prompt=none")) {
                            webViewController!.loadUrl(
                                urlRequest: URLRequest(
                                    url: WebUri.uri(Uri.parse(
                                        '${webinitialUrl}join/join'))));
                          }
                          if (loadUrl
                                  .toString()
                                  .contains("snsCallback/kakao?code=") ||
                              loadUrl
                                  .toString()
                                  .contains("snsCallback/naver?code=") ||
                              loadUrl
                                  .toString()
                                  .contains("snsCallback/works?code=")) {
                            webViewController!.loadUrl(
                                urlRequest: URLRequest(
                                    url: WebUri.uri(
                                        Uri.parse('$webinitialUrl'))));
                          }

                          setState(() {
                            isNewWindowLoading = false;
                          });
                        },
                        onLoadError: (controller, url, code, message) =>
                            {print('---load error----==$code ---$message')},
                        onCreateWindow: (controller, createWindowAction) async {
                          print('create window 2');
                          createWindow(createWindowAction.windowId);
                          return true;
                        },
                        onProgressChanged: (controller, progress) {},
                        onConsoleMessage: (controller, message) {
                          print('------console-log: ${message.message}');
                        },
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        });
      },
    ).then((value) {
      setState(() {
        isOpenDialog = false;
      });
    });
  }

  Future<void> handleLoginFail() async {
    if (isOpenDialog == true && dialogContext != null) {
      Navigator.of(dialogContext!).pop();
    }
    setState(() {
      isOpenDialog = false;
    });
  }
}
