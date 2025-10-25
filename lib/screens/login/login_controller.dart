import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class LoginController extends GetxController {
  final box = GetStorage();
  final AuthService _authService = AuthService();
  var isLoading = false.obs;

  Future<void> signInWithGoogle() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final UserCredential credential = await _authService.signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw Exception('Usuario no disponible tras autenticación');
      }
      // Persistir datos clave para uso futuro en el sistema
      final profile = {
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'provider': 'google',
        'lastLogin': DateTime.now().toIso8601String(),
      };
      box.write('auth_user', profile);
      box.write('auth_uid', user.uid);
      box.write('auth_email', user.email);
      box.write('auth_photo', user.photoURL);
      // Clave usada por Splash para determinar si hay sesión previa
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        box.write('f_nombre_usuario', user.displayName);
      } else {
        box.write('f_nombre_usuario', user.email ?? user.uid);
      }

      Get.offAllNamed(AppRoutes.MAIN);
    } catch (e) {
      Get.snackbar(
        'Inicio de sesión',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}