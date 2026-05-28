// lib/presentation/screens/home/home_screen.dart
// Aba "Home" do MainScaffold. Dashboard simples de boas-vindas, com CTA
// que joga o usuario direto na aba "Pratica".
// Responsavel: Marcos (Sprint 3, gerado por Claude)

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_flags.dart';

class HomeScreen extends StatelessWidget {
  /// Callback pra mandar o usuario direto pra aba "Aprenda".
  /// O MainScaffold (que conhece o indice da aba) injeta esse callback.
  final VoidCallback? onStartPractice;

  /// Callback pra mandar o usuario direto pra aba "Cultura".
  /// Mesma logica do [onStartPractice] — injetado pelo MainScaffold.
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
            // ── Badge "modo de teste" (so se login estiver desativado) ─
            if (kBypassAuth) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bug_report_outlined, size: 16, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Modo de teste — login desativado',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Saudacao em Nheengatu (palavra verificada do banco) ────
            // "Puranga pituna" = "Boa noite". A apresentacao da demo e a
            // noite — saudacao casa com o horario do publico.
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
              'comunidades do Alto Rio Negro. Cada palavra que você aprende '
              'ajuda a preservar uma cosmovisão única.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // ── CTA principal: leva pra aba "Aprenda" ──────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartPractice,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Começar a praticar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── CTA secundario: leva pra aba "Cultura" ─────────────────
            // Estilo outline pra nao competir com o CTA primario, mas
            // ainda convidativo. Icone bate com o do bottom nav da Cultura
            // (auto_stories) — o usuario associa visualmente.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenCulture,
                icon: const Icon(Icons.auto_stories_outlined),
                label: const Text('Conheça mais sobre o Nheengatu'),
              ),
            ),

            const SizedBox(height: 32),

            // ── Cards de dashboard (placeholders pra Sprint 5) ─────────
            const Text(
              'Seu progresso',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const _DashboardCard(
              icon: Icons.local_fire_department,
              title: 'Sequência',
              value: '0 dias',
              hint: 'Em breve',
            ),
            const SizedBox(height: 12),
            const _DashboardCard(
              icon: Icons.star,
              title: 'XP total',
              value: '0 XP',
              hint: 'Em breve',
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
  final String hint;
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
          Text(
            hint,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
