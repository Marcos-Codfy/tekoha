// lib/core/utils/validators.dart
// Camada: Core (utilitarios puros).
//
// Funcoes de validacao usadas nos `validator:` dos TextFormField.
// Cada funcao devolve:
//   null            -> valor valido
//   String (texto)  -> mensagem de erro pra mostrar embaixo do campo

class Validators {
  Validators._(); // construtor privado: classe so com metodos estaticos

  /// Verifica se o e-mail tem formato basico (algo@algo.algo).
  /// Nao tenta cobrir 100% das regras RFC — pega 99% dos casos de uso real.
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Informe seu e-mail';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'E-mail invalido';
    return null;
  }

  /// Senha precisa ter pelo menos 6 caracteres (minimo do Firebase Auth).
  /// A forca da senha (fraca/razoavel/boa/forte) e calculada separadamente
  /// na RegisterScreen pra mostrar a barra colorida.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha';
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }
}
