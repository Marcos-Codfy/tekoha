// lib/features/home/presentation/screens/home_screen.dart
//
// Aba "Home" do MainScaffold. Dashboard de boas-vindas com CTAs pra
// Pratica e Cultura.

import 'package:flutter/material.dart';

import '../../../../core/components/badges/tekoha_status_pill.dart';
import '../../../../core/components/buttons/tekoha_primary_button.dart';
import '../../../../core/components/buttons/tekoha_secondary_button.dart';
import '../../../../core/components/texts/tekoha_section_label.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_flags.dart';

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
            const Text(
              'Puranga pituna!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bem-vindo ao Tekohá',
              style: TextStyle(
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
              onPressed: onStartPractice,
            ),
            const SizedBox(height: 12),
            TekohaSecondaryButton(
              label: 'Explorar a cultura indígena',
              icon: Icons.diversity_3_outlined,
              onPressed: onOpenCulture,
            ),
            const SizedBox(height: 32),
            const TekohaSectionLabel('Seu progresso'),
            const SizedBox(height: 8),
            const _DashboardCard(
              icon: Icons.local_fire_department,
              title: 'Sequencia',
              value: '0 dias',
              isLocked: true,
            ),
            const SizedBox(height: 12),
            const _DashboardCard(
              icon: Icons.star,
              title: 'XP total',
              value: '0 XP',
              isLocked: true,
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

  /// Quando `true`, sobrepoe overlay com "Em breve". Mesmo padrao visual
  /// dos ModuleCards bloqueados da aba Aprenda. Sprint futura: passar
  /// `false` e ligar nos valores reais do Firestore.
  final bool isLocked;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
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

    if (!isLocked) return cardContent;

    return Stack(
      children: [
        cardContent,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: const Color(0xE6F5F5F5),
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Em breve',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
