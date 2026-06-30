// lib/core/components/loaders/tekoha_button_loader.dart
//
// Spinner compacto branco usado DENTRO de botoes primarios durante
// operacoes assincronas. Substitui o antigo AuthButtonLoader que vivia
// so na feature Auth.

import 'package:flutter/material.dart';

class TekohaButtonLoader extends StatelessWidget {
  const TekohaButtonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2.5,
      ),
    );
  }
}
