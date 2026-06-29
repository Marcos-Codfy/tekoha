// lib/features/practice/presentation/widgets/module_card.dart
// Camada: Presentation (Practice).
//
// Card visual de um modulo na PracticeScreen. Mostra nome + descricao;
// se trancado, sobrepoe overlay com icone e mensagem ("Em ajustes",
// "Em construcao", etc).
//
// Recebe entidade [Module] (dominio puro), NAO o DTO do Airtable.

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/module.dart';

class ModuleCard extends StatelessWidget {
  final Module module;
  final bool isLocked;
  final VoidCallback? onTap;

  /// Texto no overlay quando [isLocked] = true.
  final String lockedMessage;

  /// Icone no overlay quando [isLocked] = true.
  final IconData lockedIcon;

  const ModuleCard({
    super.key,
    required this.module,
    this.isLocked = false,
    this.onTap,
    this.lockedMessage = 'Em breve',
    this.lockedIcon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    const cardBackground = AppColors.primary;
    const lockedOverlay = Color(0xCCFFFFFF);

    final cardContent = Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.background,
            child: Text(
              '${module.order}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.name,
                  style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (module.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    module.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textOnPrimary,
          ),
        ],
      ),
    );

    final tappableCard = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLocked ? null : onTap,
        child: cardContent,
      ),
    );

    if (!isLocked) return tappableCard;

    return Stack(
      children: [
        tappableCard,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: lockedOverlay,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(lockedIcon, size: 32, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    lockedMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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
