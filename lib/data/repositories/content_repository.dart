// lib/data/repositories/content_repository.dart
// CONTRATO (interface) que define COMO o app busca conteÃºdo
// ResponsÃ¡vel: Marcos
//
// IMPORTANTE: As telas (Screens) sÃ³ conhecem ESTE arquivo.
// Elas nÃ£o sabem se os dados vÃªm do Airtable, Firebase ou outro lugar.
// Isso permite trocar o banco de dados no futuro sem mexer nas telas.

import '../models/module_model.dart';
import '../models/lesson_model.dart';
import '../models/exercise_model.dart';

abstract class ContentRepository {
  Future<List<ModuleModel>> fetchAllModules(String language);
  Future<List<LessonModel>> fetchLessonsByModule(String moduleId);
  Future<List<ExerciseModel>> fetchExercisesByLesson(String lessonId);
}
