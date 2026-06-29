// lib/features/culture/presentation/screens/cultures_list_screen.dart
//
// Tela de entrada da aba Cultura: lista linguas/povos disponiveis.
// Tocar num card ATIVO abre CultureScreen daquela lingua.

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/cultures.dart';
import '../widgets/culture_language_card.dart';
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
