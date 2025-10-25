import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  final _box = GetStorage();

  @override
  RouteSettings? redirect(String? route) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? uid = _box.read<String>('auth_uid');

    final bool isAuthenticated = user != null && uid != null && uid.isNotEmpty;

    // Permitir siempre acceder a Splash y Login
    final allowedRoutes = {AppRoutes.SPLASH, AppRoutes.LOGIN};
    if (allowedRoutes.contains(route)) {
      return null;
    }

    // Si no autenticado, redirigir a Login
    if (!isAuthenticated) {
      return const RouteSettings(name: AppRoutes.LOGIN);
    }

    return null; // continuar a la ruta solicitada
  }
}