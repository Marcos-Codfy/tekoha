// lib/core/constants/cultures.dart
// Lista estatica das culturas/linguas disponiveis na aba Cultura.
// Por enquanto so o Nheengatu esta ativo; os demais sao placeholders
// "Em breve" pra sinalizar que a aba vai crescer.
//
// Quando uma nova cultura entrar em producao:
//   1. Adicione uma entrada com `available: true`.
//   2. Garanta que [key] bate com o valor da coluna `language` no
//      Airtable (campo da tabela CultureContent).
//   3. Considere se o ContentProvider precisa indexar o cache por idioma
//      tambem — hoje ele indexa so por categoria.

class CultureLanguage {
  /// Valor armazenado no campo `language` do Airtable (ex.: 'nheengatu').
  /// Vira o filtro em `loadCultureContent`.
  final String key;

  /// Texto exibido na UI (titulo do card e AppBar da tela detalhe).
  final String label;

  /// Descricao curta opcional, mostrada como subtitulo no card.
  final String? subtitle;

  /// Quando `false`, o card aparece desativado ("Em breve").
  final bool available;

  const CultureLanguage({
    required this.key,
    required this.label,
    this.subtitle,
    this.available = true,
  });
}

const List<CultureLanguage> kCultureLanguages = [
  CultureLanguage(
    key: 'nheengatu',
    label: 'Nheengatu',
    subtitle: 'Tronco Tupi · Alto Rio Negro',
    available: true,
  ),
  CultureLanguage(
    key: '_placeholder_1',
    label: 'Em breve',
    subtitle: 'Mais línguas em breve',
    available: false,
  ),
  CultureLanguage(
    key: '_placeholder_2',
    label: 'Em breve',
    subtitle: 'Mais línguas em breve',
    available: false,
  ),
];
