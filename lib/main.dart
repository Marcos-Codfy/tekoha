// lib/main.dart
// Ponto de entrada do aplicativo TekohÃ¡
// ResponsÃ¡vel: Marcos
//
// Ordem de inicializaÃ§Ã£o:
//   1. Flutter pronto
//   2. Carrega variÃ¡veis do .env
//   3. Inicializa Firebase
//   4. Sobe o app

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';

Future<void> main() async {
  // Garante que o Flutter estÃ¡ pronto antes de qualquer coisa
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega as variÃ¡veis secretas do arquivo .env
  await dotenv.load(fileName: '.env');

  // TODO Sprint 1: Adicionar inicializacao do Firebase aqui
  // apÃ³s configurar o FlutterFire CLI (google-services.json)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const TekohaApp());
}

class TekohaApp extends StatelessWidget {
  const TekohaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TekohÃ¡',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash:  (context) => const SplashScreen(),
        AppRoutes.login:   (context) => const LoginScreen(),
        AppRoutes.home:    (context) => const HomeScreen(),
      },
    );
  }
}

/// Tela de splash â€” aparece enquanto o app carrega
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tekohá',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'O lugar onde se vive a cultura',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
