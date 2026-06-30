# Tekohá

Aplicativo mobile educacional para ensino gamificado da língua **Nheengatu**, projeto de Iniciação Científica do UniCatólica Tocantins (linha: Direitos Humanos).

> *Tekohá* — palavra guarani que significa "o lugar onde se vive a cultura".

---

## Sumário

- [Status atual](#status-atual)
- [Stack tecnológica](#stack-tecnológica)
- [Pré-requisitos](#pré-requisitos)
- [Como rodar o projeto](#como-rodar-o-projeto)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Arquitetura](#arquitetura)
- [Biblioteca de componentes](#biblioteca-de-componentes)
- [Conteúdo no Airtable](#conteúdo-no-airtable)
- [Feature flags](#feature-flags)
- [Workflow de contribuição](#workflow-de-contribuição)
- [Testes](#testes)
- [Troubleshooting](#troubleshooting)
- [Autor](#autor)

---

## Status atual

O app está em estado **MVP polido**, pronto pra avaliação heurística com 3-5 professores. Funcionalidades:

- **Bottom navigation** com 4 abas: Home, Aprenda, Cultura e Perfil — `IndexedStack` preserva estado de cada aba.
- **Autenticação** com Firebase Auth implementada mas **desativada por feature flag** (`kBypassAuth = true`) — ver [Feature flags](#feature-flags).
- **Aba Aprenda**: lista os módulos vindos do Airtable, abre lição com fluxo misto (áudio + quiz intercalados) no Módulo 1 e quiz puro nos demais.
- **Aba Cultura**: chips de categoria (Curiosidades, História, Hábitos; Cosmologia desabilitada por compliance pendente) com cards do Airtable, pull-to-refresh e cache por categoria.
- **Gamificação**: XP variável (8/10/12), contador de "palavras dominadas", barra de progresso com Endowed Progress Effect.
- **Permissões Android** para `speech_to_text` (`RECORD_AUDIO` + `INTERNET`) já configuradas — `minSdk = 21`.
- **Clean Architecture** completa (domain/data/presentation por feature) + 142 testes unitários e de integração.
- **Biblioteca de componentes** reutilizáveis em `lib/core/components/` (botões, badges, chips, banners, etc).

Cada decisão UX/UI tem fundamentação científica citável — ver `C:\Users\Marcos\.claude\plans\crispy-questing-dragonfly.md` (biblioteca conceitual: SDT, Variable Reward, Goal-Gradient, Peak-End, Color Psychology, etc).

---

## Stack tecnológica

| Camada | Ferramenta |
|---|---|
| Framework | Flutter `>=3.0.0 <4.0.0` + Dart 3 |
| Plataforma alvo | Android (iOS configurável, não testado) |
| Estado | `provider` (`ChangeNotifier`) |
| Injeção de dependência | `get_it` (Service Locator) |
| Backend de auth | Firebase Auth + Cloud Firestore (não usado ainda) |
| CMS de conteúdo | Airtable (REST API) |
| HTTP | pacote `http` |
| Áudio | `audioplayers` (preload + cache local) |
| Reconhecimento de voz | `speech_to_text` (locale pt-BR como proxy) |
| Permissões | `permission_handler` |
| Variáveis de ambiente | `flutter_dotenv` |
| Testes | `flutter_test` + `mocktail` |
| IDE recomendada | Android Studio |

---

## Pré-requisitos

1. **Flutter SDK** 3.0 ou superior — [instruções oficiais](https://docs.flutter.dev/get-started/install).
2. **Android Studio** com o plugin do Flutter instalado.
3. **Emulador Android** rodando ou um dispositivo físico em modo desenvolvedor.
4. Arquivos de configuração privados (já estão no seu setup local):
   - `.env` — chaves do Airtable e Firebase
   - `android/app/google-services.json` — config do Firebase para Android
   - `lib/firebase_options.dart` (gerado pelo `flutterfire configure`)

> Esses arquivos **nunca** devem entrar no Git — já estão no `.gitignore`.

---

## Como rodar o projeto

```bash
# 1. Clone o repositório
git clone https://github.com/Marcos-Codfy/tekoha.git
cd tekoha

# 2. Coloque os arquivos privados nos lugares certos
#    .env                  -> raiz do projeto
#    google-services.json  -> android/app/

# 3. Baixe as dependências
flutter pub get

# 4. Confirme que o emulador/device está conectado
flutter devices

# 5. Rode o app
flutter run
```

O app abre direto na aba **Home** porque `kBypassAuth = true` por padrão (ver [Feature flags](#feature-flags)).

### Conteúdo esperado do `.env`

```env
# Airtable (obrigatório)
AIRTABLE_API_KEY=...
AIRTABLE_BASE_ID=...

# Nomes de tabela — opcionais; defaults caem em Modules/Lessons/Words/CultureContent
AIRTABLE_MODULES_TABLE=Modules
AIRTABLE_LESSONS_TABLE=Lessons
AIRTABLE_WORDS_TABLE=Words
AIRTABLE_CULTURE_TABLE=CultureContent
```

---

## Estrutura de pastas

```
lib/
├── core/                         # Compartilhado entre todas as features
│   ├── app/main_scaffold.dart    # Shell com BottomNavigation (4 abas)
│   ├── components/               # ✨ Widgets reutilizáveis (ver seção abaixo)
│   ├── constants/                # app_colors, app_flags, app_routes, cultures
│   ├── errors/failures.dart      # Hierarquia sealed de Failure
│   ├── network/airtable_client.dart  # Cliente HTTP centralizado
│   ├── result/result.dart        # Result<S, F> sealed (Either-like)
│   ├── services/                 # audio_player_service, speech_service
│   ├── theme/app_theme.dart      # Material 3, paleta Urucum + indígena estendida
│   ├── utils/                    # text_utils, validators
│   └── widgets/error_view.dart   # ErrorView genérico
│
├── di/injection.dart             # Composition root (get_it)
│
├── features/                     # Uma pasta por feature, cada uma com 3 camadas
│   ├── auth/        domain/  data/  presentation/    (login desativado)
│   ├── culture/     domain/  data/  presentation/
│   ├── home/                  presentation/
│   ├── lesson/      domain/  data/  presentation/    (com LessonRunner controller)
│   ├── practice/    domain/  data/  presentation/
│   └── profile/               presentation/
│
├── firebase_options.dart         # Gerado pelo flutterfire — NÃO commitado
└── main.dart                     # Ponto de entrada

test/                             # 142 testes (unit + integration)
```

---

## Arquitetura

Clean Architecture com fatiamento feature-first. Dependências unidirecionais:

```
┌────────────────┐
│ Presentation   │  Provider/ChangeNotifier → Screen → Widget
└───────┬────────┘
        │ depende de (contrato)
        ▼
┌────────────────┐
│    Domain      │  Entity + UseCase + Repository (abstract)
└───────┬────────┘
        │ implementado por
        ▼
┌────────────────┐
│     Data       │  DataSource → DTO → Mapper → RepositoryImpl
└────────────────┘
```

**Regra de ouro:** Domain não conhece Data nem Presentation. Data implementa contratos de Domain. Presentation chama UseCases (não Repositories diretamente).

**Padrões aplicados:**

- **Sealed classes** (Dart 3) em `Failure` e `Result<S, F>` — match exaustivo
- **Service Locator** (`get_it`) em `lib/di/injection.dart`
- **Repository pattern** com cache em memória por feature
- **DTO + Mapper** isolam parsing do Airtable do domínio puro
- **`LessonRunner` controller** (`features/lesson/presentation/controllers/`) extrai toda a máquina de estado da lição de dentro do Widget

**Tratamento de erros:** toda falha vira `Failure` tipada (sealed: `NetworkFailure`, `AuthApiFailure`, `RateLimitFailure`, `ConfigFailure`, etc) com `userMessage` em PT-BR pronta pra UI.

---

## Biblioteca de componentes

`lib/core/components/` centraliza widgets reutilizáveis. Sempre que precisar de um botão/badge/chip, **importa daqui** em vez de criar inline.

```
lib/core/components/
├── buttons/      # TekohaPrimaryButton, TekohaSecondaryButton
├── badges/       # TekohaXpBadge, TekohaStatusPill
├── chips/        # TekohaCategoryChip
├── banners/      # TekohaErrorBanner
├── loaders/      # TekohaLoader, TekohaButtonLoader
└── texts/        # TekohaPurposeText, TekohaSectionLabel, TekohaEncouragementText
```

**Exemplo de uso:**

```dart
import 'package:tekoha/core/components/buttons/tekoha_primary_button.dart';

TekohaPrimaryButton(
  label: 'Praticar Nheengatu',
  icon: Icons.play_arrow,
  isLoading: _isSubmitting,
  onPressed: _handleStart,
)
```

Convenção: nomes começam com `Tekoha` — facilita autocomplete (`Tekoha` + `Ctrl+Space` lista tudo). Pra detalhes de cada componente e por que componentizar, ver [`lib/core/components/README.md`](lib/core/components/README.md).

---

## Conteúdo no Airtable

Base `Tekoha DB` com 4 tabelas:

| Tabela | Conteúdo | Campos principais |
|---|---|---|
| `Modules` | Trilhas de aprendizado (3 registros) | `name`, `description`, `language`, `order`, `is_active` |
| `Lessons` | Lições dentro de um módulo (3 registros) | `title`, `module` (link), `order`, `xp_reward` |
| `Words` | Palavras de uma lição (30 registros) | `nheengatu`, `translation`, `pronunciation`, `cultural_note`, `lesson` (link), `order`, `audio_url` |
| `CultureContent` | Cards da aba Cultura (20 registros) | `language`, `category`, `title`, `body`, `order`, `is_active` |

**Categorias de `CultureContent`** (single select, valores em inglês minúsculo):
`history`, `cosmology`, `habits`, `curiosities`.

**Convenções ortográficas (Navarro, 2011):** `K` (não `C`/`Qu`), `U` (não `W`), `I` (não `Y`). Ex: `Katu` (não "Catu"), `Iauareté` (não "Yauareté").

> Linked records do Airtable retornam IDs no JSON, **não nomes**. Por isso `fetchLessonsByModule` e `fetchWordsByLesson` filtram no código em vez de usar `filterByFormula` no servidor. O comentário detalhando isso está em [`features/lesson/data/datasources/lesson_remote_datasource.dart`](lib/features/lesson/data/datasources/lesson_remote_datasource.dart).

**Áudios:** hospedados no GitHub raw via repo público `Marcos-Codfy/tekoha-assets`. Padrão da URL:
```
https://raw.githubusercontent.com/Marcos-Codfy/tekoha-assets/main/audios/nheengatu/<modulo>/<modulo>_<NN>_<palavra>.mp3
```
Atualmente: 3 de 30 palavras com áudio (saudações do Módulo 1).

---

## Feature flags

Definidas em [`lib/core/constants/app_flags.dart`](lib/core/constants/app_flags.dart).

| Flag | Padrão | Efeito |
|---|---|---|
| `kBypassAuth` | `true` | Pula Splash, Login e Cadastro — abre direto no `MainScaffold`. Útil para demo e desenvolvimento. |

Para reativar o fluxo de login real, mude `kBypassAuth` para `false` e faça hot **restart** (R no terminal, não r minúsculo).

---

## Workflow de contribuição

### Branches

```
main                              # protegida, recebe merge via PR
├── feat/<feature>                # nova funcionalidade
├── fix/<bug>                     # correção
├── refactor/<area>               # refatoração sem mudar comportamento
├── chore/<tarefa>                # build, deps, IDE config
└── docs/<topico>                 # documentação
```

### Conventional Commits

Mensagens em **português**, no **imperativo**, sem acentos (compatibilidade com encoding Windows):

```
feat: adiciona aba Cultura com chips de categoria
fix(airtable): filtra licoes no codigo para evitar problema com linked fields
refactor: desacopla provider de service
feat(components): cria TekohaPrimaryButton reutilizavel
chore: atualiza configuracoes do IDE
docs: atualiza README com instrucoes de setup
test: adiciona testes pra LessonRunner com seed deterministica
```

### Pull Requests

- Sempre via PR para `main`, nunca commit direto (exceção: fast-forward de feature branch já revisada).
- Antes de abrir: rode `flutter analyze` — zero erros novos nos arquivos modificados.
- Antes de mergear: teste localmente com `flutter run` os fluxos afetados.
- PR mergeado pode ser via **squash** ou **merge commit**.

---

## Testes

142 testes (unit + integration). Estrutura espelha `lib/`:

```bash
flutter test                                # tudo
flutter test test/core/                     # só core
flutter test test/features/lesson/          # só feature lesson
flutter test test/integration/              # só integration tests
flutter test --reporter=expanded            # verbose
flutter test --coverage                     # com coverage report
```

**Estratégias aplicadas:**

- Equivalence partitioning (validators, normalize, DTOs)
- Boundary values (4 palavras mínimas, TLD com 1 vs 2 chars, etc)
- Determinismo com seed em builders (`Random(seed)`)
- Mocks com `mocktail` (sem codegen)
- Widget tests pra integração: estado loaded/error/empty + interação

---

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Configuracao do Airtable nao encontrada` | `.env` ausente ou sem `AIRTABLE_API_KEY`/`AIRTABLE_BASE_ID` | Confirme que o arquivo está na raiz e tem as duas chaves preenchidas |
| `Token do Airtable invalido ou expirado` | Token expirou ou está errado | Gere um Personal Access Token novo no Airtable e atualize o `.env` |
| `Base ou tabela "X" nao encontrada` | Nome da tabela no Airtable diferente do código | Confirme nomes reais: `Modules`, `Lessons`, `Words`, `CultureContent` |
| App trava no boot no Chrome | Firebase web não configurado | Rode `flutterfire configure --platforms=web` ou ignore (mensagem é só aviso) |
| `speech_to_text` não reconhece fala | Emulador não tem microfone funcional | Use device físico Android (API 21+) |
| Hot reload (`r`) não pega mudança no Provider | Estado do `ChangeNotifier` cacheado | Use hot **restart** (`R` maiúsculo) |
| `flutter test` falha em CRLF warning | Windows line endings | Ignorar — não afeta testes |

---

## Autor

**Marcos Vinicius Muniz Arruda** — desenvolvimento completo (backend, frontend, arquitetura, conteúdo, design).

> O Anexo II original do projeto lista mais coautores; este repositório reflete o autor real do código.

---

*UniCatólica Tocantins — Engenharia de Software — 2025/2026*
