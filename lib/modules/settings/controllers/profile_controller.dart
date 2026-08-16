import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cacao_apps/core/db/user_repository.dart';
import 'package:cacao_apps/core/db/sync_queue_reporitory.dart';
import 'package:cacao_apps/core/model/user.model.dart';
import 'package:cacao_apps/core/network/client.dart';
import 'package:cacao_apps/core/services/connectivity_service.dart';
import '../services/profile_service.dart';

enum ProfileUpdateResult {
  successOnline,
  savedOffline,
  error,
}

class UserProfileController extends ChangeNotifier {
  final UserRepository _repository = UserRepository();
  final SyncQueueRepository _syncQueueRepository = SyncQueueRepository();
  final ConnectivityService _connectivityService = ConnectivityService();
  late final ProfileService _profileService;

  LocalUser? user;
  bool isLoading = true;
  String? lastError;

  UserProfileController() {
    _profileService = ProfileService(dio: DioClient.dio);
  }

  Future<void> loadUser() async {
    isLoading = true;
    notifyListeners();

    user = await _repository.getCurrentUser();

    isLoading = false;
    notifyListeners();
  }

  Future<ProfileUpdateResult> updateProfile({
    String? name,
    String? address,
    String? contactNumber,
  }) async {
    if (user == null) {
      lastError = 'No user found';
      return ProfileUpdateResult.error;
    }

    final Map<String, dynamic> payload = {};
    if (name != null) payload['name'] = name;
    if (address != null) payload['address'] = address;
    if (contactNumber != null) payload['contact_number'] = contactNumber;

    if (payload.isEmpty) {
      return ProfileUpdateResult.successOnline; 
    }

    final hasConnection = await _connectivityService.hasConnection;

    ProfileUpdateResult result;

    if (hasConnection) {
      final serverReachable = await _profileService.isServerReachable();
      
      if (serverReachable) {
        try {
          await _profileService.updateProfile(
            userId: user!.userId,
            name: name ?? user!.name,
            address: address ?? user!.address,
            contactNumber: contactNumber ?? user!.contactNumber,
          );

          await _repository.updateUser(
            userId: user!.userId,
            name: name,
            address: address,
            contactNumber: contactNumber,
          );

          await _syncQueueRepository.deletePending(
            tableName: 'users',
            recordId: user!.userId,
            action: 'update',
          );
          debugPrint(
            '[ProfileController] Server update confirmed; local profile '
            'updated and pending sync cleared for user=${user!.userId}',
          );

          user = LocalUser(
            userId: user!.userId,
            email: user!.email,
            createdAt: user!.createdAt,
            name: name ?? user!.name,
            address: address ?? user!.address,
            contactNumber: contactNumber ?? user!.contactNumber,
          );

          result = ProfileUpdateResult.successOnline;
        } on DioException catch (e) {
          lastError = e.message;
          debugPrint(
            '[ProfileController] Server update failed; saving locally and '
            'queueing retry. error=$lastError',
          );
          
          // API failed, save offline
          await _saveOffline(name, address, contactNumber, payload);
          result = ProfileUpdateResult.savedOffline;
        } catch (e) {
          lastError = e.toString();
          debugPrint(
            '[ProfileController] Unexpected update error; saving locally and '
            'queueing retry. error=$lastError',
          );
          
          // Unexpected error, save offline
          await _saveOffline(name, address, contactNumber, payload);
          result = ProfileUpdateResult.savedOffline;
        }
      } else {
        await _saveOffline(name, address, contactNumber, payload);
        result = ProfileUpdateResult.savedOffline;
      }
    } else {
      // No connection, save offline
      await _saveOffline(name, address, contactNumber, payload);
      result = ProfileUpdateResult.savedOffline;
    }

    notifyListeners();
    return result;
  }

  Future<void> _saveOffline(
    String? name,
    String? address,
    String? contactNumber,
    Map<String, dynamic> payload,
  ) async {
    await _repository.updateUser(
      userId: user!.userId,
      name: name,
      address: address,
      contactNumber: contactNumber,
    );

    user = LocalUser(
      userId: user!.userId,
      email: user!.email,
      createdAt: user!.createdAt,
      name: name ?? user!.name,
      address: address ?? user!.address,
      contactNumber: contactNumber ?? user!.contactNumber,
    );

    await _syncQueueRepository.add(
      tableName: 'users',
      recordId: user!.userId,
      action: 'update',
      payload: payload,
    );
    debugPrint(
      '[ProfileController] Local profile saved; pending sync queued '
      'for user=${user!.userId} payload=$payload',
    );
  }
}
