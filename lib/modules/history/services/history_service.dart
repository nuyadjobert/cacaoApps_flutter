import 'dart:io';
import 'package:cacao_apps/core/db/scan_repository.dart';
class HistoryService {
  // 2. Initialize the repository
  final ScanRepository _scanRepository = ScanRepository();

  Future<List<Map<String, dynamic>>> getHistoryByUserId(String userId) async {
    // 3. Ask the repository for the data
    return await _scanRepository.getHistoryByUserId(userId);
  }

  Future<void> deleteImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Error handled silently
    }
  }

  Future<void> deleteScan({
    required String localId,
    required String userId,
    String? imagePath,
  }) async {
    // 4. Ask the repository to delete the database record
    await _scanRepository.deleteHistoryItem(
      localId: localId,
      userId: userId,
    );

    // 5. Delete the physical image file
    await deleteImageFile(imagePath);
  }
}