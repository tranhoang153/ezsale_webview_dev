import 'package:dio/dio.dart';
import 'package:wwwow_mobile/services/rest_api/http_config.dart';

class FcmAPI {
  Future<Response> saveFCMToken(params) {
    return HttpConfig.post(params, 'Member/fcm_regist');
  }
}
