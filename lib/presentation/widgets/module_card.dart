// lib/presentation/widgets/module_card.dart
// Card visual de um modulo na HomeScreen.
// Mostra nome + descricao; se trancado, sobrepoe icone de cadeado e mensagem.
// Responsavel: Marcos (Sprint 3, gerado por Claude)

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/module_model.dart';

class ModuleCard extends StatelessWidget {
  final ModuleModel module;
  final bool isLocked;
  final VoidCallback? onTap;

  const ModuleCard({
    super.key,
    required this.module,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Cor de fundo do card: Urucum cheio (marca do app).
    // Overlay quando trancado: branco semitransparente pra "apagar" o card.
    const cardBackground = AppColors.primary;
    const lockedOverlay  = Color(0xCCFFFFFF);

    // Conteudo principal do card (mesmo layout pra trancado e aberto).
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
          // Numero do modulo num circulo branco.
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
          // Coluna com nome + descricao do modulo.
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
          // Seta de "entrar no modulo" na direita.
          const Icon(
            Icons.chevron_right,
            color: AppColors.textOnPrimary,
          ),
        ],
      ),
    );

    // InkWell pra dar feedback visual de toque (ripple).
    // Material + InkWell ja resolvem o ripple respeitando o borderRadius.
    final tappableCard = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLocked ? null : onTap,
        child: cardContent,
      ),
    );

    if (!isLocked) return tappableCard;

    // Versao trancada: empilha overlay branco + cadeado + mensagem por cima.
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
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 32, color: AppColors.primary),
                  SizedBox(height: 4),
                  Text(
                    'Complete o Modulo 2 para desbloquear',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
