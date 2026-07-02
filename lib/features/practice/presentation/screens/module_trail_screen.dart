// lib/features/practice/presentation/screens/module_trail_screen.dart
// Camada: Presentation (Practice).
//
// Tela de TRILHA de um modulo (ESP-005): caminho vertical de etapas.
// Fluxo: Aprenda -> [tap modulo] -> ESTA TELA -> [tap etapa] ->
// LessonScreen (roda so as palavras da etapa) -> volta com result=true
// -> marca progresso -> proximo no destrava.
//
// Gamificacao aplicada (ver 05_Registro_Decisoes_Cientificas.md):
//   - Goal-Gradient (Kivetz, 2006): label "Faltam X etapas"
//   - Peak-End (Kahneman, 1993): banner de celebracao ao fechar modulo
//   - SDT-Relacionamento: frase de proposito na celebracao

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/buttons/tekoha_primary_button.dart';
import '../../../../core/components/loaders/tekoha_loader.dart';
import '../../../../core/components/texts/tekoha_purpose_text.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../di/injection.dart';
import '../../../lesson/domain/entities/trail_stage.dart';
import '../../../lesson/domain/usecases/get_lessons_by_module.dart';
import '../../../lesson/domain/usecases/get_words_by_lesson.dart';
import '../../../lesson/presentation/screens/lesson_screen.dart';
import '../../domain/entities/module.dart';
import '../providers/progress_provider.dart';
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
  Module? get nextModule =>
      index + 1 < modules.length ? modules[index + 1] : null;

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
    final completed = await Navigator.of(context).push<bool>(
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
    if (completed == true && context.mounted) {
      await context
          .read<ProgressProvider>()
          .markStageDone(module.id, stage.index);
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
    final progress = context.watch<ProgressProvider>();

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

        // Registra o total de etapas no ProgressProvider — e assim que
        // a PracticeScreen sabe quando "modulo anterior completo" e
        // destrava o proximo modulo. Pos-frame pra nao notificar
        // durante o build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context
                .read<ProgressProvider>()
                .registerTotalStages(module.id, stages.length);
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
          if (nextModule != null)
            TekohaPrimaryButton(
              label: 'Avançar: ${nextModule!.name}',
              icon: Icons.arrow_forward,
              onPressed: onAdvance,
            )
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
