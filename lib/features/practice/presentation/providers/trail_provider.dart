// lib/features/practice/presentation/providers/trail_provider.dart
// Camada: Presentation (Practice).
//
// Provider LOCAL da ModuleTrailScreen (criado por tela, auto-disposed
// no pop). Carrega licao + palavras do modulo (mesmos UseCases da
// Lesson — o cache do Repository evita rede duplicada) e monta as
// etapas via TrailBuilder (ESP-005).

import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../../lesson/domain/builders/trail_builder.dart';
import '../../../lesson/domain/entities/trail_stage.dart';
import '../../../lesson/domain/usecases/get_lessons_by_module.dart';
import '../../../lesson/domain/usecases/get_words_by_lesson.dart';

enum TrailStatus { idle, loading, loaded, error }

class TrailProvider extends ChangeNotifier {
  final GetLessonsByModuleUseCase _getLessons;
  final GetWordsByLessonUseCase _getWords;

  TrailProvider(this._getLessons, this._getWords);

  TrailStatus _status = TrailStatus.idle;
  List<TrailStage> _stages = const [];
  String? _errorMessage;

  TrailStatus get status => _status;
  List<TrailStage> get stages => List.unmodifiable(_stages);
  String? get errorMessage => _errorMessage;

  bool get isLoading =>
      _status == TrailStatus.loading || _status == TrailStatus.idle;
  bool get hasError => _status == TrailStatus.error;
  bool get isLoaded => _status == TrailStatus.loaded;

  Future<void> load(String moduleId, int moduleOrder) async {
    _status = TrailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final lessonsResult = await _getLessons(moduleId);
    final lessons = lessonsResult.fold(
      onSuccess: (l) => l,
      onFailure: (Failure f) {
        _fail(f.userMessage);
        return null;
      },
    );
    if (lessons == null) return;
    if (lessons.isEmpty) {
      _fail('Nenhuma lição encontrada para este módulo.');
      return;
    }

    final wordsResult = await _getWords(lessons.first.id);
    final words = wordsResult.fold(
      onSuccess: (w) => w,
      onFailure: (Failure f) {
        _fail(f.userMessage);
        return null;
      },
    );
    if (words == null) return;
    if (words.isEmpty) {
      _fail('Esta lição ainda não tem palavras cadastradas.');
      return;
    }

    _stages = TrailBuilder.build(words, moduleOrder: moduleOrder);
    _status = TrailStatus.loaded;
    notifyListeners();
  }

  void _fail(String message) {
    _status = TrailStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
