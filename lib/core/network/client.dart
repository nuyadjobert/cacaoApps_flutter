import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

class DioClient {
  static late final Dio dio;

  static void init({
    required String baseUrl,
    required Future<String?> Function() getToken,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  

    dio.interceptors.add(AuthInterceptor(getToken));
  }
}
