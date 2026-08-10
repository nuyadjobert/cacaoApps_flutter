import 'package:dio/dio.dart';

class ProfileService {
  final Dio dio;

  ProfileService({required this.dio});

  /// Update user profile on the backend
  /// Throws DioException on failure
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? address,
    String? contactNumber,
  }) async {
    final Map<String, dynamic> payload = {};

    if (name != null) {
      payload['name'] = name;
    }

    if (address != null) {
      payload['address'] = address;
    }

    if (contactNumber != null) {
      payload['contact_number'] = contactNumber;
    }

    if (payload.isEmpty) {
      return; // Nothing to update
    }

    final response = await dio.put(
      '/api/theobrotect/users/$userId',
      data: payload,
    );

    if (response.statusCode != 200) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Failed to update profile: ${response.statusCode}',
      );
    }
  }

  /// Check if the backend server is reachable
  Future<bool> isServerReachable() async {
    try {
      final response = await dio.head(
        '/api/theobrotect/test',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
