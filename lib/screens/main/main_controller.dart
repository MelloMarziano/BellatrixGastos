import 'package:flutter/material.dart';
import 'package:gastos/screens/ahorro/ahorro_screen.dart';
import 'package:gastos/screens/reportes/reportes_screen.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../home/home_screen.dart';
import '../categorias/categoria_screen.dart';
import '../presupuesto/presupuesto_screen.dart';

class MainController extends GetxController {
  // Screen currently shown (puedes usarlo más adelante si deseas cambiar de vista)
  Widget mainScreenActive = HomeScreen();

  // Índice del botón activo en el bottom nav
  int selectedIndex = 0;

  var box = GetStorage();

  void changeScreenActive(Widget screen) {
    mainScreenActive = screen;
    update();
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    // Cambia la vista activa basada en el índice seleccionado
    switch (index) {
      case 0:
        mainScreenActive = HomeScreen();
        break;
      case 1:
        mainScreenActive = const ReportesScreen();
        break;
      case 2:
        mainScreenActive = const CategoriaScreen();
        break;
      case 3:
        mainScreenActive = const AhorroScreen();
        break;
      case 4:
        mainScreenActive = const PresupuestoScreen();
        break;
    }
    update();
  }
}
