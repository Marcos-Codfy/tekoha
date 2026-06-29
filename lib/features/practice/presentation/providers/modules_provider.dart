// lib/features/practice/presentation/providers/modules_provider.dart
// Camada: Presentation (Practice).
//
// Provider DEDICADO a modulos. Diferente do ContentProvider legado, NAO
// gerencia licoes, palavras ou cultura — uma feature, um provider.
// Ganho: rebuilds menos frequentes e responsabilidade isolada.
//
// O Provider so conhece o [GetModulesUseCase] e o tipo `Result`.
// Erros chegam tipados (Failure) — UI sabe se foi rede, auth, config etc.

import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/module.dart';
import '../../domain/usecases/get_modules.dart';

/// Estados possiveis. Mesma estrutura do legacy pra UI nao precisar
/// reaprender o protocolo.
enum ModulesStatus { idle, loading, loaded, error }

class ModulesProvider extends ChangeNotifier {
  final GetModulesUseCase _getModules;

  ModulesProvider(this._getModules);

  // ── Estado ──────────────────────────────────────────────────────────
  List<Module> _modules = const [];
  ModulesStatus _status = ModulesStatus.idle;
  Failure? _failure;

  // ── Getters publicos ────────────────────────────────────────────────
  /// Lista IMUTAVEL — UI nao consegue mutar acidentalmente.
  List<Module> get modules => List.unmodifiable(_modules);
  ModulesStatus get status => _status;

  /// Failure tipada — a UI pode decidir mostrar widget diferente por tipo
  /// (ex.: tela offline pra NetworkFailure vs banner pra outros).
  Failure? get failure => _failure;

  /// Mensagem ja em PT-BR (atalho pra UI que so quer texto).
  String? get errorMessage => _failure?.userMessage;

  bool get isLoading => _status == ModulesStatus.loading;
  bool get hasError => _status == ModulesStatus.error;
  bool get isLoaded => _status == ModulesStatus.loaded;

  // ── Acoes ───────────────────────────────────────────────────────────

  /// Carrega os modulos. Se ja tiver carregado, nao bate na rede de novo
  /// (cache vive no Repository). [forceRefresh] pula o cache (pull-to-refresh).
  Future<void> load({
    String language = 'nheengatu',
    bool forceRefresh = false,
  }) async {
    // Curto-circuito: se ja carregou e nao e refresh, evita re-render.
    if (!forceRefresh &&
        _status == ModulesStatus.loaded &&
        _modules.isNotEmpty) {
      return;
    }

    _status = ModulesStatus.loading;
    _failure = null;
    notifyListeners();

    final result = await _getModules(
      language: language,
      forceRefresh: forceRefresh,
    );

    result.fold(
      onSuccess: (list) {
        _modules = list;
        _status = ModulesStatus.loaded;
        _failure = null;
      },
      onFailure: (failure) {
        _modules = const [];
        _status = ModulesStatus.error;
        _failure = failure;
      },
    );

    notifyListeners();
  }
}
