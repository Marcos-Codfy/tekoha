// lib/features/home/presentation/screens/home_screen.dart
//
// Aba "Home" do MainScaffold. Dashboard de boas-vindas com CTAs pra
// Pratica e Cultura.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/badges/tekoha_status_pill.dart';
import '../../../../core/components/buttons/tekoha_primary_button.dart';
import '../../../../core/components/buttons/tekoha_secondary_button.dart';
import '../../../../core/components/texts/tekoha_section_label.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_flags.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../progress/presentation/providers/user_progress_provider.dart';

class HomeScreen extends StatefulWidget {
  /// Callback pra ir direto pra aba "Aprenda". MainScaffold injeta.
  final VoidCallback? onStartPractice;

  /// Callback pra ir direto pra aba "Cultura". MainScaffold injeta.
  final VoidCallback? onOpenCulture;

  const HomeScreen({
    super.key,
    this.onStartPractice,
    this.onOpenCulture,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProgressProvider>().ensureLoaded();
      }
    });
  }

  /// Saudacao em Nheengatu pelo horario — o proprio app FALA a lingua
  /// que ensina (consistencia + Dual Coding: o usuario reve as tres
  /// primeiras expressoes da trilha em contexto real de uso).
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Puranga ara!';
    if (hour >= 12 && hour < 18) return 'Puranga karuka!';
    return 'Puranga pituna!';
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<UserProgressProvider>();
    final displayName = context.select<AuthProvider, String?>(
      (a) => a.currentUser?.displayName,
    );
    final firstName =
        (displayName ?? '').trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tekoha'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kBypassAuth) ...[
              const TekohaStatusPill(
                icon: Icons.bug_report_outlined,
                label: 'Modo de demonstração',
              ),
              const SizedBox(height: 24),
            ],
            Text(
              _greeting(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              firstName.isEmpty
                  ? 'Bem-vindo ao Tekohá'
                  : 'Bem-vindo de volta, $firstName',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aprenda o Nheengatu, uma língua indígena viva falada por '
              'comunidades do Alto Rio Negro. Cada palavra que você '
              'pratica é uma palavra que continua viva.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            TekohaPrimaryButton(
              label: 'Praticar Nheengatu',
              icon: Icons.play_arrow,
              onPressed: widget.onStartPractice,
            ),
            const SizedBox(height: 12),
            TekohaSecondaryButton(
              label: 'Explorar a cultura indígena',
              icon: Icons.diversity_3_outlined,
              onPressed: widget.onOpenCulture,
            ),
            const SizedBox(height: 32),
            const TekohaSectionLabel('Seu progresso'),
            const SizedBox(height: 8),
            _DashboardCard(
              icon: Icons.local_fire_department,
              title: 'Sequência',
              value: progress.streakDays == 1
                  ? '1 dia'
                  : '${progress.streakDays} dias',
            ),
            const SizedBox(height: 12),
            _DashboardCard(
              icon: Icons.star,
              title: 'XP total',
              value: '${progress.xp} XP',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    // Valores REAIS persistidos (ESP-006/007) — o overlay "Em breve"
    // que existia aqui foi aposentado junto com o modo demonstracao.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
