// lib/data/services/airtable_service.dart
// ServiÃ§o que busca os dados do Airtable (conteÃºdo das liÃ§Ãµes)
// ResponsÃ¡vel: Marcos
// Implementa o contrato ContentRepository
// TODO Sprint 2: Implementar as chamadas Ã  API do Airtable

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/module_model.dart';
import '../models/lesson_model.dart';
import '../models/exercise_model.dart';
import '../repositories/content_repository.dart';

class AirtableService implements ContentRepository {
  // LÃª as chaves secretas do arquivo .env
  final String _apiKey = dotenv.env['AIRTABLE_API_KEY'] ?? '';
  final String _baseId = dotenv.env['AIRTABLE_BASE_ID'] ?? '';

  final String _baseUrl = 'https://api.airtable.com/v0';

  @override
  Future<List<ModuleModel>> fetchAllModules(String language) async {
    // TODO: implementar no Sprint 2
    throw UnimplementedError('fetchAllModules ainda nao implementado');
  }

  @override
  Future<List<LessonModel>> fetchLessonsByModule(String moduleId) async {
    // TODO: implementar no Sprint 2
    throw UnimplementedError('fetchLessonsByModule ainda nao implementado');
  }

  @override
  Future<List<ExerciseModel>> fetchExercisesByLesson(String lessonId) async {
    // TODO: implementar no Sprint 2
    throw UnimplementedError('fetchExercisesByLesson ainda nao implementado');
  }
}
