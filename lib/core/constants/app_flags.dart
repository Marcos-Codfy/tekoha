// lib/core/constants/app_flags.dart
// Feature flags do app. Liga/desliga comportamentos rapidamente
// sem ter que mexer em varios arquivos.

/// Quando `true`, o app PULA a splash, login e cadastro, abrindo direto
/// no MainScaffold (com a bottom nav). Util pra testar telas internas
/// sem ter que logar a cada hot restart.
///
/// DESDE A ESP-007 (02/07/2026) O LOGIN ESTA ATIVO (`false`):
///   - Splash roteia por sessao: logado -> Home; deslogado -> Login.
///   - A sessao do Firebase Auth persiste nativamente no aparelho —
///     o usuario continua conectado ate tocar em "Sair" no Perfil
///     ("manter logado" sem armazenar senha; OWASP + Nielsen H1).
///   - XP, streak, etapas e conquistas persistem em user_progress/{uid}.
///
/// Pra voltar ao modo demonstracao (sem login): `true` + hot restart.
const bool kBypassAuth = false;
