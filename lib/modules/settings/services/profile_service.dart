import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cacao_apps/core/network/server_reachability_service.dart';

class ProfileService {
  final Dio dio;
  late final ServerReachabilityService _serverReachability;

  ProfileService({required this.dio}) {
    _serverReachability = ServerReachabilityService(dio: dio);
  }

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

    final endpoint = '/api/theobrotect/users/$userId';
    debugPrint('[ProfileService] PATCH $endpoint payload=$payload');

    try {
      final response = await dio.patch(
        endpoint,
        data: payload,
      );

      final statusCode = response.statusCode;
      final hasAuthHeader =
          response.requestOptions.headers.containsKey('Authorization');
      debugPrint(
        '[ProfileService] Response status=$statusCode '
        'authenticated=$hasAuthHeader data=${response.data}',
      );

      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Failed to update profile: $statusCode',
        );
      }
    } on DioException catch (error) {
      final hasAuthHeader =
          error.requestOptions.headers.containsKey('Authorization');
      debugPrint(
        '[ProfileService] Update failed status=${error.response?.statusCode} '
        'authenticated=$hasAuthHeader data=${error.response?.data} '
        'error=${error.message}',
      );
      rethrow;
    }
  }

  /// Check if the backend server is reachable
  Future<bool> isServerReachable() async {
    final reachable = await _serverReachability.isReachable();
    debugPrint(
      '[ProfileService] Server is ${reachable ? 'reachable' : 'unreachable'}',
    );
    return reachable;
  }
}
