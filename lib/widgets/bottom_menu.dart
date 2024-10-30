import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:wwwow_mobile/helpers/Icons.dart';
import 'package:wwwow_mobile/provider/webviewURLProvider.dart';

import '../helpers/Constant.dart';
import '../helpers/Themes.dart';

class BottomMenu extends StatefulWidget {
  InAppWebViewController? webViewController;
  final void Function(VoidCallback fn) setState;
  BottomMenu(
      {Key? key, required this.webViewController, required this.setState})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _BottomMenu();
}

class _BottomMenu extends State<BottomMenu> {
  late int _tabNumber;

  @override
  void initState() {
    _tabNumber = 2;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      clipBehavior: Clip.none,
      child: Platform.isIOS
          ? SizedBox(
              height: perHeight(context, Platform.isIOS ? 75 : 50),
              child: Column(
                children: [
                  bottomRow(),
                  Container(
                    height: Platform.isIOS ? perHeight(context, 25) : 0,
                    width: fullWidth(context),
                    color: Colors.white,
                  )
                ],
              ))
          : bottomRow(),
    );
  }

  Widget bottomRow() {
    return Container(
      height: perHeight(context, 50),
      width: double.infinity,
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          image: DecorationImage(
              image: AssetImage('assets/images/bottom_menu_frame.png'),
              fit: BoxFit.cover)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child: _bottomMenuIcon(Theme.of(context).colorScheme.planProjectIcon,
              tabNumber: 0, text: '기획 프로젝트'),
        ),
        Expanded(
          child: _bottomMenuIcon(Theme.of(context).colorScheme.acchiveIcon,
              tabNumber: 1, text: '운영 프로젝트'),
        ),
        Expanded(
          child: _homeButton(),
        ),
        Expanded(
          child: _bottomMenuIcon(Theme.of(context).colorScheme.happyIcon,
              tabNumber: 3, text: '파트너'),
        ),
        Expanded(
          child: _bottomMenuIcon(Theme.of(context).colorScheme.accountIcon,
              tabNumber: 4, text: '마이 페이지'),
        ),
      ]),
    );
  }

  Widget _bottomMenuIcon(String icon,
      {onTap,
      required tabNumber,
      required text,
      double width = 24,
      double height = 24}) {
    bool isLoginPage =
        context.read<WebviewURLProvider>().currentURL.contains('Join') ||
            context.read<WebviewURLProvider>().currentURL.contains('join');
    bool isCurrentPage = context.read<WebviewURLProvider>().currentURL ==
        listBottomUrl[tabNumber];
    Color buttonColor = (_tabNumber == tabNumber && !isLoginPage)
        ? const Color(0xff02D3AE)
        : const Color(0xff777777);
    if (isCurrentPage) {
      setState(() {
        _tabNumber = tabNumber;
      });
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => {
          if (onTap != null) onTap(),
          widget.webViewController!.loadUrl(
              urlRequest: URLRequest(
                  url: WebUri.uri(Uri.parse(listBottomUrl[tabNumber])))),
          setState(() {
            _tabNumber = tabNumber;
          })
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: width,
              height: height,
              color: buttonColor,
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: perHeight(context, 10),
                color: buttonColor,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _homeButton() {
    bool isCurrentPage =
        context.read<WebviewURLProvider>().currentURL == listBottomUrl[2];

    if (isCurrentPage) {
      setState(() {
        _tabNumber = 2;
      });
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned(
            bottom: perHeight(context, 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onTap: () => {
                        widget.webViewController!.loadUrl(
                            urlRequest: URLRequest(
                                url: WebUri.uri(Uri.parse(listBottomUrl[2])))),
                        setState(() {
                          _tabNumber = 2;
                        }),
                      },
                  child: Container(
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 0.5,
                        blurRadius: 2,
                        offset: Offset(0, 0),
                      ),
                    ], shape: BoxShape.circle),
                    child: Image.asset(
                      'assets/images/home_button.png',
                      height: perHeight(context, 48),
                      width: perHeight(context, 48),
                    ),
                  )),
            ))
      ],
    );
  }
}
