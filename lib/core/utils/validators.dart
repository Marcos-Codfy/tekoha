// lib/core/utils/validators.dart
// FunÃ§Ãµes de validaÃ§Ã£o de formulÃ¡rios (login, cadastro)
// ResponsÃ¡vel: Marcos

class Validators {
  /// Valida se o e-mail tem formato correto
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Informe seu e-mail';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'E-mail invÃ¡lido';
    return null; // null = vÃ¡lido
  }

  /// Valida se a senha tem pelo menos 6 caracteres
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha';
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }
}
