// lib/presentation/screens/culture/cultures_list_screen.dart
// Tela de entrada da aba Cultura: lista as linguas/povos disponiveis em
// cards grandes. Tocar num card ATIVO empurra a CultureScreen com os
// chips de categoria daquela lingua via Navigator.push (mesmo padrao da
// PracticeScreen -> LessonScreen).
// Responsavel: Marcos (gerado por Claude)

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/cultures.dart';
import '../../widgets/culture_language_card.dart';
import 'culture_screen.dart';

class CulturesListScreen extends StatelessWidget {
  const CulturesListScreen({super.key});

  void _openCulture(BuildContext context, CultureLanguage culture) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CultureScreen(
          language: culture.key,
          languageLabel: culture.label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cultura'),
        // Aba do MainScaffold — sem botao voltar.
        automaticallyImplyLeading: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: kCultureLanguages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final culture = kCultureLanguages[index];
          return CultureLanguageCard(
            title: culture.label,
            subtitle: culture.subtitle,
            onTap: culture.available
                ? () => _openCulture(context, culture)
                : null,
          );
        },
      ),
    );
  }
}
