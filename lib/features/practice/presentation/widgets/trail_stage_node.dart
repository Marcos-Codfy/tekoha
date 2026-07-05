// lib/features/practice/presentation/widgets/trail_stage_node.dart
// Camada: Presentation (Practice).
//
// UM no da trilha de etapas (ModuleTrailScreen): circulo de status +
// linha conectora + card com titulo e contagem de exercicios.
//
// Estados visuais:
//   - done:    circulo verde com check; card tocavel (revisar etapa)
//   - current: circulo urucum com numero; card destacado, tocavel
//   - locked:  circulo cinza com cadeado; card apagado, nao tocavel

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../lesson/domain/entities/trail_stage.dart';

enum TrailNodeState { done, current, locked }

class TrailStageNode extends StatelessWidget {
  final TrailStage stage;
  final TrailNodeState state;

  /// Ultimo no da trilha nao desenha a linha conectora abaixo.
  final bool isLast;

  final VoidCallback? onTap;

  const TrailStageNode({
    super.key,
    required this.stage,
    required this.state,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = state == TrailNodeState.locked;
    final isCurrent = state == TrailNodeState.current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Coluna do circulo + conector.
          Column(
            children: [
              _StatusCircle(state: state, number: stage.index + 1),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: state == TrailNodeState.done
                          ? AppColors.correct.withValues(alpha: 0.45)
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Card da etapa.
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: isLocked ? null : onTap,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? const Color(0xFFF4F4F4)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.border,
                        width: isCurrent ? 2 : 1.2,
                      ),
                      boxShadow: isCurrent
                          ? const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stage.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isLocked
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLocked
                                    ? 'Termine a etapa anterior'
                                    : '${stage.exerciseCount} exercícios',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primary,
                          ),
                        if (state == TrailNodeState.done)
                          const Icon(
                            Icons.replay_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  final TrailNodeState state;
  final int number;

  const _StatusCircle({required this.state, required this.number});

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Widget child;

    switch (state) {
      case TrailNodeState.done:
        background = AppColors.correct;
        child = const Icon(Icons.check_rounded,
            color: AppColors.textOnPrimary, size: 24);
      case TrailNodeState.current:
        background = AppColors.primary;
        child = Text(
          '$number',
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        );
      case TrailNodeState.locked:
        background = const Color(0xFFDBDBDB);
        child = const Icon(Icons.lock_outline_rounded,
            color: Color(0xFF8A8A8A), size: 20);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      alignment: Alignment.center,
      child: child,
    );
  }
}
