// test/features/practice/presentation/providers/progress_provider_test.dart
//
// Estrategia: ciclo completo com a impl em memoria real (nao ha IO):
// estado inicial vazio, marcacao idempotente, isolamento entre modulos,
// nextStageIndex e isModuleDone com boundaries.

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/practice/data/repositories/in_memory_progress_repository.dart';
import 'package:tekoha/features/practice/presentation/providers/progress_provider.dart';

void main() {
  late ProgressProvider provider;

  setUp(() {
    provider = ProgressProvider(InMemoryProgressRepository());
  });

  group('estado inicial', () {
    test('nenhuma etapa concluida, modulo nao concluido', () {
      expect(provider.isStageDone('m1', 0), isFalse);
      expect(provider.doneCount('m1'), 0);
      expect(provider.isModuleDone('m1', 4), isFalse);
      expect(provider.nextStageIndex('m1', 4), 0);
    });

    test('isModuleDone com totalStages 0 e false (boundary)', () {
      expect(provider.isModuleDone('m1', 0), isFalse);
    });
  });

  group('markStageDone', () {
    test('marca etapa e notifica listeners', () async {
      var notified = 0;
      provider.addListener(() => notified++);

      await provider.markStageDone('m1', 0);

      expect(provider.isStageDone('m1', 0), isTrue);
      expect(provider.doneCount('m1'), 1);
      expect(notified, greaterThan(0));
    });

    test('e idempotente — marcar duas vezes conta uma', () async {
      await provider.markStageDone('m1', 2);
      await provider.markStageDone('m1', 2);

      expect(provider.doneCount('m1'), 1);
    });

    test('progresso de um modulo nao vaza pro outro', () async {
      await provider.markStageDone('m1', 0);

      expect(provider.isStageDone('m2', 0), isFalse);
      expect(provider.doneCount('m2'), 0);
    });
  });

  group('nextStageIndex', () {
    test('aponta a primeira etapa nao concluida (fora de ordem)', () async {
      await provider.markStageDone('m1', 0);
      await provider.markStageDone('m1', 2);

      expect(provider.nextStageIndex('m1', 4), 1);
    });

    test('devolve -1 quando todas as etapas foram concluidas', () async {
      for (var i = 0; i < 4; i++) {
        await provider.markStageDone('m1', i);
      }

      expect(provider.nextStageIndex('m1', 4), -1);
      expect(provider.isModuleDone('m1', 4), isTrue);
    });
  });

  group('loadModule', () {
    test('recarrega cache do repositorio e notifica', () async {
      final repo = InMemoryProgressRepository();
      await repo.markStageDone('m1', 1);
      final fresh = ProgressProvider(repo);

      // Antes do load o cache local esta vazio.
      expect(fresh.isStageDone('m1', 1), isFalse);

      await fresh.loadModule('m1');

      expect(fresh.isStageDone('m1', 1), isTrue);
    });
  });
}
