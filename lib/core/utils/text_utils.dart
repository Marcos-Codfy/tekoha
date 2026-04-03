// lib/core/utils/text_utils.dart
// FunÃ§Ãµes para normalizar texto â€” importante para comparar respostas em Nheengatu
// ResponsÃ¡vel: Marcos
// Exemplo: "Serui" e "  serui  " devem ser consideradas respostas iguais

class TextUtils {
  /// Remove espaÃ§os extras e converte para minÃºsculas
  static String normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"['\\u2018\u2019]"), "'") // Normaliza aspas
        .replaceAll(RegExp(r'\s+'), ' ');               // Remove espaÃ§os duplos
  }

  /// Verifica se a resposta do usuÃ¡rio estÃ¡ correta (ignora maiÃºsculas/espaÃ§os)
  static bool isCorrect(String userAnswer, String correctAnswer) {
    return normalize(userAnswer) == normalize(correctAnswer);
  }
}
