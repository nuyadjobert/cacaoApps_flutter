import 'package:dio/dio.dart';
import './cacao_guide_repository.dart';

class GuideSyncService {
  final Dio dio;
  final CacaoGuideRepository guideRepository;

  GuideSyncService({
    required this.dio,
    required this.guideRepository,
  });

  Future<bool> fetchUpdatesFromServer() async {
    try {
      final response = await dio.get(
        '/api/theobrotect/disease-breakdown-view',
      );

      if (response.statusCode == 200) {
        if (response.data is! List) {
          return false;
        }

        final List<dynamic> backendPayload = response.data;

        if (backendPayload.isEmpty) {
          return false;
        }
        await guideRepository.syncCacaoGuide(
          backendPayload,
        );

        return true;
      } else {
        return false;
      }
    } on DioException {
      final stillEmpty = await guideRepository.isDatabaseEmpty();

      if (stillEmpty) {
        throw Exception(
          'Initial guide download failed. '
          'Internet connection is required '
          'for first launch.',
        );
      }

      return false;
    } catch (_) {
      final stillEmpty = await guideRepository.isDatabaseEmpty();

      if (stillEmpty) {
        throw Exception(
          'Failed to initialize local guide database.',
        );
      }

      return false;
    }
  }
}
