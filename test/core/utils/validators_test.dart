// test/core/utils/validators_test.dart
//
// Estrategia: equivalence partitioning + boundary values.
// Email partitions: null/vazio, formato invalido (sem @, sem dominio,
//   TLD < 2 chars, TLD > 4 chars), valido tipico, valido com dot+hifen.
// Senha partitions: null/vazio, 0..5 chars (invalido), 6 chars (boundary
//   minimo), 7+ chars (valido).

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('null retorna mensagem de obrigatorio', () {
      expect(Validators.email(null), 'Informe seu e-mail');
    });

    test('string vazia retorna mensagem de obrigatorio', () {
      expect(Validators.email(''), 'Informe seu e-mail');
    });

    test('sem @ e invalido', () {
      expect(Validators.email('semarroba.com'), 'E-mail invalido');
    });

    test('sem dominio depois do @ e invalido', () {
      expect(Validators.email('foo@'), 'E-mail invalido');
    });

    test('sem TLD e invalido', () {
      expect(Validators.email('foo@bar'), 'E-mail invalido');
    });

    test('TLD com 1 char e invalido (boundary: minimo do regex e 2)', () {
      expect(Validators.email('foo@bar.x'), 'E-mail invalido');
    });

    test('TLD com 2 chars e valido (boundary minimo)', () {
      expect(Validators.email('foo@bar.io'), isNull);
    });

    test('TLD com 4 chars e valido (boundary maximo)', () {
      expect(Validators.email('foo@bar.info'), isNull);
    });

    test('email com ponto e hifen no local-part e valido', () {
      expect(Validators.email('foo.bar-baz@example.co'), isNull);
    });

    test('subdominio e valido', () {
      expect(Validators.email('user@mail.example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('null retorna obrigatorio', () {
      expect(Validators.password(null), 'Informe sua senha');
    });

    test('vazia retorna obrigatorio', () {
      expect(Validators.password(''), 'Informe sua senha');
    });

    test('5 chars retorna mensagem de minimo (boundary -1)', () {
      expect(
        Validators.password('12345'),
        'A senha deve ter pelo menos 6 caracteres',
      );
    });

    test('6 chars e valida (boundary minimo)', () {
      expect(Validators.password('123456'), isNull);
    });

    test('7+ chars e valida', () {
      expect(Validators.password('1234567'), isNull);
      expect(Validators.password('senhaforte#123'), isNull);
    });
  });
}
