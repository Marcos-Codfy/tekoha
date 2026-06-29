// lib/features/culture/presentation/screens/culture_screen.dart
//
// Tela com chips de categoria + lista de cards. Consome o CultureProvider.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../presentation/widgets/error_view.dart';
import '../providers/culture_provider.dart';
import '../widgets/culture_card.dart';

/// Categorias disponiveis na aba Cultura.
class _CultureCategory {
  /// `key` = valor armazenado no Airtable (ingles, minusculo).
  final String key;

  /// `label` = texto exibido na UI (PT-BR).
  final String label;

  /// `available` = false renderiza chip cinza, sem ripple e sem callback.
  final bool available;

  const _CultureCategory(this.key, this.label, {this.available = true});
}

/// Ordem da demo: Curiosidades primeiro (mais leve), depois Historia e
/// Habitos. Cosmologia fica por ultimo e DESABILITADA enquanto o texto
/// nao passa pela validacao juridica.
const List<_CultureCategory> _categories = [
  _CultureCategory('curiosities', 'Curiosidades'),
  _CultureCategory('history', 'Historia'),
  _CultureCategory('habits', 'Habitos'),
  _CultureCategory('cosmology', 'Cosmologia', available: false),
];

class CultureScreen extends StatefulWidget {
  /// Chave do idioma no Airtable (ex.: 'nheengatu').
  final String language;

  /// Texto exibido no AppBar.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CultureProvider>().load(
            category: _categories[_selectedIndex].key,
            language: widget.language,
          );
    });
  }

  void _selectCategory(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.read<CultureProvider>().load(
          category: _categories[index].key,
          language: widget.language,
        );
  }

  Future<void> _refresh() {
    return context.read<CultureProvider>().load(
          category: _categories[_selectedIndex].key,
          language: widget.language,
          forceRefresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.languageLabel)),
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
          final category = _categories[index];
          final selected = index == _selectedIndex;
          final disabled = !category.available;

          final Color background;
          final Color labelColor;
          final Color borderColor;
          if (disabled) {
            background = const Color(0xFFF5F5F5);
            labelColor = AppColors.textSecondary;
            borderColor = AppColors.border;
          } else if (selected) {
            background = AppColors.primary;
            labelColor = AppColors.textOnPrimary;
            borderColor = AppColors.primary;
          } else {
            background = AppColors.surface;
            labelColor = AppColors.textPrimary;
            borderColor = AppColors.border;
          }

          return ChoiceChip(
            label: Text(category.label),
            selected: selected,
            onSelected: disabled ? null : (_) => _selectCategory(index),
            selectedColor: AppColors.primary,
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
        },
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<CultureProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (provider.hasError) {
          return ErrorView(
            message: provider.errorMessage ??
                'Erro ao carregar o conteudo cultural.',
            onRetry: _refresh,
          );
        }

        final items = provider.items;
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhum conteudo disponivel nessa categoria.',
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
