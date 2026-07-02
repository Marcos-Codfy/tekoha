// test/features/progress/data/repositories/firestore_stage_progress_repository_test.dart
//
// Estrategia: o adapter que liga o contrato da trilha (ProgressRepository
// da feature Practice) ao documento user_progress do Firestore.
// Casos: sem login (uid vazio), leitura por modulo, merge de escrita e
// degradacao silenciosa em falha de rede.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoha/features/progress/data/datasources/firestore_progress_datasource.dart';
import 'package:tekoha/features/progress/data/repositories/firestore_stage_progress_repository.dart';

class _MockDataSource extends Mock implements FirestoreProgressDataSource {}

void main() {
  late _MockDataSource dataSource;

  setUp(() {
    dataSource = _MockDataSource();
  });

  FirestoreStageProgressRepository repo({String uid = 'u1'}) =>
      FirestoreStageProgressRepository(dataSource, () => uid);

  group('sem usuario logado (uid vazio)', () {
    test('doneStages devolve vazio sem tocar a rede', () async {
      expect(await repo(uid: '').doneStages('m1'), isEmpty);
      verifyNever(() => dataSource.fetch(any()));
    });

    test('markStageDone e no-op sem tocar a rede', () async {
      await repo(uid: '').markStageDone('m1', 0);
      verifyNever(() => dataSource.save(any(), any()));
    });
  });

  group('doneStages', () {
    test('le as etapas do modulo do documento do usuario', () async {
      when(() => dataSource.fetch('u1')).thenAnswer((_) async => {
            'stages_done': {
              'm1': [0, 2],
              'm2': [0],
            },
          });

      expect(await repo().doneStages('m1'), {0, 2});
      expect(await repo().doneStages('m3'), isEmpty);
    });

    test('falha de rede degrada pra vazio (trilha continua navegavel)',
        () async {
      when(() => dataSource.fetch('u1')).thenThrow(FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      ));

      expect(await repo().doneStages('m1'), isEmpty);
    });
  });

  group('markStageDone', () {
    test('mescla a etapa nova com as existentes e salva ordenado',
        () async {
      when(() => dataSource.fetch('u1')).thenAnswer((_) async => {
            'stages_done': {
              'm1': [2, 0],
            },
          });
      when(() => dataSource.save(any(), any())).thenAnswer((_) async {});

      await repo().markStageDone('m1', 1);

      final captured =
          verify(() => dataSource.save('u1', captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['stages_done'], {
        'm1': [0, 1, 2],
      });
    });

    test('marcar etapa repetida nao duplica', () async {
      when(() => dataSource.fetch('u1')).thenAnswer((_) async => {
            'stages_done': {
              'm1': [0],
            },
          });
      when(() => dataSource.save(any(), any())).thenAnswer((_) async {});

      await repo().markStageDone('m1', 0);

      final captured =
          verify(() => dataSource.save('u1', captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['stages_done'], {
        'm1': [0],
      });
    });

    test('falha de rede na escrita nao propaga excecao', () async {
      when(() => dataSource.fetch('u1')).thenAnswer((_) async => null);
      when(() => dataSource.save(any(), any())).thenThrow(FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      ));

      await expectLater(repo().markStageDone('m1', 0), completes);
    });
  });
}
