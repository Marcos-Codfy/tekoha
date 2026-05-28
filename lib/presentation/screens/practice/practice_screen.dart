// lib/presentation/screens/practice/practice_screen.dart
// Aba "Pratica" do MainScaffold. Mostra os modulos do Nheengatu como
// trilha de aprendizado. Tap num modulo aberto navega pra LessonScreen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/content_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/module_card.dart';
import '../lesson/lesson_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  void initState() {
    super.initState();
    // Dispara o load DEPOIS do primeiro frame pra evitar
    // "setState/notifyListeners called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().loadModules();
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
      body: Consumer<ContentProvider>(
        builder: (context, content, _) {
          if (content.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (content.hasError) {
            return ErrorView(
              message: content.errorMessage ?? 'Erro ao carregar módulos.',
              onRetry: () => content.loadModules(forceRefresh: true),
            );
          }

          if (content.modules.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum conteúdo disponível.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => content.loadModules(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: content.modules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final module = content.modules[index];
                // Regra de demo: so o Modulo 1 (Saudacoes, com audio) abre.
                // Modulo 2 "Em ajustes" e Modulo 3 "Em construcao" — copia
                // mais humana que "Complete o Modulo X". Sprint futura troca
                // essa regra hardcoded por progresso real do usuario.
                final bool isLocked;
                final String lockedMessage;
                final IconData lockedIcon;
                if (module.order == 1) {
                  isLocked = false;
                  lockedMessage = '';
                  lockedIcon = Icons.lock_outline;
                } else if (module.order == 2) {
                  isLocked = true;
                  lockedMessage = 'Em ajustes';
                  lockedIcon = Icons.tune;
                } else {
                  isLocked = true;
                  lockedMessage = 'Em construção';
                  lockedIcon = Icons.construction;
                }

                return ModuleCard(
                  module: module,
                  isLocked: isLocked,
                  lockedMessage: lockedMessage,
                  lockedIcon: lockedIcon,
                  onTap: isLocked
                      ? null
                      : () => _openModule(context, module.id, module.name),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
