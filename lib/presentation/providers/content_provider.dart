// lib/presentation/providers/content_provider.dart
// Gerencia o estado do conteudo (modulos, licoes, palavras) na UI.
// Le do ContentRepository (= AirtableService no MVP) e cacheia em memoria.
// Responsavel: Marcos (gerado por Claude na Sprint 3)
//
// A tela NAO conhece o AirtableService. Ela conversa SO com o ContentProvider.
// Isso mantem a Clean Architecture: UI -> Provider -> Repository -> Service.

import 'package:flutter/foundation.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/module_model.dart';
import '../../data/models/word_model.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/services/airtable_service.dart';

/// Estados possiveis da camada de conteudo (so usado pra `loadModules`).
/// A UI desenha um widget diferente pra cada estado.
enum ContentStatus { idle, loading, loaded, error }

class ContentProvider extends ChangeNotifier {
  final ContentRepository _repository;

  ContentProvider(this._repository);

  // ── Estado dos modulos ─────────────────────────────────────────────
  List<ModuleModel> _modules = [];
  ContentStatus _status = ContentStatus.idle;
  String? _errorMessage;

  List<ModuleModel> get modules => List.unmodifiable(_modules);
  ContentStatus get status      => _status;
  String? get errorMessage      => _errorMessage;

  bool get isLoading => _status == ContentStatus.loading;
  bool get hasError  => _status == ContentStatus.error;
  bool get isLoaded  => _status == ContentStatus.loaded;

  // ── Cache de licoes por modulo ─────────────────────────────────────
  // Chave = moduleId; valor = lista de LessonModel.
  final Map<String, List<LessonModel>> _lessonsByModule = {};

  List<LessonModel> lessonsForModule(String moduleId) =>
      List.unmodifiable(_lessonsByModule[moduleId] ?? const []);

  // ── Cache de palavras por licao ────────────────────────────────────
  // Chave = lessonId; valor = lista de WordModel.
  final Map<String, List<WordModel>> _wordsByLesson = {};

  List<WordModel> wordsForLesson(String lessonId) =>
      List.unmodifiable(_wordsByLesson[lessonId] ?? const []);

  /// Carrega os modulos do Airtable.
  /// Se ja tiver carregado uma vez, nao bate na API de novo (a menos
  /// que [forceRefresh] = true).
  Future<void> loadModules({
    String language = 'nheengatu',
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _status == ContentStatus.loaded && _modules.isNotEmpty) {
      return;
    }

    _status = ContentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.fetchAllModules(language);
      _modules = result;
      _status = ContentStatus.loaded;
    } on AirtableException catch (e) {
      _modules = [];
      _status = ContentStatus.error;
      _errorMessage = e.userMessage;
    } catch (_) {
      _modules = [];
      _status = ContentStatus.error;
      _errorMessage = 'Erro inesperado ao carregar modulos.';
    }
    notifyListeners();
  }

  /// Carrega licoes de um modulo (com cache em memoria).
  /// Devolve a lista direto pra quem chamar nao precisar usar a tela
  /// de "loading" do provider (lessons sao parte de uma tela especifica).
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

  /// Limpa todo o cache (modulos, licoes, palavras). Util pra refresh ou logout.
  void clearCache() {
    _modules = [];
    _lessonsByModule.clear();
    _wordsByLesson.clear();
    _status = ContentStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
