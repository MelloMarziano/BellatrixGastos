import 'package:gastos/screens/reportes/reportes_controller.dart';
import 'package:get/get.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportesController>(() => ReportesController());
  }
}
