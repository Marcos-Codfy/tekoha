// lib/core/components/loaders/tekoha_loader.dart
//
// CircularProgressIndicator com a cor primaria da marca (urucum).
// Substitui o boilerplate `const CircularProgressIndicator(color: AppColors.primary)`
// que se repetia em todas as telas com estado de loading.

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class TekohaLoader extends StatelessWidget {
  /// Quando true, ja vem dentro de um `Center`. Padrao da maioria das
  /// telas que mostram loading.
  final bool centered;

  const TekohaLoader({super.key, this.centered = true});

  @override
  Widget build(BuildContext context) {
    const loader = CircularProgressIndicator(color: AppColors.primary);
    if (centered) return const Center(child: loader);
    return loader;
  }
}
