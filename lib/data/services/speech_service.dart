// lib/data/services/speech_service.dart
// Wrapper do reconhecimento de voz (speech_to_text) pra o exercicio
// "ouvir e repetir".
//
// IMPORTANTE: o motor do Android NAO entende Nheengatu. Usamos locale
// pt_BR (o mais proximo foneticamente) e comparamos com tolerancia alta
// contra a pronuncia aportuguesada E o proprio texto Nheengatu. E uma
// aproximacao encorajadora pra demo, NAO um avaliador fonetico rigoroso.
//
// Responsavel: Marcos (gerado por Claude)

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  /// Pede permissao de microfone e inicializa o motor.
  /// Retorna true se esta tudo pronto pra ouvir.
  Future<bool> init() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _available = false;
      return false;
    }
    _available = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _available;
  }

  /// Comeca a ouvir. [onResult] recebe a transcricao (parcial e final).
  /// Para sozinho apos [pauseFor] de silencio ou [listenFor] total.
  Future<void> listen({
    required void Function(String transcript) onResult,
  }) async {
    if (!_available) return;
    await _speech.listen(
      localeId: 'pt_BR', // mais proximo foneticamente do Nheengatu
      listenFor: const Duration(seconds: 6),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) => onResult(result.recognizedWords),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  /// Validacao TOLERANTE: compara a fala do usuario com os alvos
  /// (pronuncia E texto Nheengatu). Aceita se a similaridade passar
  /// de [threshold]. Threshold baixo de proposito (encorajador).
  ///
  /// Retorna true se considerou "acertou".
  bool matches(
    String spoken,
    List<String> targets, {
    double threshold = 0.5,
  }) {
    final s = _normalize(spoken);
    if (s.isEmpty) return false;
    for (final target in targets) {
      final t = _normalize(target);
      if (t.isEmpty) continue;
      if (s.contains(t) || t.contains(s)) return true;
      if (_similarity(s, t) >= threshold) return true;
    }
    return false;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\sãâáàéêíóôõúç]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Similaridade simples baseada em distancia de Levenshtein normalizada.
  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1.0;
    return 1.0 - (dist / maxLen);
  }

  int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }
    return dp[m][n];
  }
}
