import 'package:dio/dio.dart';
import '../models/disease_counts_model.dart';

class StatisticsService {
  final Dio dio;

  StatisticsService({required this.dio});
  Future<DiseaseCountsModel> getUserDiseaseCounts({int? year}) async {
    try {
      final queryParams = year != null ? {'year': year.toString()} : null;

      final response = await dio.get(
        '/api/theobrotect/scans/user/disease-counts',
        queryParameters: queryParams,
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Invalid response format: expected Map, got ${data.runtimeType}',
        );
      }

      if (data['status'] != 'OK') {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'API returned non-OK status: ${data['status']}',
        );
      }

      if (data['data'] == null) {
        return DiseaseCountsModel.empty();
      }

      final countsData = data['data'] as Map<String, dynamic>;
      final counts = DiseaseCountsModel.fromJson(countsData);

      return counts;
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }


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
    } catch (e) {
      return false;
    }
  }
}
