// lib/data/repositories/content_repository.dart
// CONTRATO (interface) que define COMO o app busca conteudo.
// Responsavel: Marcos
//
// IMPORTANTE: As telas (Screens) so conhecem ESTE arquivo.
// Elas nao sabem se os dados vem do Airtable, Firebase ou outro lugar.
// Isso permite trocar o banco de dados no futuro sem mexer nas telas.
//
// Sprint 3: trocamos `fetchExercisesByLesson` por `fetchWordsByLesson`.
// Motivo: o que vem do Airtable e PALAVRA. Exercicio (Quiz/Translate) e
// DERIVADO da palavra dentro do Provider, nao buscado no banco.
// Isso mantem a regra de negocio (1 palavra = 1 Quiz + 1 Translate) na camada
// de apresentacao, longe da camada de dados.

import '../models/module_model.dart';
import '../models/lesson_model.dart';
import '../models/word_model.dart';

abstract class ContentRepository {
  /// Busca todos os modulos ATIVOS de um idioma, ordenados pelo campo `order`.
  Future<List<ModuleModel>> fetchAllModules(String language);

  /// Busca todas as licoes de um modulo, ordenadas pelo campo `order`.
  Future<List<LessonModel>> fetchLessonsByModule(String moduleId);

  /// Busca todas as palavras de uma licao, ordenadas pelo campo `order`.
  Future<List<WordModel>> fetchWordsByLesson(String lessonId);
}
