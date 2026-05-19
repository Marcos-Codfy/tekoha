// lib/core/utils/text_utils.dart
// Camada: Core (utilitarios puros, sem dependencias de Flutter).
//
// Funcoes pra normalizar texto antes de comparar respostas em Nheengatu.
// Sera usado pelo exercicio do tipo Translate (Sprint 4): o usuario
// digita a resposta livremente, e queremos aceitar pequenas variacoes
// (maiusculas, espacos a mais, aspas curvas vs retas).
//
// Exemplo:
//   normalize("  Puranga Ara  ") -> "puranga ara"
//   isCorrect("Puranga Ara", "puranga ara") -> true

class TextUtils {
  TextUtils._(); // construtor privado: classe so com metodos estaticos

  /// Devolve [text] em minusculas, sem espacos extras e com aspas
  /// tipograficas (’ ‘) convertidas em apostrofo simples (').
  ///
  /// O foco e tornar a comparacao tolerante a pequenas diferencas
  /// de digitacao sem alterar o significado da palavra.
  static String normalize(String text) {
    return text
        .trim()
        .toLowerCase()
        // Converte aspas curvas/tipograficas em aspa simples reta.
        // Usamos os codigos unicode ‘ (‘) e ’ (’) diretamente.
        .replaceAll(RegExp('[‘’]'), "'")
        // Multiplos espacos viram um so.
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Compara duas strings depois de normalizar as duas.
  /// Retorna `true` se forem equivalentes pra fins de exercicio.
  static bool isCorrect(String userAnswer, String correctAnswer) {
    return normalize(userAnswer) == normalize(correctAnswer);
  }
}
