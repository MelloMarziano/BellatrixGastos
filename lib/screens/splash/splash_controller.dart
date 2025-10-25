import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final box = GetStorage();
  var isLoading = false;

  @override
  void onInit() {
    super.onInit();
    loadHome();
  }

  loadHome() {
    final userName = box.read('f_nombre_usuario');
    final delay = const Duration(seconds: 5);
    if (userName != null) {
      Timer(delay, () {
        Get.offNamed(AppRoutes.MAIN);
      });
    } else {
      Timer(delay, () {
        Get.offNamed(AppRoutes.LOGIN);
      });
    }
  }
}
