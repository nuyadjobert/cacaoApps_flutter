import 'package:dio/dio.dart';

class ServerReachabilityService {
  final Dio dio;

  const ServerReachabilityService({required this.dio});

  Future<bool> isReachable() async {
    try {
      final response = await dio.get<Object?>(
        '/api/theobrotect/test',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      final statusCode = response.statusCode;
      return statusCode != null && statusCode < 500;
    } catch (_) {
      return false;
    }
  }
}
