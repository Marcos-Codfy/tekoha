// lib/features/lesson/data/datasources/lesson_remote_datasource.dart
// Camada: Data (Lesson).
//
// DataSource remoto da feature Lesson. Pega licoes e palavras do
// Airtable e devolve DTOs.
//
// IMPORTANTE — Linked Records do Airtable:
//   `filterByFormula` no servidor NAO funciona pra campos linkados (a
//   formula recebe o NOME do registro linkado, nao o ID). Por isso,
//   buscamos TODOS os records e filtramos no Dart pelo ID.
//   Comentario detalhado no metodo `fetchLessonsByModule`.

import '../../../../core/errors/failures.dart';
import '../../../../core/network/airtable_client.dart';
import '../../../../core/result/result.dart';
import '../dtos/airtable_lesson_dto.dart';
import '../dtos/airtable_word_dto.dart';

abstract class LessonRemoteDataSource {
  Future<Result<List<AirtableLessonDto>, Failure>> fetchLessonsByModule(
    String moduleId,
  );

  Future<Result<List<AirtableWordDto>, Failure>> fetchWordsByLesson(
    String lessonId,
  );
}

class LessonRemoteDataSourceImpl implements LessonRemoteDataSource {
  final AirtableClient _client;
  final String lessonsTable;
  final String wordsTable;

  const LessonRemoteDataSourceImpl(
    this._client, {
    this.lessonsTable = 'Lessons',
    this.wordsTable = 'Words',
  });

  @override
  Future<Result<List<AirtableLessonDto>, Failure>> fetchLessonsByModule(
    String moduleId,
  ) async {
    // Buscamos TODAS as licoes e filtramos por moduleId no codigo.
    //
    // Por que? `filterByFormula` em campo Linked Record devolve o NOME
    // do registro linkado (primary field), nao o ID. FIND('recXXX',
    // ARRAYJOIN({module})) sempre retorna 0 — filtra tudo.
    // A REST API por outro lado entrega o campo `fields.module` como
    // ARRAY DE IDS, entao a comparacao funciona em Dart.
    // Com 3 licoes no MVP, o custo extra de rede e desprezivel.
    final result = await _client.getRecords(
      lessonsTable,
      queryParams: {
        'sort[0][field]': 'order',
        'sort[0][direction]': 'asc',
      },
    );

    return result.fold(
      onSuccess: (records) {
        final dtos = records
            .map(AirtableLessonDto.fromAirtable)
            .where((dto) => dto.moduleId == moduleId)
            .toList();
        return Success(dtos);
      },
      onFailure: (f) => FailureResult(f),
    );
  }

  @override
  Future<Result<List<AirtableWordDto>, Failure>> fetchWordsByLesson(
    String lessonId,
  ) async {
    // Mesma logica do fetchLessonsByModule: traz tudo e filtra em Dart.
    final result = await _client.getRecords(
      wordsTable,
      queryParams: {
        'sort[0][field]': 'order',
        'sort[0][direction]': 'asc',
      },
    );

    return result.fold(
      onSuccess: (records) {
        final dtos = records
            .map(AirtableWordDto.fromAirtable)
            .where((dto) => dto.lessonId == lessonId)
            .toList();
        return Success(dtos);
      },
      onFailure: (f) => FailureResult(f),
    );
  }
}
