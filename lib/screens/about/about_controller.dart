import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class AboutController extends GetxController {
  final AuthService _authService = AuthService();
  final box = GetStorage();
  var isSigningOut = false.obs;

  Future<void> logout() async {
    if (isSigningOut.value) return;
    isSigningOut.value = true;
    try {
      await _authService.signOut();
      await box.erase();
      Get.offAllNamed(AppRoutes.LOGIN);
      Get.snackbar('Sesión cerrada', 'Has cerrado sesión correctamente', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Cerrar sesión', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSigningOut.value = false;
    }
  }
}