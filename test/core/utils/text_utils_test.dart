// test/core/utils/text_utils_test.dart
//
// Estrategia: equivalence partitioning das classes de entrada
// (vazio, so-espaco, maiusculas, aspas tipograficas, espacos internos
// excedentes) + casos de fronteira (string vazia, so 1 char).

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/core/utils/text_utils.dart';

void main() {
  group('TextUtils.normalize', () {
    test('strings simples sao mantidas em minusculas', () {
      expect(TextUtils.normalize('Olá'), 'olá');
    });

    test('apara espacos no inicio e fim', () {
      expect(TextUtils.normalize('  puranga  '), 'puranga');
    });

    test('multiplos espacos internos viram um so', () {
      expect(TextUtils.normalize('Bom    dia'), 'bom dia');
    });

    test('quebras de linha e tabs sao tratadas como espaco', () {
      // \s+ no regex cobre \n e \t.
      expect(TextUtils.normalize('Bom\tdia'), 'bom dia');
      expect(TextUtils.normalize('Bom\ndia'), 'bom dia');
    });

    test('aspas curvas viram aspa reta', () {
      expect(TextUtils.normalize('it’s'), "it's"); // U+2019
      expect(TextUtils.normalize('it‘s'), "it's"); // U+2018
    });

    test('string vazia retorna vazia (boundary)', () {
      expect(TextUtils.normalize(''), '');
    });

    test('string so com espacos retorna vazia (boundary)', () {
      expect(TextUtils.normalize('   '), '');
    });

    test('caso composto: caixa + aspas + espacos', () {
      expect(
        TextUtils.normalize('  Puranga’  Ara  '),
        "puranga' ara",
      );
    });
  });

  group('TextUtils.isCorrect', () {
    test('igual exato e correto', () {
      expect(TextUtils.isCorrect('puranga ara', 'puranga ara'), true);
    });

    test('caixa diferente nao impede acerto', () {
      expect(TextUtils.isCorrect('PURANGA ARA', 'puranga ara'), true);
    });

    test('espacos extras nao impedem acerto', () {
      expect(TextUtils.isCorrect('  Puranga   Ara  ', 'puranga ara'), true);
    });

    test('aspas tipograficas vs aspa reta sao equivalentes', () {
      expect(TextUtils.isCorrect("it’s", "it's"), true);
    });

    test('strings diferentes retornam false', () {
      expect(TextUtils.isCorrect('outra coisa', 'puranga ara'), false);
    });

    test('strings vazias sao iguais entre si', () {
      expect(TextUtils.isCorrect('', ''), true);
      expect(TextUtils.isCorrect('   ', '   '), true);
    });
  });
}
