import 'package:cacao_apps/core/db/user_repository.dart';
import 'package:cacao_apps/core/storage/token_storage.dart';
import '../../../core/model/user.model.dart';

class SettingsController {
  final UserRepository userRepository =UserRepository();
  // settings_controller.dart
Future<void> logout() async {
  try {
    await TokenStorage().clear();
    await userRepository.clearUsers();
  } catch (e) {
    await TokenStorage().clear(); 
  }
}

Future<LocalUser?> getCurrentUser() async {
  try {
    return await userRepository.getCurrentUser();
  } catch (e) {
    return null;
  }
}
}