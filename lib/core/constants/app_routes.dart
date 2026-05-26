// lib/core/constants/app_routes.dart
// Nomes das rotas de navegacao registradas no MaterialApp.
//
// Rotas internas do MainScaffold (Pratica, Cultura, Perfil, LessonScreen)
// NAO vivem aqui — sao trocas de aba ou Navigator.push diretos.

class AppRoutes {
  AppRoutes._();

  static const String splash   = '/';
  static const String login    = '/auth/login';
  static const String register = '/auth/register';

  /// Casca principal apos login: MainScaffold com bottom nav de 4 abas.
  static const String home     = '/home';
}
