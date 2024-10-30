import 'package:flutter/material.dart';
import 'package:wwwow_mobile/widgets/webview/load_web_view.dart';

class HomeScreen extends StatefulWidget {
  final String url;
  final bool mainPage;
  const HomeScreen(this.url, {Key? key, this.mainPage = true})
      : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen>, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late AnimationController navigationContainerAnimationController =
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void dispose() {
    navigationContainerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LoadWebView(
      url: widget.url,
      webUrl: true,
    );
  }
}
