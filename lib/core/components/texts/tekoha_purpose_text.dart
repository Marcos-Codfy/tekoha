// lib/core/components/texts/tekoha_purpose_text.dart
//
// Texto curto de PROPOSITO — enquadra a acao do usuario como contribuicao
// concreta a revitalizacao do Nheengatu.
//
// Fundamentacao:
//   - Self-Determination Theory (Deci & Ryan, 2000) — necessidade de
//     RELACIONAMENTO/CONEXAO: aprender ganha sentido quando ligado a
//     proposito coletivo.
//   - Control-Value Theory (Pekrun, 2006) — eleva o VALOR percebido da
//     atividade, sustentando engajamento.
//
// Usado em: Home, Profile, _DoneView. Sempre cinza-secundario, italico,
// centralizado. Centraliza a propria definicao do estilo num lugar so —
// se mudarmos de fonte/cor amanha, muda em todas as telas.

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class TekohaPurposeText extends StatelessWidget {
  final String text;

  /// Padrao centralizado. Em casos especificos (ex.: dentro de Row),
  /// pode passar `align: TextAlign.start`.
  final TextAlign align;

  /// Padrao em italico. Setar `false` quando dentro de feedback bar
  /// que ja e italico, pra evitar dupla enfase.
  final bool italic;

  const TekohaPurposeText({
    super.key,
    required this.text,
    this.align = TextAlign.center,
    this.italic = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: 1.5,
      ),
    );
  }
}
