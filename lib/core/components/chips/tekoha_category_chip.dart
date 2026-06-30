// lib/core/components/chips/tekoha_category_chip.dart
//
// ChoiceChip estilizado do Tekoha. Tres estados visuais:
//   - SELECIONADO   : fundo na cor `selectedColor`, label branco
//   - NORMAL        : fundo branco, label preto suave, borda neutra
//   - DESABILITADO  : fundo cinza claro, label cinza, sem ripple
//
// Pra Cultura usamos `selectedColor: AppColors.floresta` (verde-mata),
// diferenciando visualmente da Pratica (urucum). Mas o componente aceita
// qualquer cor — permite reuso futuro em outras categorias.

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class TekohaCategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  /// Cor de fundo quando selecionado. Default: floresta (Cultura).
  final Color selectedColor;

  const TekohaCategoryChip({
    super.key,
    required this.label,
    required this.selected,
    this.disabled = false,
    this.onTap,
    this.selectedColor = AppColors.floresta,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color labelColor;
    final Color borderColor;

    if (disabled) {
      background = const Color(0xFFF5F5F5);
      labelColor = AppColors.textSecondary;
      borderColor = AppColors.border;
    } else if (selected) {
      background = selectedColor;
      labelColor = AppColors.textOnPrimary;
      borderColor = selectedColor;
    } else {
      background = AppColors.surface;
      labelColor = AppColors.textPrimary;
      borderColor = AppColors.border;
    }

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: disabled || onTap == null ? null : (_) => onTap!(),
      selectedColor: selectedColor,
      backgroundColor: background,
      disabledColor: background,
      labelStyle: TextStyle(
        color: labelColor,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
    );
  }
}
