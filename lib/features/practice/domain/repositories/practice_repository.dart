// lib/features/practice/domain/repositories/practice_repository.dart
// Camada: Domain (Practice).
//
// CONTRATO do repositorio da feature Practice. O dominio define O QUE
// precisa (assinaturas), a camada `data/` decide COMO (Airtable, mock,
// cache, etc.).
//
// Retorno tipado como Result<X, Failure> — quem chama (UseCase) e
// obrigado a tratar sucesso e falha explicitamente.

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/module.dart';

abstract class PracticeRepository {
  /// Busca todos os modulos ATIVOS de [language], ordenados por `order`.
  /// Quando [forceRefresh] = true, ignora cache e busca de novo na fonte.
  Future<Result<List<Module>, Failure>> getModules({
    required String language,
    bool forceRefresh = false,
  });
}
