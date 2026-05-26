// lib/presentation/providers/content_provider.dart
// Camada: Presentation (gerencia de estado).
//
// Provider e a "ponte" entre os dados e a UI:
//   - guarda o estado atual (modulos carregados, loading, erro, etc.)
//   - chama o ContentRepository quando a UI pede algo
//   - chama notifyListeners() pra avisar que mudou — a UI re-renderiza sozinha
//
// IMPORTANTE: esta classe so conhece o CONTRATO `ContentRepository`, nao a
// implementacao Airtable. Isso e Clean Architecture: a camada de cima
// (UI/Provider) nao depende da camada de baixo (servicos concretos).
//
// Cache em memoria: depois de carregar uma vez, guarda em Map ate o app
// fechar (ou clearCache ser chamado). Poupa requisicao no Airtable
// toda vez que o usuario muda de tela e volta.

import 'package:flutter/foundation.dart';

import '../../data/models/culture_content_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/module_model.dart';
import '../../data/models/word_model.dart';
import '../../data/repositories/content_repository.dart';

/// Estados possiveis da camada de conteudo (usado em [loadModules] e
/// [loadCultureContent]). A UI desenha um widget diferente pra cada estado:
///   idle    -> nada aconteceu ainda (visto so no boot)
///   loading -> CircularProgressIndicator
///   loaded  -> mostra os dados
///   error   -> mostra ErrorView com botao "Tentar de novo"
enum ContentStatus { idle, loading, loaded, error }

class ContentProvider extends ChangeNotifier {
  final ContentRepository _repository;

  /// O [repository] e injetado em main.dart. Pra trocar Airtable por
  /// outra fonte (Firebase, JSON local, mock), basta passar outra classe
  /// que implemente ContentRepository — zero mudanca aqui.
  ContentProvider(this._repository);

  // ── Estado dos modulos ─────────────────────────────────────────────
  List<ModuleModel> _modules = [];
  ContentStatus _status = ContentStatus.idle;
  String? _errorMessage;

  /// Lista IMUTAVEL pra UI nao conseguir alterar diretamente.
  /// Pra modificar, use loadModules / clearCache.
  List<ModuleModel> get modules => List.unmodifiable(_modules);
  ContentStatus get status      => _status;
  String? get errorMessage      => _errorMessage;

  /// Helpers booleanos pra UI ficar mais legivel:
  /// `if (content.isLoading) ...` em vez de comparar com o enum direto.
  bool get isLoading => _status == ContentStatus.loading;
  bool get hasError  => _status == ContentStatus.error;
  bool get isLoaded  => _status == ContentStatus.loaded;

  // ── Cache de licoes por modulo ─────────────────────────────────────
  // Chave = moduleId; valor = lista de LessonModel daquele modulo.
  final Map<String, List<LessonModel>> _lessonsByModule = {};

  /// Devolve as licoes ja carregadas de um modulo. Lista vazia se ainda
  /// nao foi carregado — chame [loadLessonsForModule] antes.
  List<LessonModel> lessonsForModule(String moduleId) =>
      List.unmodifiable(_lessonsByModule[moduleId] ?? const []);

  // ── Cache de palavras por licao ────────────────────────────────────
  // Chave = lessonId; valor = lista de WordModel daquela licao.
  final Map<String, List<WordModel>> _wordsByLesson = {};

  /// Devolve as palavras ja carregadas de uma licao.
  List<WordModel> wordsForLesson(String lessonId) =>
      List.unmodifiable(_wordsByLesson[lessonId] ?? const []);

  // ── Estado da aba Cultura ──────────────────────────────────────────
  // A Cultura tem estado separado dos modulos porque a UI dela e
  // independente (chips de categoria, com troca de conteudo na mesma tela).
  // Cache por categoria evita refetch ao alternar entre chips.
  final Map<String, List<CultureContentModel>> _cultureByCategory = {};
  List<CultureContentModel> _cultureItems = const [];
  String _cultureCurrentCategory = '';
  ContentStatus _cultureStatus = ContentStatus.idle;
  String? _cultureErrorMessage;

  /// Lista atual de cards da Cultura (referente a [cultureCurrentCategory]).
  List<CultureContentModel> get cultureItems =>
      List.unmodifiable(_cultureItems);

  /// Categoria atualmente exibida ('history', 'cosmology', etc.).
  String get cultureCurrentCategory => _cultureCurrentCategory;

  /// Estado atual da carga de cultura.
  ContentStatus get cultureStatus => _cultureStatus;
  String? get cultureErrorMessage => _cultureErrorMessage;

  bool get isCultureLoading => _cultureStatus == ContentStatus.loading;
  bool get cultureHasError  => _cultureStatus == ContentStatus.error;
  bool get isCultureLoaded  => _cultureStatus == ContentStatus.loaded;

  // ── Operacoes de carga ─────────────────────────────────────────────

  /// Carrega os modulos do Airtable.
  /// Se ja tiver carregado uma vez, NAO bate na API de novo (a menos
  /// que [forceRefresh] = true). Isso evita refetch quando o usuario
  /// muda de aba e volta pra Pratica.
  Future<void> loadModules({
    String language = 'nheengatu',
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _status == ContentStatus.loaded && _modules.isNotEmpty) {
      return;
    }

    _status = ContentStatus.loading;
    _errorMessage = null;
    notifyListeners(); // avisa a UI: comecou o loading

    try {
      _modules = await _repository.fetchAllModules(language);
      _status = ContentStatus.loaded;
    } on ContentException catch (e) {
      // Excecoes conhecidas do contrato (rede, auth, 404, etc.) ja tem
      // userMessage amigavel — passa direto pra UI.
      _modules = [];
      _status = ContentStatus.error;
      _errorMessage = e.userMessage;
    } catch (_) {
      // Erros desconhecidos: nao expor stacktrace pro usuario.
      _modules = [];
      _status = ContentStatus.error;
      _errorMessage = 'Erro inesperado ao carregar modulos.';
    }
    notifyListeners(); // avisa a UI: terminou (com ou sem erro)
  }

  /// Carrega licoes de um modulo (com cache em memoria).
  /// Devolve a lista direto pra quem chamar — nao usa o `_status` geral
  /// porque licoes vivem dentro da LessonScreen, que tem seu proprio
  /// loading state.
  Future<List<LessonModel>> loadLessonsForModule(
    String moduleId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _lessonsByModule.containsKey(moduleId)) {
      return _lessonsByModule[moduleId]!;
    }
    final lessons = await _repository.fetchLessonsByModule(moduleId);
    _lessonsByModule[moduleId] = lessons;
    notifyListeners();
    return lessons;
  }

  /// Carrega palavras de uma licao (com cache em memoria).
  /// Mesma logica do loadLessonsForModule.
  Future<List<WordModel>> loadWordsForLesson(
    String lessonId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _wordsByLesson.containsKey(lessonId)) {
      return _wordsByLesson[lessonId]!;
    }
    final words = await _repository.fetchWordsByLesson(lessonId);
    _wordsByLesson[lessonId] = words;
    notifyListeners();
    return words;
  }

  /// Carrega os cards da Cultura de uma [category].
  ///
  /// Diferente das licoes/palavras (que retornam direto), aqui mantemos
  /// estado proprio no provider porque a UI da Cultura usa
  /// Consumer<ContentProvider> e precisa reagir a loading/error.
  ///
  /// Cache por categoria: alternar entre chips ja vistos e instantaneo.
  /// Pra forcar nova busca (ex.: pull-to-refresh), passe [forceRefresh] true.
  Future<void> loadCultureContent(
    String category, {
    String language = 'nheengatu',
    bool forceRefresh = false,
  }) async {
    _cultureCurrentCategory = category;

    // Hit no cache: mostra instantaneamente, sem loading.
    if (!forceRefresh && _cultureByCategory.containsKey(category)) {
      _cultureItems = _cultureByCategory[category]!;
      _cultureStatus = ContentStatus.loaded;
      _cultureErrorMessage = null;
      notifyListeners();
      return;
    }

    _cultureStatus = ContentStatus.loading;
    _cultureErrorMessage = null;
    _cultureItems = const [];
    notifyListeners();

    try {
      final items = await _repository.fetchCultureContent(language, category);
      _cultureByCategory[category] = items;
      _cultureItems = items;
      _cultureStatus = ContentStatus.loaded;
    } on ContentException catch (e) {
      _cultureItems = const [];
      _cultureStatus = ContentStatus.error;
      _cultureErrorMessage = e.userMessage;
    } catch (_) {
      _cultureItems = const [];
      _cultureStatus = ContentStatus.error;
      _cultureErrorMessage = 'Erro inesperado ao carregar a Cultura.';
    }
    notifyListeners();
  }

  /// Limpa todo o cache (modulos, licoes, palavras, cultura).
  /// Util pra refresh manual ou pra forcar uma releitura do Airtable
  /// apos logout.
  void clearCache() {
    _modules = [];
    _lessonsByModule.clear();
    _wordsByLesson.clear();
    _cultureByCategory.clear();
    _cultureItems = const [];
    _cultureCurrentCategory = '';
    _cultureStatus = ContentStatus.idle;
    _cultureErrorMessage = null;
    _status = ContentStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
