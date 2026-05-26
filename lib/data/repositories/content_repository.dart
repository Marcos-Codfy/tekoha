// lib/data/repositories/content_repository.dart
// Camada: Data (contratos).
//
// CONTRATO (interface) que define COMO o app busca conteudo de aprendizado.
// Ele NAO sabe de onde os dados vem — pode ser Airtable, Firebase, JSON
// local, etc. Quem decide isso e a implementacao concreta injetada no
// ContentProvider la em main.dart.
//
// Esse desacoplamento e o coracao da Clean Architecture aqui:
//   UI -> Provider -> ContentRepository (este arquivo) -> Service concreto

import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../models/word_model.dart';

/// Excecao base da camada de conteudo.
/// Toda implementacao de [ContentRepository] deve transformar suas falhas
/// internas (HTTP, parse, timeout) em uma `ContentException` com uma
/// `userMessage` em portugues que pode ser exibida na UI direto.
///
/// O `technicalDetails` e opcional e serve so pra log/debug — NUNCA mostrar
/// pro usuario final (pode conter detalhes sensiveis tipo nomes de variavel,
/// status HTTP cru, etc.).
class ContentException implements Exception {
  final String userMessage;
  final String? technicalDetails;

  ContentException(this.userMessage, [this.technicalDetails]);

  @override
  String toString() => 'ContentException: $userMessage';
}

abstract class ContentRepository {
  /// Busca todos os modulos ATIVOS de um idioma, ordenados por `order`.
  Future<List<ModuleModel>> fetchAllModules(String language);

  /// Busca todas as licoes de um modulo, ordenadas por `order`.
  Future<List<LessonModel>> fetchLessonsByModule(String moduleId);

  /// Busca todas as palavras de uma licao, ordenadas por `order`.
  Future<List<WordModel>> fetchWordsByLesson(String lessonId);
}
