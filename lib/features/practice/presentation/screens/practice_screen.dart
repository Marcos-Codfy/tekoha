// lib/features/practice/presentation/screens/practice_screen.dart
// Camada: Presentation (Practice).
//
// Aba "Aprenda" do MainScaffold. Lista os modulos vindos do Airtable
// como trilha de aprendizado. Tap num modulo aberto navega para a
// ModuleTrailScreen (trilha de etapas — ESP-005).
//
// TRAVA POR PROGRESSO REAL: o modulo N so destrava quando o modulo
// N-1 esta com todas as etapas concluidas (ProgressProvider). O
// primeiro modulo esta sempre aberto.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/loaders/tekoha_loader.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../progress/presentation/providers/user_progress_provider.dart';
import '../../domain/entities/module.dart';
import '../providers/modules_provider.dart';
import '../widgets/module_card.dart';
import 'module_trail_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  void initState() {
    super.initState();
    // Carga apos primeiro frame pra nao bater no notifyListeners durante
    // o build inicial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ModulesProvider>().load();
      // Puxa o progresso persistido do usuario logado (idempotente).
      context.read<UserProgressProvider>().ensureLoaded();
    });
  }

  void _openTrail(BuildContext context, List<Module> modules, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModuleTrailScreen(modules: modules, index: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aprenda'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<ModulesProvider, UserProgressProvider>(
        builder: (context, provider, progress, _) {
          if (provider.isLoading) {
            return const TekohaLoader();
          }

          if (provider.hasError) {
            return ErrorView(
              message:
                  provider.errorMessage ?? 'Erro ao carregar os módulos.',
              onRetry: () => provider.load(forceRefresh: true),
            );
          }

          if (provider.modules.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum módulo disponível ainda. Verifique sua conexão.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          // Ordena por `order` pra garantir a progressao 1 -> 2 -> 3
          // independente da ordem que o Airtable devolveu.
          final modules = [...provider.modules]
            ..sort((a, b) => a.order.compareTo(b.order));

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.load(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: modules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final module = modules[index];

                // Trava por progresso PERSISTIDO: destrava quando o
                // modulo anterior esta completo (modules_done no
                // Firestore — sobrevive a fechar o app).
                final isLocked = index > 0 &&
                    !progress.isModuleComplete(modules[index - 1].id);

                return ModuleCard(
                  module: module,
                  isLocked: isLocked,
                  lockedMessage: 'Termine o módulo anterior',
                  lockedIcon: Icons.lock_outline,
                  onTap: isLocked
                      ? null
                      : () => _openTrail(context, modules, index),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
