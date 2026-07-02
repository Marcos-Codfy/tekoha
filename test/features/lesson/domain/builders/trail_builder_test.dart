// test/features/lesson/domain/builders/trail_builder_test.dart
//
// Estrategia: divisao curada por modulo (tamanhos + titulos), fallback
// generico (total divergente, modulo desconhecido), ordenacao previa
// por Word.order, boundaries (vazio) e exerciseCount.

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/lesson/domain/builders/trail_builder.dart';
import 'package:tekoha/features/lesson/domain/entities/word.dart';

Word _w(int order, {bool audio = true}) => Word(
      id: 'rec$order',
      nheengatu: 'nh$order',
      translation: 'tr$order',
      pronunciation: 'pr$order',
      culturalNote: '',
      lessonId: 'L1',
      order: order,
      audioUrl: audio ? 'http://a/$order.mp3' : '',
    );

List<Word> _tenWords() => List.generate(10, (i) => _w(i + 1));

void main() {
  group('TrailBuilder.build — divisao curada', () {
    test('modulo 1 divide 10 palavras em 3/3/2/2 com titulos aprovados', () {
      final stages = TrailBuilder.build(_tenWords(), moduleOrder: 1);

      expect(stages, hasLength(4));
      expect(stages.map((s) => s.words.length), [3, 3, 2, 2]);
      expect(stages.map((s) => s.title), [
        'A palavra curinga',
        'O encontro',
        'Sim e não',
        'Gratidão e despedida',
      ]);
      // Sem sobreposicao nem buraco: cobre as 10 palavras em ordem.
      final allOrders =
          stages.expand((s) => s.words).map((w) => w.order).toList();
      expect(allOrders, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('modulo 3 divide 10 palavras em 3/2/3/2 (agua/ceu/mata/fauna)', () {
      final stages = TrailBuilder.build(_tenWords(), moduleOrder: 3);

      expect(stages.map((s) => s.words.length), [3, 2, 3, 2]);
      expect(stages.first.title, 'O mundo das águas');
      expect(stages.last.title, 'Os que vivem nela');
    });

    test('palavras fora de ordem sao ordenadas por Word.order antes '
        'da fatia', () {
      final shuffled = [_w(5), _w(1), _w(3), _w(2), _w(4)];
      final stages = TrailBuilder.build(shuffled, moduleOrder: 99);

      final firstStageOrders =
          stages.first.words.map((w) => w.order).toList();
      expect(firstStageOrders, firstStageOrders..sort());
      expect(stages.first.words.first.order, 1);
    });
  });

  group('TrailBuilder.build — fallback generico', () {
    test('modulo desconhecido cai em etapas de ate 3 palavras (10 -> '
        '3/3/2/2) com titulos "Etapa N"', () {
      final stages = TrailBuilder.build(_tenWords(), moduleOrder: 42);

      expect(stages.map((s) => s.words.length), [3, 3, 2, 2]);
      expect(stages.map((s) => s.title),
          ['Etapa 1', 'Etapa 2', 'Etapa 3', 'Etapa 4']);
    });

    test('total de palavras diferente da divisao curada tambem cai no '
        'fallback (conteudo mudou no Airtable)', () {
      final elevenWords = List.generate(11, (i) => _w(i + 1));
      final stages = TrailBuilder.build(elevenWords, moduleOrder: 1);

      // 11 palavras -> 4 etapas (3/3/3/2), nenhuma com mais de 3.
      expect(stages.fold(0, (t, s) => t + s.words.length), 11);
      for (final s in stages) {
        expect(s.words.length, lessThanOrEqualTo(3));
        expect(s.title, startsWith('Etapa'));
      }
    });

    test('lista vazia devolve trilha vazia (boundary)', () {
      expect(TrailBuilder.build(const [], moduleOrder: 1), isEmpty);
    });
  });

  group('TrailBuilder.specsFor / stageCountFor', () {
    test('stageCountFor devolve 4 pros modulos curados com 10 palavras',
        () {
      expect(TrailBuilder.stageCountFor(1, 10), 4);
      expect(TrailBuilder.stageCountFor(2, 10), 4);
      expect(TrailBuilder.stageCountFor(3, 10), 4);
    });

    test('specsFor de modulo curado soma exatamente o total de palavras',
        () {
      for (final order in [1, 2, 3]) {
        final specs = TrailBuilder.specsFor(order, 10);
        expect(specs.fold(0, (t, s) => t + s.wordCount), 10);
      }
    });
  });

  group('TrailStage.exerciseCount', () {
    test('palavra com audio vale 4 exercicios; sem audio vale 1', () {
      final words = [_w(1), _w(2), _w(3, audio: false)];
      final stages = TrailBuilder.build(words, moduleOrder: 99);

      // Fallback: 3 palavras -> 1 etapa unica. 4 + 4 + 1 = 9.
      expect(stages.single.exerciseCount, 9);
    });

    test('etapa de 3 palavras com audio gera 12 exercicios (teto ESP-005)',
        () {
      final stages = TrailBuilder.build(_tenWords(), moduleOrder: 1);
      expect(stages.first.exerciseCount, 12);
      // Nenhuma etapa passa de 12 exercicios.
      for (final s in stages) {
        expect(s.exerciseCount, lessThanOrEqualTo(12));
      }
    });
  });
}
