import 'package:get/get.dart';

import 'categoria_controller.dart';

class CategoriaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CategoriaController());
  }
}
