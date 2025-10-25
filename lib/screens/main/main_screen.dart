import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../routes/app_routes.dart';
import 'main_controller.dart';
import 'widgets/main_nav_button.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainController>(
      init: MainController(),
      builder: (controller) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F5F9),
          elevation: 0,
          title: Text(
            'Control Financiero',
            style: GoogleFonts.nunito(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: 0.3,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              color: const Color(0xFF2A65CC),
              tooltip: 'Acerca de',
              onPressed: () => Get.toNamed(AppRoutes.ABOUT),
            ),
          ],
        ),
        body: Container(
          height: double.infinity,
          width: double.infinity,
          color: const Color(0xFFF2F5F9),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.grey,
                  child: controller.mainScreenActive,
                ),
              ),
              SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      Expanded(
                        child: MainNavButton(
                          label: 'Inicio',
                          icon: LucideIcons.house,
                          isActive: controller.selectedIndex == 0,
                          onTap: () => controller.setSelectedIndex(0),
                          showLabel: false,
                        ),
                      ),
                      Expanded(
                        child: MainNavButton(
                          label: 'Reportes',
                          icon: LucideIcons.chart_bar,
                          isActive: controller.selectedIndex == 1,
                          onTap: () => controller.setSelectedIndex(1),
                          showLabel: false,
                        ),
                      ),
                      Expanded(
                        child: MainNavButton(
                          label: 'Categorías',
                          icon: LucideIcons.folder,
                          isActive: controller.selectedIndex == 2,
                          onTap: () => controller.setSelectedIndex(2),
                          showLabel: false,
                        ),
                      ),
                      Expanded(
                        child: MainNavButton(
                          label: 'Ahorro',
                          icon: LucideIcons.wallet,
                          isActive: controller.selectedIndex == 3,
                          onTap: () => controller.setSelectedIndex(3),
                          showLabel: false,
                        ),
                      ),
                      Expanded(
                        child: MainNavButton(
                          label: 'Presupuesto',
                          icon: LucideIcons.badge_percent,
                          isActive: controller.selectedIndex == 4,
                          onTap: () => controller.setSelectedIndex(4),
                          showLabel: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // FloatingActionButton removido para evitar superposición
      ),
    );
  }
}
