// lib/main.dart
// Ponto de entrada do app Tekoha.
//
// ╭─ ARQUITETURA EM 30 SEGUNDOS ──────────────────────────────────────╮
// │                                                                   │
// │   lib/                                                            │
// │   ├── core/         constantes, tema, helpers puros               │
// │   ├── data/         models, contratos (repository), services      │
// │   ├── presentation/ providers (estado), screens, widgets          │
// │   ├── firebase_options.dart   (gerado pelo flutterfire)           │
// │   └── main.dart     (este arquivo — ponto de entrada)             │
// │                                                                   │
// │   Fluxo de dependencia: UI -> Provider -> Repository -> Service   │
// │   (camada de cima nunca importa direto da de baixo da cadeia)     │
// │                                                                   │
// ╰───────────────────────────────────────────────────────────────────╯
//
// O que main() faz, em ordem:
//   1. Inicializa o Flutter
//   2. Carrega as variaveis do .env (chaves Airtable)
//   3. Inicializa o Firebase (Auth + Firestore)
//   4. Constroi os Providers (Auth + Content) com o MultiProvider
//   5. Roda o MaterialApp com a rota inicial certa (depende do kBypassAuth)
//
// RESILIENCIA: dotenv.load e Firebase.initializeApp estao em try/catch.
// Se falharem (ex.: web sem config Firebase), o app NAO trava — so loga
// aviso e segue. Funcionalidades que precisam dessas camadas mostram
// erro proprio na UI quando forem usadas.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/constants/app_flags.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/content_repository.dart';
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
  // Isso registra um Web App no projeto tekoha-d0179 e atualiza o
  // arquivo firebase_options.dart automaticamente.
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
    // Criado UMA UNICA VEZ aqui no topo e injetado no ContentProvider —
    // essa e a "injecao de dependencia" manual. Pra trocar Airtable por
    // outra fonte (Firebase, mock), so trocar a classe aqui.
    final ContentRepository contentRepository = AirtableService();

    return MultiProvider(
      providers: [
        // AuthProvider escuta o estado de login do Firebase Auth.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ContentProvider gerencia modulos, licoes e palavras (cache em memoria).
        ChangeNotifierProvider(create: (_) => ContentProvider(contentRepository)),
      ],
      child: MaterialApp(
        title: 'Tekoha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Se o flag estiver `true`, pula splash + login e abre direto no
        // MainScaffold. Util pra desenvolvimento. Pra reativar o login
        // de verdade: muda kBypassAuth pra false em app_flags.dart.
        initialRoute: kBypassAuth ? AppRoutes.home : AppRoutes.splash,
        routes: {
          AppRoutes.splash:   (context) => const SplashScreen(),
          AppRoutes.login:    (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          // `home` aponta pra MainScaffold (a casca com bottom nav de 4 abas).
          // Login/register navegam pra ca apos sucesso.
          AppRoutes.home:     (context) => const MainScaffold(),
        },
      ),
    );
  }
}
