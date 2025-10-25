import 'package:gastos/screens/categorias/categoria_binding.dart';
import 'package:gastos/screens/categorias/categoria_screen.dart';
import 'package:get/get.dart';

import '../screens/home/home_binding.dart';
import '../screens/home/home_screen.dart';
import '../screens/main/main_binding.dart';
import '../screens/main/main_screen.dart';
import '../screens/splash/splash_binding.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/login/login_binding.dart';
import '../screens/login/login_screen.dart';
import 'app_routes.dart';
import '../screens/about/about_binding.dart';
import '../screens/about/about_screen.dart';
import 'auth_middleware.dart';

class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.MAIN,
      page: () => MainScreen(),
      binding: MainBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.HOME,
      page: () => HomeScreen(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.CATEGORIA,
      page: () => CategoriaScreen(),
      binding: CategoriaBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ABOUT,
      page: () => const AboutScreen(),
      binding: AboutBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
