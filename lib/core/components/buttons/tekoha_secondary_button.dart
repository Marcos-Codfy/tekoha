// lib/core/components/buttons/tekoha_secondary_button.dart
//
// Botao secundario (acao alternativa) do Tekoha. Usa o OutlinedButtonTheme
// global. Centraliza o padrao Icon + Text repetido em Home e Profile.
//
// Quando usar PRIMARY vs SECONDARY:
//   - Primary: a acao MAIS importante da tela (1 por contexto)
//   - Secondary: acoes alternativas ou destrutivas suaves (Sair, Cancelar)
//
// Mais que 1 botao primario na mesma tela = quebra Lei de Hick.

import 'package:flutter/material.dart';

class TekohaSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const TekohaSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget button = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton(
            onPressed: onPressed,
            child: Text(label),
          );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
