// lib/features/profile/presentation/screens/profile_screen.dart
//
// Aba "Perfil" do MainScaffold. Com o login ativo (ESP-007) mostra a
// identidade do usuario (nome + e-mail), estatisticas REAIS persistidas
// (XP, streak, etapas, palavras dominadas) e a galeria de conquistas.
//
// Decisoes de UX (ver 05_Registro_Decisoes_Cientificas.md):
//   - Bloco de identidade no topo: avatar > nome > e-mail (hierarquia
//     visual padrao de perfil; reconhecimento — Nielsen H6).
//   - Conquistas travadas ficam VISIVEIS em silhueta com dica de meta
//     (Zeigarnik, 1927 + goal setting de Antin & Churchill, 2011).
//   - Tom sem punicao: nenhuma estatistica exibe "voce falhou".

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/buttons/tekoha_secondary_button.dart';
import '../../../../core/components/texts/tekoha_purpose_text.dart';
import '../../../../core/components/texts/tekoha_section_label.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_flags.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../achievements/domain/entities/achievement.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../progress/presentation/providers/user_progress_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProgressProvider>().ensureLoaded();
      }
    });
  }

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
    final user = context.watch<AuthProvider>().currentUser;
    final progress = context.watch<UserProgressProvider>();

    final displayName = user?.displayName?.trim();
    final hasName = displayName != null && displayName.isNotEmpty;

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
            // ── Identidade ─────────────────────────────────────────────
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: hasName
                    ? Text(
                        displayName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 56,
                        color: AppColors.primary,
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                hasName
                    ? displayName
                    : (kBypassAuth ? 'Modo de demonstração' : 'Visitante'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (user?.email != null) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  user!.email!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ── Estatisticas reais (persistidas) ───────────────────────
            const TekohaSectionLabel('Seu progresso'),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.star,
              label: 'XP total',
              value: '${progress.xp} XP',
            ),
            const Divider(height: 1, color: AppColors.border),
            _StatRow(
              icon: Icons.local_fire_department,
              label: 'Sequência',
              value: progress.streakDays == 1
                  ? '1 dia'
                  : '${progress.streakDays} dias',
            ),
            const Divider(height: 1, color: AppColors.border),
            _StatRow(
              icon: Icons.route,
              label: 'Etapas concluídas',
              value: '${progress.progress.totalStagesDone}',
            ),
            const Divider(height: 1, color: AppColors.border),
            _StatRow(
              icon: Icons.spa,
              label: 'Palavras aprendidas',
              value: '${progress.progress.masteredWordIds.length}',
            ),
            const SizedBox(height: 32),

            // ── Galeria de conquistas ──────────────────────────────────
            if (progress.achievements.isNotEmpty) ...[
              TekohaSectionLabel(
                'Conquistas '
                '(${progress.unlockedCount}/${progress.achievements.length})',
              ),
              const SizedBox(height: 12),
              _AchievementsGallery(
                achievements: progress.achievements,
                isUnlocked: progress.isAchievementUnlocked,
              ),
              const SizedBox(height: 24),
            ],

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

/// Grade de conquistas: desbloqueadas em cores, travadas em silhueta
/// (Zeigarnik — a colecao incompleta visivel convida a completar).
class _AchievementsGallery extends StatelessWidget {
  final List<Achievement> achievements;
  final bool Function(String code) isUnlocked;

  const _AchievementsGallery({
    required this.achievements,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: achievements.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final unlocked = isUnlocked(achievement.code);
        return _AchievementTile(
          achievement: achievement,
          unlocked: unlocked,
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => _AchievementDetailDialog(
              achievement: achievement,
              unlocked: unlocked,
            ),
          ),
        );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final VoidCallback onTap;

  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.onTap,
  });

  /// Matriz de dessaturacao (grayscale) pra silhueta de conquista
  /// travada — evita gerar um segundo asset por badge.
  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final icon = achievement.iconUrl.isEmpty
        ? Icon(
            Icons.emoji_events,
            size: 48,
            color: unlocked ? AppColors.primary : AppColors.border,
          )
        : Image.network(
            achievement.iconUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.emoji_events,
              size: 48,
              color: unlocked ? AppColors.primary : AppColors.border,
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: unlocked ? AppColors.caulim : const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unlocked
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    unlocked
                        ? icon
                        : Opacity(
                            opacity: 0.45,
                            child: ColorFiltered(
                              colorFilter: _grayscale,
                              child: icon,
                            ),
                          ),
                    if (!unlocked)
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.lock,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                achievement.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: unlocked
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detalhe da conquista: desbloqueada mostra a celebracao; travada
/// mostra a META (locked_hint) — goal setting explicito.
class _AchievementDetailDialog extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementDetailDialog({
    required this.achievement,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.background,
      title: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events : Icons.lock_outline,
            color: unlocked ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              achievement.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        unlocked ? achievement.description : achievement.lockedHint,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(unlocked ? 'Kuekatu!' : 'Vou conseguir'),
        ),
      ],
    );
  }
}
