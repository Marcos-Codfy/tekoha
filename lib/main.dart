// lib/main.dart
// Ponto de entrada do app Tekoha.
// Responsavel: Marcos
//
// Sprint 3: registrou MultiProvider com Auth e Content.
// Atualizado: rota `home` aponta pra MainScaffold (com bottom nav).
// O flag `kBypassAuth` (em app_flags.dart) pula splash+login pra dev/teste.
//
// Resiliencia (importante!): tanto dotenv.load quanto Firebase.initializeApp
// estao envoltos em try/catch. Se falharem (ex.: rodando no Chrome, onde
// Firebase web ainda nao foi configurado), o app NAO trava — apenas loga
// aviso no console e segue. Funcionalidades que dependem dessas camadas
// (login, Airtable sem .env) mostram erro proprio na UI.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/constants/app_flags.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/services/airtable_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/content_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/main_scaffold.dart';
import 'presentation/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Carrega .env ──────────────────────────────────────────────────
  // Se faltar (ex.: rodou de uma worktree sem o arquivo), nao quebra
  // o app — o AirtableService vai exibir mensagem amigavel na UI.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[Tekoha] AVISO: nao foi possivel carregar .env: $e');
    debugPrint('[Tekoha] As variaveis do Airtable estarao vazias.');
  }

  // ── Inicializa Firebase ───────────────────────────────────────────
  // No Chrome o `currentPlatform` lanca UnsupportedError porque Firebase
  // web ainda nao foi registrado. Pulamos a inicializacao nesse caso
  // pra deixar o app carregar mesmo assim (login fica desativado).
  //
  // PRA ATIVAR FIREBASE NO WEB DE VERDADE: rode na pasta do projeto:
  //   flutterfire configure --platforms=web
  // Isso registra um Web App no projeto tekoha-d0179 e atualiza este
  // arquivo com a config web.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (kIsWeb) {
      debugPrint('[Tekoha] Firebase nao configurado pra web — login desativado.');
      debugPrint('[Tekoha] Pra ativar: rode "flutterfire configure --platforms=web".');
    } else {
      debugPrint('[Tekoha] Erro ao inicializar Firebase: $e');
    }
  }

  runApp(const TekohaApp());
}

class TekohaApp extends StatelessWidget {
  const TekohaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Instancia o servico que conversa com o Airtable.
    // Criado UMA UNICA VEZ aqui no topo e injetado no ContentProvider.
    final airtableService = AirtableService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider(airtableService)),
      ],
      child: MaterialApp(
        title: 'Tekoha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Bypass: pula splash e login, abre direto no MainScaffold.
        // Pra reativar o login: kBypassAuth = false em app_flags.dart.
        initialRoute: kBypassAuth ? AppRoutes.home : AppRoutes.splash,
        routes: {
          AppRoutes.splash:   (context) => const SplashScreen(),
          AppRoutes.login:    (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          // `home` agora aponta pra MainScaffold (que contem as 4 abas).
          // Login/register continuam navegando pra ca apos sucesso.
          AppRoutes.home:     (context) => const MainScaffold(),
        },
      ),
    );
  }
}
