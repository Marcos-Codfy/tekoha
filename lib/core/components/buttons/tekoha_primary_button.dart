// lib/core/components/buttons/tekoha_primary_button.dart
//
// Botao primario (CTA principal) do Tekoha. Usa o ElevatedButtonTheme
// global definido em [AppTheme], mas centraliza o padrao Icon + Text que
// se repetia em varias telas (Home, DoneView, ErrorView, Auth).
//
// USO:
//   TekohaPrimaryButton(
//     label: 'Praticar Nheengatu',
//     icon: Icons.play_arrow,
//     onPressed: () { ... },
//   )
//
// Variante sem icone:
//   TekohaPrimaryButton(label: 'Entrar', onPressed: ...)

import 'package:flutter/material.dart';

import '../loaders/tekoha_button_loader.dart';

class TekohaPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Se true, troca o conteudo por um spinner branco compacto.
  /// Use durante operacoes assincronas (login, submit, etc).
  final bool isLoading;

  /// Padrao: ocupa toda a largura disponivel. Botoes em rodapes de
  /// dialogo podem querer false.
  final bool fullWidth;

  const TekohaPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget button;

    if (icon != null) {
      button = ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const TekohaButtonLoader()
            : Icon(icon),
        label: Text(label),
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading ? const TekohaButtonLoader() : Text(label),
      );
    }

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
