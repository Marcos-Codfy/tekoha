// lib/core/errors/failures.dart
// Camada: Core.
//
// Hierarquia tipada de falhas usadas em toda a aplicacao.
//
// Por que sealed class?
//   Dart 3 garante MATCH EXAUSTIVO em switch — se eu adicionar um novo
//   tipo de Failure aqui, o compilador me obriga a tratar nele em todos
//   os switchs espalhados pela UI. Erros silenciosos viram erros de
//   compilacao.
//
// Por que NAO usar so Exception?
//   Exception nao carrega `userMessage` em PT-BR e nao distingue entre
//   sem-internet (recuperavel com retry) e 401 (precisa avisar dev).
//   A UI fica adivinhando o que mostrar. Com Failure tipado a UI escolhe
//   o widget certo (ex.: tela de offline vs banner de erro).
//
// CONVENCAO:
//   - `userMessage`  -> texto pronto pra mostrar ao usuario final (PT-BR).
//   - `technicalDetails` -> contexto pra log/debug; nunca expor na UI.

sealed class Failure {
  final String userMessage;
  final String? technicalDetails;

  const Failure(this.userMessage, [this.technicalDetails]);

  @override
  String toString() =>
      '$runtimeType(userMessage: $userMessage, technicalDetails: $technicalDetails)';
}

/// Sem internet, DNS, host inalcancavel.
/// UI: oferece retry, mostra icone de wifi cortado.
class NetworkFailure extends Failure {
  const NetworkFailure([String? technicalDetails])
      : super(
          'Sem conexao com a internet. Verifique sua rede e tente de novo.',
          technicalDetails,
        );
}

/// Requisicao demorou mais que o timeout configurado.
class TimeoutFailure extends Failure {
  const TimeoutFailure([String? technicalDetails])
      : super(
          'A requisicao demorou demais. Tente de novo em alguns segundos.',
          technicalDetails,
        );
}

/// HTTP 401/403 — token invalido ou sem permissao.
/// UI: mensagem "avise o desenvolvedor" (nao e algo que o usuario resolve).
class AuthApiFailure extends Failure {
  const AuthApiFailure([
    super.userMessage = 'Acesso negado ao servidor. Avise o desenvolvedor.',
    super.technicalDetails,
  ]);
}

/// HTTP 404 — recurso/tabela nao encontrada.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.userMessage, [super.technicalDetails]);
}

/// HTTP 429 — rate limit do Airtable. Volta a tentar depois.
class RateLimitFailure extends Failure {
  const RateLimitFailure([String? technicalDetails])
      : super(
          'Muitas requisicoes em pouco tempo. Aguarde alguns segundos.',
          technicalDetails,
        );
}

/// HTTP 5xx ou resposta malformada.
class ServerFailure extends Failure {
  const ServerFailure([
    super.userMessage = 'Erro no servidor. Tente novamente em instantes.',
    super.technicalDetails,
  ]);
}

/// .env ausente, chaves vazias, plataforma sem suporte.
/// Diferente de ServerFailure porque o usuario nao pode resolver — e
/// problema de setup.
class ConfigFailure extends Failure {
  const ConfigFailure([
    super.userMessage =
        'Configuracao invalida. Verifique o ambiente do aplicativo.',
    super.technicalDetails,
  ]);
}

/// Erros do FirebaseAuth (login/cadastro). Carrega o code original do
/// FirebaseAuthException pra UI poder customizar a mensagem.
class AuthFailure extends Failure {
  /// Codigo bruto do FirebaseAuth (`user-not-found`, `wrong-password`, etc).
  /// Util pra UI escolher microcopy contextual.
  final String code;

  const AuthFailure({
    required this.code,
    required String userMessage,
    String? technicalDetails,
  }) : super(userMessage, technicalDetails);
}

/// Input do usuario nao passou na validacao do dominio.
/// Diferente das mensagens dos `Validators` (que rodam no formulario);
/// esta aqui e pra regras de negocio (ex.: senha fraca apos backend).
class ValidationFailure extends Failure {
  const ValidationFailure(super.userMessage, [super.technicalDetails]);
}

/// Erro nao mapeado. Use so como fallback final no catch generico.
class UnknownFailure extends Failure {
  const UnknownFailure([String? technicalDetails])
      : super('Erro inesperado. Tente novamente.', technicalDetails);
}
