// lib/core/constants/app_flags.dart
// Feature flags do app. Liga/desliga comportamentos rapidamente
// sem ter que mexer em varios arquivos.

/// Quando `true`, o app PULA a splash, login e cadastro, abrindo direto
/// no MainScaffold (com a bottom nav). Util pra testar telas internas
/// sem ter que logar a cada hot restart.
///
/// PRA REATIVAR O LOGIN:
///   mude o valor pra `false` aqui e faca hot restart (R no terminal flutter).
///
/// Quando bypass esta ON:
///   - SplashScreen, LoginScreen e RegisterScreen continuam existindo,
///     so nao sao usadas na navegacao inicial.
///   - O botao "Sair" no Perfil fica desativado (vira um aviso).
///   - context.read<AuthProvider>().currentUser eh `null` (ninguem logado).
const bool kBypassAuth = true;
