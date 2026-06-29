// lib/features/practice/data/repositories/practice_repository_impl.dart
// Camada: Data (Practice).
//
// Implementacao concreta de [PracticeRepository]. Adiciona:
//   - cache em memoria (mesmo comportamento do ContentProvider legado)
//   - traducao DTO -> Entity via Mapper
//
// O cache vive aqui (e nao no Provider) porque cache e detalhe de
// implementacao do acesso a dados, nao logica de UI. Provider so pede
// "me da os modulos" e o repo decide se serve do cache ou da rede.

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/module.dart';
import '../../domain/repositories/practice_repository.dart';
import '../datasources/practice_remote_datasource.dart';
import '../mappers/module_mapper.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  final PracticeRemoteDataSource _remote;

  /// Cache simples: chave = language, valor = lista de Modules.
  /// Visivel pra teste poder limpar entre cenarios.
  final Map<String, List<Module>> _cache = {};

  PracticeRepositoryImpl(this._remote);

  @override
  Future<Result<List<Module>, Failure>> getModules({
    required String language,
    bool forceRefresh = false,
  }) async {
    // Hit no cache: devolve sem bater na rede.
    if (!forceRefresh && _cache.containsKey(language)) {
      return Success(_cache[language]!);
    }

    final dtoResult = await _remote.fetchModules(language);

    return dtoResult.fold(
      onSuccess: (dtos) {
        final modules = ModuleMapper.toEntityList(dtos);
        _cache[language] = modules;
        return Success(modules);
      },
      onFailure: (failure) => FailureResult(failure),
    );
  }
}
