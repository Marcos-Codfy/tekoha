// test/features/lesson/domain/builders/quiz_builder_test.dart
//
// Estrategia: comportamento determinístico (seed fixa), invariantes do
// algoritmo (4 opcoes, 1 correta, distratores nao repetem a correta),
// boundary (4 palavras minimo, exatamente 4, mais que 4).

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/lesson/domain/builders/quiz_builder.dart';
import 'package:tekoha/features/lesson/domain/entities/word.dart';

Word _w(int order, String nh, String tr) => Word(
      id: 'rec$order',
      nheengatu: nh,
      translation: tr,
      pronunciation: 'pron-$nh',
      culturalNote: '',
      lessonId: 'L1',
      order: order,
    );

void main() {
  final pool = [
    _w(1, 'ara', 'manha'),
    _w(2, 'karuka', 'tarde'),
    _w(3, 'pituna', 'noite'),
    _w(4, 'kuara', 'sol'),
    _w(5, 'iuy', 'agua'),
  ];

  group('QuizBuilder.build', () {
    test('gera 1 pergunta por target', () {
      final questions = QuizBuilder.build(
        targets: pool.take(3).toList(),
        pool: pool,
      );
      expect(questions, hasLength(3));
    });

    test('cada pergunta tem 4 opcoes (1 correta + 3 distratores)', () {
      final questions = QuizBuilder.build(
        targets: pool.take(2).toList(),
        pool: pool,
        random: Random(42),
      );
      for (final q in questions) {
        expect(q.options, hasLength(4));
        expect(q.options[q.correctIndex], q.word.nheengatu);
      }
    });

    test('distratores NAO incluem a palavra correta', () {
      final questions = QuizBuilder.build(
        targets: pool.take(3).toList(),
        pool: pool,
        random: Random(1),
      );
      for (final q in questions) {
        final distractors = [...q.options]..removeAt(q.correctIndex);
        expect(
          distractors,
          isNot(contains(q.word.nheengatu)),
          reason: 'distratores nao podem repetir a correta',
        );
      }
    });

    test('boundary: pool com exatamente 4 palavras ainda gera quiz valido',
        () {
      final small = pool.take(4).toList();
      final questions = QuizBuilder.build(
        targets: small,
        pool: small,
        random: Random(7),
      );
      expect(questions, hasLength(4));
      for (final q in questions) {
        expect(q.options, hasLength(4));
        expect(q.options[q.correctIndex], q.word.nheengatu);
      }
    });

    test('mesma seed produz resultado IDENTICO (determinismo)', () {
      final a = QuizBuilder.build(
        targets: pool.take(3).toList(),
        pool: pool,
        random: Random(99),
      );
      final b = QuizBuilder.build(
        targets: pool.take(3).toList(),
        pool: pool,
        random: Random(99),
      );
      for (var i = 0; i < a.length; i++) {
        expect(a[i].options, b[i].options);
        expect(a[i].correctIndex, b[i].correctIndex);
      }
    });

    test('targets vazio devolve lista vazia', () {
      final questions = QuizBuilder.build(targets: const [], pool: pool);
      expect(questions, isEmpty);
    });
  });
}
