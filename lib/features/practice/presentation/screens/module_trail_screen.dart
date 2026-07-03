// lib/features/practice/presentation/screens/module_trail_screen.dart
// Camada: Presentation (Practice).
//
// Tela de TRILHA de um modulo (ESP-005): caminho vertical de etapas.
// Fluxo: Aprenda -> [tap modulo] -> ESTA TELA -> [tap etapa] ->
// LessonScreen (roda so as palavras da etapa) -> volta com o
// LessonOutcome -> persiste progresso (ESP-006) -> proximo no destrava
// -> conquistas recem-desbloqueadas viram celebracao (Peak-End).
//
// Gamificacao aplicada (ver 05_Registro_Decisoes_Cientificas.md):
//   - Goal-Gradient (Kivetz, 2006): label "Faltam X etapas"
//   - Peak-End (Kahneman, 1993): banner de modulo + dialog de conquista
//   - SDT-Relacionamento: frase de proposito na celebracao

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/buttons/tekoha_primary_button.dart';
import '../../../../core/components/loaders/tekoha_loader.dart';
import '../../../../core/components/texts/tekoha_purpose_text.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../di/injection.dart';
import '../../../achievements/domain/entities/achievement.dart';
import '../../../lesson/domain/entities/trail_stage.dart';
import '../../../lesson/domain/usecases/get_lessons_by_module.dart';
import '../../../lesson/domain/usecases/get_words_by_lesson.dart';
import '../../../lesson/presentation/controllers/lesson_outcome.dart';
import '../../../lesson/presentation/screens/lesson_screen.dart';
import '../../../progress/presentation/providers/user_progress_provider.dart';
import '../../domain/entities/module.dart';
import '../providers/trail_provider.dart';
import '../widgets/trail_stage_node.dart';

class ModuleTrailScreen extends StatelessWidget {
  /// Lista COMPLETA de modulos (ordenada por `order`) + indice do
  /// modulo desta trilha. Assim a celebracao sabe qual e o proximo
  /// modulo pra oferecer o botao de avancar.
  final List<Module> modules;
  final int index;

  const ModuleTrailScreen({
    super.key,
    required this.modules,
    required this.index,
  });

  Module get module => modules[index];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrailProvider(
        sl<GetLessonsByModuleUseCase>(),
        sl<GetWordsByLessonUseCase>(),
      )..load(module.id, module.order),
      child: _TrailBody(modules: modules, index: index),
    );
  }
}

class _TrailBody extends StatelessWidget {
  final List<Module> modules;
  final int index;

  const _TrailBody({required this.modules, required this.index});

  Module get module => modules[index];
  Module? get nextModule =>
      index + 1 < modules.length ? modules[index + 1] : null;

  Future<void> _openStage(BuildContext context, TrailStage stage) async {
    final outcome = await Navigator.of(context).push<LessonOutcome>(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          moduleId: module.id,
          moduleName: module.name,
          stageIndex: stage.index,
          stageTitle: stage.title,
          moduleOrder: module.order,
        ),
      ),
    );
    if (outcome == null || !context.mounted) return;

    final newlyUnlocked =
        await context.read<UserProgressProvider>().recordStageCompleted(
              moduleId: module.id,
              stageIndex: stage.index,
              outcome: outcome,
            );

    // Celebracao de conquista: momento de pico (Peak-End) logo apos o
    // retorno pra trilha — reforco imediato do comportamento.
    if (newlyUnlocked.isNotEmpty && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => _AchievementUnlockedDialog(
          achievements: newlyUnlocked,
        ),
      );
    }
  }

  /// Label Goal-Gradient do topo da trilha.
  String _headerLabel(int done, int total) {
    final remaining = total - done;
    if (remaining <= 0) return 'Trilha completa!';
    if (remaining == 1) return 'Última etapa — você está quase lá!';
    if (done == 0) return 'Cada etapa concluída libera a próxima.';
    return 'Faltam $remaining etapas pra fechar o módulo.';
  }

  @override
  Widget build(BuildContext context) {
    final trail = context.watch<TrailProvider>();
    final progress = context.watch<UserProgressProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(module.name)),
      body: () {
        if (trail.isLoading) return const TekohaLoader();
        if (trail.hasError) {
          return ErrorView(
            message: trail.errorMessage ?? 'Erro ao carregar a trilha.',
            onRetry: () =>
                context.read<TrailProvider>().load(module.id, module.order),
          );
        }

        final stages = trail.stages;

        // Registra o total de etapas — e como o provider detecta
        // "modulo completo" na hora da ultima etapa. Pos-frame pra nao
        // notificar durante o build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            final userProgress = context.read<UserProgressProvider>();
            userProgress
              ..registerTotalStages(module.id, stages.length)
              // Defensivo: garante progresso carregado mesmo se esta
              // tela for aberta antes da aba Aprenda (idempotente).
              ..ensureLoaded();
          }
        });

        final doneCount = progress.doneCount(module.id);
        final nextIndex = progress.nextStageIndex(module.id, stages.length);
        final moduleDone = nextIndex == -1 && stages.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              module.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _headerLabel(doneCount, stages.length),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < stages.length; i++)
              TrailStageNode(
                stage: stages[i],
                isLast: i == stages.length - 1,
                state: progress.isStageDone(module.id, i)
                    ? TrailNodeState.done
                    : (i == nextIndex
                        ? TrailNodeState.current
                        : TrailNodeState.locked),
                onTap: () => _openStage(context, stages[i]),
              ),
            if (moduleDone) ...[
              const SizedBox(height: 28),
              _ModuleDoneBanner(
                module: module,
                nextModule: nextModule,
                onAdvance: nextModule == null
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => ModuleTrailScreen(
                              modules: modules,
                              index: index + 1,
                            ),
                          ),
                        ),
              ),
            ],
          ],
        );
      }(),
    );
  }
}

/// Celebracao de modulo completo (Peak-End) + CTA de avanco.
class _ModuleDoneBanner extends StatelessWidget {
  final Module module;
  final Module? nextModule;
  final VoidCallback? onAdvance;

  const _ModuleDoneBanner({
    required this.module,
    required this.nextModule,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.caulim,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.correct.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 48, color: AppColors.primary),
          const SizedBox(height: 8),
          const Text(
            'Módulo concluído!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const TekohaPurposeText(
            text: 'Você deu voz a mais palavras do Nheengatu.',
          ),
          const SizedBox(height: 16),
          if (nextModule != null) ...[
            // Microcopy curto e generico (ESP-008): o nome completo do
            // modulo deixava o botao gigante; o card do proximo modulo
            // ja aparece nomeado na aba Aprenda.
            TekohaPrimaryButton(
              label: 'Próximo módulo',
              onPressed: onAdvance,
            ),
            const SizedBox(height: 8),
            Text(
              nextModule!.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ]
          else
            const Text(
              'Você completou todos os módulos disponíveis.\nKuekatu reté!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

/// Dialog de conquista desbloqueada. Mostra 1..N conquistas ganhas ao
/// fim da etapa (podem vir juntas — ex.: 1a etapa + 100 XP).
class _AchievementUnlockedDialog extends StatelessWidget {
  final List<Achievement> achievements;

  const _AchievementUnlockedDialog({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievements.length == 1
                  ? 'Conquista desbloqueada!'
                  : '${achievements.length} conquistas desbloqueadas!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            for (final achievement in achievements) ...[
              _AchievementRow(achievement: achievement),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 4),
            TekohaPrimaryButton(
              label: 'Kuekatu! (Obrigado!)',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final Achievement achievement;

  const _AchievementRow({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: achievement.iconUrl.isEmpty
              ? const Icon(Icons.emoji_events,
                  size: 56, color: AppColors.primary)
              : Image.network(
                  achievement.iconUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events,
                    size: 56,
                    color: AppColors.primary,
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                achievement.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
