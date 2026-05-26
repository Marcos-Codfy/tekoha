// lib/presentation/screens/profile/profile_screen.dart
// Aba "Perfil" do MainScaffold. Mostra dados do usuario logado + botao de sair.
// Quando o login esta desativado (kBypassAuth = true), o botao "Sair" vira
// um aviso explicativo (porque nao tem ninguem logado pra deslogar).
// Sprint 5 vai trocar os placeholders por XP/streak/licoes reais.
// Responsavel: Marcos (Sprint 3, gerado por Claude)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_flags.dart';
import '../../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Le o email do usuario logado. Sera null se kBypassAuth = true
    // (ninguem fez login) ou se o usuario fez logout.
    final email = context.select<AuthProvider, String?>((a) => a.currentUser?.email);

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
            // ── Avatar circular ──────────────────────────────────────
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person, size: 56, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            // ── Identificacao (email ou "Modo de teste") ────────────
            Center(
              child: Text(
                email ?? (kBypassAuth ? 'Modo de teste' : 'Visitante'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Stats placeholder (Sprint 5) ────────────────────────
            const Text(
              'Seu progresso',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const _StatRow(icon: Icons.star, label: 'XP total', value: '0 XP'),
            const Divider(height: 1, color: AppColors.border),
            const _StatRow(icon: Icons.local_fire_department, label: 'Sequência', value: '0 dias'),
            const Divider(height: 1, color: AppColors.border),
            const _StatRow(icon: Icons.menu_book, label: 'Lições concluídas', value: '0 / 3'),
            const SizedBox(height: 8),
            const Text(
              'Estatísticas reais entram na Sprint 5.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),

            // ── Botao "Sair" (ou aviso se bypass estiver on) ────────
            if (kBypassAuth)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'O login está desativado (modo de teste). '
                        'Pra reativar, mude kBypassAuth pra false em '
                        'lib/core/constants/app_flags.dart.',
                        style: TextStyle(fontSize: 13, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
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
  const _StatRow({required this.icon, required this.label, required this.value});

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
              style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
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
