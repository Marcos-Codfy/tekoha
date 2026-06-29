// lib/data/services/audio_player_service.dart
// Servico singleton de reproducao de audio das saudacoes.
//
// ESTRATEGIA ANTI-BUG PRA DEMO: baixa cada MP3 UMA VEZ pra um arquivo
// temporario (preload) e toca do disco local. Reproducao instantanea e
// nao depende da rede no momento da demo (so no preload inicial).
// Se o preload de uma URL falhar, o play() cai pro fallback de tocar
// direto da URL — degrada gracioso em vez de explodir.
//
// Responsavel: Marcos (gerado por Claude)

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AudioPlayerService {
  AudioPlayerService._();
  static final AudioPlayerService instance = AudioPlayerService._();

  final AudioPlayer _player = AudioPlayer();

  /// Cache: url remota -> caminho do arquivo local baixado.
  final Map<String, String> _localPaths = {};

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  /// Baixa todos os [urls] pra arquivos temporarios (1x cada).
  /// Chame ao abrir a tela. Falha em uma URL nao impede as outras.
  Future<void> preload(List<String> urls) async {
    final dir = await getTemporaryDirectory();
    for (final url in urls) {
      if (url.trim().isEmpty) continue;
      if (_localPaths.containsKey(url)) continue; // ja baixado
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          // Nome de arquivo seguro a partir da URL.
          final fileName = url.split('/').last;
          final file = File('${dir.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          _localPaths[url] = file.path;
        }
      } catch (_) {
        // Ignora: se nao baixou, o play() cai pro fallback de URL.
      }
    }
  }

  /// Toca o audio da [url]. Usa o arquivo local se ja foi baixado;
  /// senao toca direto da URL (fallback). Se [url] vazia, nao faz nada.
  Future<void> play(String url) async {
    if (url.trim().isEmpty) return;
    try {
      await _player.stop();
      final localPath = _localPaths[url];
      if (localPath != null && File(localPath).existsSync()) {
        await _player.play(DeviceFileSource(localPath));
      } else {
        await _player.play(UrlSource(url));
      }
      _isPlaying = true;
      // Marca como nao-tocando quando o audio termina.
      _player.onPlayerComplete.first.then((_) => _isPlaying = false);
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  /// Libera o player. Chame em dispose() apenas se for desmontar o app —
  /// como e singleton, normalmente nao chamar.
  Future<void> dispose() async {
    await _player.dispose();
  }
}
