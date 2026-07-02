// test/features/lesson/domain/builders/audio_exercise_builder_test.dart
//
// Estrategia: invariantes da intercalacao por palavra (3 exercicios por
// saudacao, ordem trad-word-repeat), boundary (lista vazia, 1 palavra,
// palavra sem audio filtrada), determinismo com seed.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/lesson/domain/builders/audio_exercise_builder.dart';
import 'package:tekoha/features/lesson/domain/entities/audio_exercise.dart';
import 'package:tekoha/features/lesson/domain/entities/word.dart';

Word _w(int order, String nh, String tr, {String url = ''}) => Word(
      id: 'rec$order',
      nheengatu: nh,
      translation: tr,
      pronunciation: 'pron-$nh',
      culturalNote: '',
      lessonId: 'L1',
      order: order,
      audioUrl: url,
    );

void main() {
  group('AudioExerciseBuilder.build', () {
    test('palavras sem audio sao filtradas (boundary: todas sem)', () {
      final words = [_w(1, 'ara', 'manha'), _w(2, 'karuka', 'tarde')];
      final ex = AudioExerciseBuilder.build(words);
      expect(ex, isEmpty);
    });

    test('lista vazia devolve lista vazia (boundary)', () {
      expect(AudioExerciseBuilder.build(const []), isEmpty);
    });

    test('3 exercicios por palavra na ordem trad-word-repeat', () {
      final words = [
        _w(1, 'ara', 'manha', url: 'http://a/a.mp3'),
        _w(2, 'karuka', 'tarde', url: 'http://a/k.mp3'),
      ];
      final ex = AudioExerciseBuilder.build(words, random: Random(0));

      expect(ex, hasLength(6));
      expect(ex[0].type, AudioExerciseType.listenChooseTranslation);
      expect(ex[1].type, AudioExerciseType.listenChooseWord);
      expect(ex[2].type, AudioExerciseType.listenAndRepeat);
      expect(ex[3].type, AudioExerciseType.listenChooseTranslation);
      expect(ex[4].type, AudioExerciseType.listenChooseWord);
      expect(ex[5].type, AudioExerciseType.listenAndRepeat);

      // Target da primeira trinca = ara; da segunda = karuka.
      expect(ex[0].target.nheengatu, 'ara');
      expect(ex[3].target.nheengatu, 'karuka');
    });

    test('listenAndRepeat nao tem opcoes nem correctIndex valido', () {
      final words = [_w(1, 'ara', 'manha', url: 'http://a/a.mp3')];
      final ex = AudioExerciseBuilder.build(words);
      final repeat = ex.firstWhere(
        (e) => e.type == AudioExerciseType.listenAndRepeat,
      );
      expect(repeat.options, isEmpty);
      expect(repeat.correctIndex, -1);
      expect(repeat.correctAnswer, '');
    });

    test('options de listenChooseTranslation contem a traducao correta',
        () {
      final words = [
        _w(1, 'ara', 'manha', url: 'http://a/a.mp3'),
        _w(2, 'karuka', 'tarde', url: 'http://a/k.mp3'),
      ];
      final ex = AudioExerciseBuilder.build(words, random: Random(3));
      final t = ex.firstWhere(
        (e) => e.type == AudioExerciseType.listenChooseTranslation,
      );
      expect(t.options[t.correctIndex], t.target.translation);
      expect(t.options, containsAll(['manha', 'tarde']));
    });

    test('options de listenChooseWord contem o nheengatu correto', () {
      final words = [
        _w(1, 'ara', 'manha', url: 'http://a/a.mp3'),
        _w(2, 'karuka', 'tarde', url: 'http://a/k.mp3'),
      ];
      final ex = AudioExerciseBuilder.build(words, random: Random(3));
      final w = ex.firstWhere(
        (e) => e.type == AudioExerciseType.listenChooseWord,
      );
      expect(w.options[w.correctIndex], w.target.nheengatu);
      expect(w.options, containsAll(['ara', 'karuka']));
    });

    test('com 1 palavra so, listenChooseTranslation tem 1 opcao apenas '
        '(boundary minimo)', () {
      final words = [_w(1, 'ara', 'manha', url: 'http://a/a.mp3')];
      final ex = AudioExerciseBuilder.build(words);
      final t = ex.firstWhere(
        (e) => e.type == AudioExerciseType.listenChooseTranslation,
      );
      expect(t.options, ['manha']);
      expect(t.correctIndex, 0);
    });

    test('palavras misturadas com/sem audio so geram exercicios das com',
        () {
      final words = [
        _w(1, 'ara', 'manha', url: 'http://a/a.mp3'),
        _w(2, 'kuara', 'sol'), // sem audio
        _w(3, 'karuka', 'tarde', url: 'http://a/k.mp3'),
      ];
      final ex = AudioExerciseBuilder.build(words);
      // 2 palavras com audio -> 6 exercicios.
      expect(ex, hasLength(6));
      final targets =
          ex.map((e) => e.target.nheengatu).toSet();
      expect(targets, {'ara', 'karuka'});
    });

    test('com muitas palavras, exercicios de escolha tem no maximo 4 opcoes '
        '(ESP-004: Hick-Hyman / consistencia com o quiz)', () {
      final words = List.generate(
        10,
        (i) => _w(i + 1, 'palavra$i', 'traducao$i', url: 'http://a/$i.mp3'),
      );
      final ex = AudioExerciseBuilder.build(words, random: Random(5));

      final chooseExercises = ex.where(
        (e) => e.type != AudioExerciseType.listenAndRepeat,
      );
      expect(chooseExercises, isNotEmpty);
      for (final e in chooseExercises) {
        expect(e.options.length, AudioExerciseBuilder.kMaxOptions);
        // A correta sempre presente e apontada pelo correctIndex.
        expect(e.options[e.correctIndex], e.correctAnswer);
        // Sem opcoes duplicadas.
        expect(e.options.toSet().length, e.options.length);
      }
    });

    test('mesma seed produz resultado identico (determinismo)', () {
      final words = [
        _w(1, 'ara', 'manha', url: 'http://a/a.mp3'),
        _w(2, 'karuka', 'tarde', url: 'http://a/k.mp3'),
        _w(3, 'pituna', 'noite', url: 'http://a/p.mp3'),
      ];
      final a = AudioExerciseBuilder.build(words, random: Random(7));
      final b = AudioExerciseBuilder.build(words, random: Random(7));
      for (var i = 0; i < a.length; i++) {
        expect(a[i].options, b[i].options);
        expect(a[i].correctIndex, b[i].correctIndex);
      }
    });
  });
}
