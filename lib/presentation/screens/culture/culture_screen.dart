// lib/presentation/screens/culture/culture_screen.dart
// Aba "Cultura" do MainScaffold. Placeholder pro V1.1 — artigos sobre
// o povo, a historia e as tradicoes ligadas ao Nheengatu.
// Responsavel: Marcos (Sprint 3, gerado por Claude)

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CultureScreen extends StatelessWidget {
  const CultureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cultura'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 80,
                color: AppColors.primary.withOpacity(0.4),
              ),
              const SizedBox(height: 24),
              const Text(
                'Em breve',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Artigos sobre o povo, a história e as tradições culturais '
                'ligadas à língua Nheengatu.\n\nDisponível na versão 1.1.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
