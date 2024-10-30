import 'package:dio/dio.dart';
import 'package:wwwow_mobile/helpers/Constant.dart';

class HttpConfig {
  static Map<String, String> header = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Response> post(dynamic params, String apiName) async {
    final dio = Dio();
    final response = await dio.post(baseURL + apiName, data: params);
    return response;
  }
}
