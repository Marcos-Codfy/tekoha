// lib/features/practice/presentation/screens/practice_screen.dart
// Camada: Presentation (Practice).
//
// Aba "Aprenda" do MainScaffold. Lista os modulos vindos do Airtable
// como trilha de aprendizado. Tap num modulo aberto navega para a
// LessonScreen.
//
// Diferenca pro legado:
//   - Consome ModulesProvider (so modulos), nao o ContentProvider
//     monolitico.
//   - Acesso a Failure tipada via `provider.failure` permite UI
//     diferenciar tipo de erro (rede vs config vs auth).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/loaders/tekoha_loader.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../features/lesson/presentation/screens/lesson_screen.dart';
import '../providers/modules_provider.dart';
import '../widgets/module_card.dart';

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
    });
  }

  void _openModule(BuildContext context, String moduleId, String moduleName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          moduleId: moduleId,
          moduleName: moduleName,
        ),
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
      body: Consumer<ModulesProvider>(
        builder: (context, provider, _) {
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

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.load(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.modules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final module = provider.modules[index];

                // Todos os modulos abertos: as 30 palavras tem audio
                // (01/jul) e os 3 modulos rodam no modo misto (audio +
                // quiz). Sprint futura: travar por progresso real do
                // usuario (ModuleCard ja suporta isLocked).
                return ModuleCard(
                  module: module,
                  onTap: () => _openModule(context, module.id, module.name),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
