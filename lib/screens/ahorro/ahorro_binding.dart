import 'package:get/get.dart';

import 'ahorro_controller.dart';

class AhorroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AhorroController());
  }
}
