// lib/presentation/screens/culture/culture_screen.dart
// Aba "Cultura" do MainScaffold.
// Lista cards do Airtable filtrados pela categoria selecionada via chips
// no topo. Estado e busca de dados vivem no ContentProvider.
// Responsavel: Marcos (gerado por Claude)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/content_provider.dart';
import '../../widgets/culture_card.dart';
import '../../widgets/error_view.dart';

/// Categorias disponiveis na aba Cultura.
/// O `key` e o valor armazenado no Airtable (ingles, minusculo).
/// O `label` e o texto exibido na UI em PT-BR.
class _CultureCategory {
  final String key;
  final String label;
  const _CultureCategory(this.key, this.label);
}

const List<_CultureCategory> _categories = [
  _CultureCategory('history',     'História'),
  _CultureCategory('cosmology',   'Cosmologia'),
  _CultureCategory('habits',      'Hábitos'),
  _CultureCategory('curiosities', 'Curiosidades'),
];

class CultureScreen extends StatefulWidget {
  /// Chave do idioma no Airtable (ex.: 'nheengatu'). Default mantem
  /// compatibilidade caso a tela seja usada sem parametros.
  final String language;

  /// Texto exibido no AppBar (ex.: 'Nheengatu').
  final String languageLabel;

  const CultureScreen({
    super.key,
    this.language = 'nheengatu',
    this.languageLabel = 'Nheengatu',
  });

  @override
  State<CultureScreen> createState() => _CultureScreenState();
}

class _CultureScreenState extends State<CultureScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Dispara a primeira carga DEPOIS do primeiro frame pra evitar
    // "setState/notifyListeners called during build". Mesmo padrao da
    // PracticeScreen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadCultureContent(
            _categories[_selectedIndex].key,
            language: widget.language,
          );
    });
  }

  void _selectCategory(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.read<ContentProvider>().loadCultureContent(
          _categories[index].key,
          language: widget.language,
        );
  }

  Future<void> _refresh() {
    return context.read<ContentProvider>().loadCultureContent(
          _categories[_selectedIndex].key,
          language: widget.language,
          forceRefresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.languageLabel),
      ),
      body: Column(
        children: [
          _buildChips(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selectedIndex;
          return ChoiceChip(
            label: Text(_categories[index].label),
            selected: selected,
            onSelected: (_) => _selectCategory(index),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ContentProvider>(
      builder: (context, content, _) {
        if (content.isCultureLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (content.cultureHasError) {
          return ErrorView(
            message: content.cultureErrorMessage ??
                'Erro ao carregar o conteúdo cultural.',
            onRetry: _refresh,
          );
        }

        final items = content.cultureItems;
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum conteúdo disponível nessa categoria.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                CultureCard(content: items[index]),
          ),
        );
      },
    );
  }
}
