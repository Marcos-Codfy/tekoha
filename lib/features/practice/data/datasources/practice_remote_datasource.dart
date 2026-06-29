// lib/features/practice/data/datasources/practice_remote_datasource.dart
// Camada: Data (Practice).
//
// DataSource e a CAMADA MAIS BAIXA: fala direto com a fonte (Airtable
// via [AirtableClient]). Devolve DTOs.
//
// Separar do Repository ajuda quando virmos a precisar de DataSource
// local (cache em disco) E remoto — o Repository orquestra os dois.

import '../../../../core/errors/failures.dart';
import '../../../../core/network/airtable_client.dart';
import '../../../../core/result/result.dart';
import '../dtos/airtable_module_dto.dart';

/// Contrato do DataSource (permite mockar em teste sem ter rede).
abstract class PracticeRemoteDataSource {
  Future<Result<List<AirtableModuleDto>, Failure>> fetchModules(
    String language,
  );
}

class PracticeRemoteDataSourceImpl implements PracticeRemoteDataSource {
  final AirtableClient _client;

  /// Nome da tabela no Airtable. Configuravel mas com default seguro.
  final String tableName;

  const PracticeRemoteDataSourceImpl(
    this._client, {
    this.tableName = 'Modules',
  });

  @override
  Future<Result<List<AirtableModuleDto>, Failure>> fetchModules(
    String language,
  ) async {
    // Filtra so modulos ATIVOS do idioma pedido. `is_active` e `language`
    // sao campos diretos (nao linked records) — formula funciona no
    // servidor Airtable sem problema (ver comentario do legacy
    // airtable_service.dart pra contraste com Lessons/Words).
    final formula = "AND({is_active}=TRUE(), {language}='$language')";

    final result = await _client.getRecords(
      tableName,
      queryParams: {
        'filterByFormula': formula,
        'sort[0][field]': 'order',
        'sort[0][direction]': 'asc',
      },
    );

    return result.fold(
      onSuccess: (records) {
        final dtos =
            records.map((r) => AirtableModuleDto.fromAirtable(r)).toList();
        return Success(dtos);
      },
      onFailure: (failure) => FailureResult(failure),
    );
  }
}
