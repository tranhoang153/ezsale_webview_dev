import 'package:flutter/foundation.dart';

class RouteProvider extends ChangeNotifier {
  String _route = "/";

  void setRoute(String route) {
    _route = route;
    notifyListeners();
  }

  String get route => _route;
}
