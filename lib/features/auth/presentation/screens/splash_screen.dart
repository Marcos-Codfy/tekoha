// lib/features/auth/presentation/screens/splash_screen.dart
// Splash inicial. So aparece quando kBypassAuth = false (login ativo).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_flags.dart';
import '../../../../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;

    // Defesa em profundidade: se kBypassAuth estiver ON, a Splash NUNCA
    // navega pra login. Vai direto pra Home, independente do estado do
    // AuthProvider. Evita race conditions em builds antigas no cache do
    // device ou caminhos de navegacao residuais.
    if (kBypassAuth) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                  height: 180,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.flutter_dash,
                    size: 120,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _textFade,
              child: const Text(
                'Tekoha',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            FadeTransition(
              opacity: _textFade,
              child: const Text(
                'O lugar onde se vive a cultura',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 56),
            FadeTransition(
              opacity: _textFade,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
