// lib/features/profile/presentation/screens/profile_screen.dart
//
// Aba "Perfil" do MainScaffold. Quando login esta desativado
// (kBypassAuth = true), o botao "Sair" vira aviso explicativo.
//
// Sprint futura: trocar placeholders por XP/streak/licoes reais
// vindos do Firestore.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/buttons/tekoha_secondary_button.dart';
import '../../../../core/components/texts/tekoha_purpose_text.dart';
import '../../../../core/components/texts/tekoha_section_label.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_flags.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../progress/presentation/providers/user_progress_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    // Zera o estado LOCAL de progresso antes de sair — o Firestore
    // mantem o do usuario; o proximo login carrega o dele.
    context.read<UserProgressProvider>().clearOnLogout();
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Le o email do usuario logado. `null` se kBypassAuth = true ou
    // se ninguem fez login ainda.
    final email = context.select<AuthProvider, String?>(
      (a) => a.currentUser?.email,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                email ?? (kBypassAuth ? 'Modo de demonstração' : 'Visitante'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const TekohaSectionLabel('Seu progresso'),
            const SizedBox(height: 8),
            const _StatRow(icon: Icons.star, label: 'XP total', value: '0 XP'),
            const Divider(height: 1, color: AppColors.border),
            const _StatRow(
              icon: Icons.local_fire_department,
              label: 'Sequência',
              value: '0 dias',
            ),
            const Divider(height: 1, color: AppColors.border),
            const _StatRow(
              icon: Icons.menu_book,
              label: 'Lições concluídas',
              value: '0 / 3',
            ),
            const SizedBox(height: 8),
            const Text(
              'Seu histórico será salvo em breve.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: TekohaPurposeText(
                text:
                    'Cada palavra praticada apoia a revitalização do Nheengatu.',
              ),
            ),
            const SizedBox(height: 40),
            if (kBypassAuth)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Login desativado neste modo de demonstração. '
                        'A versão final terá conta com progresso salvo.',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              )
            else
              TekohaSecondaryButton(
                label: 'Sair da conta',
                icon: Icons.logout,
                onPressed: () => _logout(context),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
