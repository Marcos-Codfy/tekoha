# Tekoha

Aplicativo mobile educacional para ensino gamificado da língua **Nheengatu**.

> *Tekoha* — palavra guarani que significa "o lugar onde se vive a cultura".

---

## Sumário

- [Status atual](#status-atual)
- [Stack tecnológica](#stack-tecnológica)
- [Pré-requisitos](#pré-requisitos)
- [Como rodar o projeto](#como-rodar-o-projeto)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Arquitetura](#arquitetura)
- [Conteúdo no Airtable](#conteúdo-no-airtable)
- [Feature flags](#feature-flags)
- [Workflow de contribuição](#workflow-de-contribuição)
- [Troubleshooting](#troubleshooting)
- [Equipe](#equipe)

---

## Status atual

O app está com a **Sprint 3** concluída. Funcionalidades já entregues:

- **Bottom navigation** com 4 abas: Home, Prática, Cultura e Perfil — `IndexedStack` preserva estado de cada aba.
- **Autenticação** com Firebase Auth: telas de Splash, Login e Cadastro implementadas (atualmente desativadas por uma feature flag — ver [Feature flags](#feature-flags)).
- **Aba Prática**: lista os módulos vindos do Airtable, abre lição com fluxo de quiz mínimo, cache em memória entre navegações.
- **Aba Cultura**: chips de categoria (História, Cosmologia, Hábitos, Curiosidades) com listagem de cards curtos vindos do Airtable, com pull-to-refresh e cache por categoria.
- **Permissões Android** para `speech_to_text` (`RECORD_AUDIO` + `INTERNET`) já configuradas — `minSdk = 21`.

---

## Stack tecnológica

| Camada | Ferramenta |
|---|---|
| Framework | Flutter `>=3.0.0 <4.0.0` + Dart |
| Plataforma alvo | Android (iOS configurável, não testado) |
| Estado | `provider` (`ChangeNotifier`) |
| Backend de auth | Firebase Auth + Cloud Firestore |
| CMS de conteúdo | Airtable (REST API) |
| HTTP | pacote `http` |
| Variáveis de ambiente | `flutter_dotenv` |
| IDE recomendada | Android Studio |

---

## Pré-requisitos

1. **Flutter SDK** 3.0 ou superior — [instruções oficiais](https://docs.flutter.dev/get-started/install).
2. **Android Studio** com o plugin do Flutter instalado.
3. **Emulador Android** rodando ou um dispositivo físico em modo desenvolvedor.
4. Acesso aos arquivos de configuração privados (peça ao Marcos):
   - `.env` — chaves do Airtable e Firebase
   - `google-services.json` — config do Firebase para Android
   - `firebase_options.dart` (opcional, gerado pelo `flutterfire configure`)

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

O app abre direto na aba **Home** porque a flag `kBypassAuth` está ligada por padrão (ver [Feature flags](#feature-flags)).

### Conteúdo esperado do `.env`

```env
# Airtable
AIRTABLE_API_KEY=...
AIRTABLE_BASE_ID=...
AIRTABLE_TABLE_MODULES=Modules
AIRTABLE_TABLE_LESSONS=Lessons
AIRTABLE_TABLE_WORDS=Words

# Firebase
FIREBASE_API_KEY=...
FIREBASE_PROJECT_ID=...
FIREBASE_APP_ID=...
```

> **Nota:** as variáveis `AIRTABLE_TABLE_*` no `.env` hoje são lidas por chaves diferentes no código (`AIRTABLE_MODULES_TABLE` etc.). O serviço cai para os fallbacks `Modules`, `Lessons`, `Words`, `CultureContent`, que coincidem com os nomes reais das tabelas — então tudo funciona. Há uma issue aberta para alinhar essa nomenclatura.

---

## Estrutura de pastas

```
lib/
├── core/                        # Compartilhado entre todas as features
│   ├── constants/               # app_colors, app_flags, app_routes
│   ├── theme/                   # app_theme (Material 3, paleta Urucum)
│   └── utils/                   # quiz_builder, text_utils, validators
│
├── data/                        # Camada de dados (Marcos)
│   ├── models/                  # module, lesson, word, culture_content
│   ├── repositories/            # content_repository (contrato abstrato)
│   └── services/                # airtable_service (impl. concreta)
│
├── presentation/                # UI + estado (Jeovanna)
│   ├── providers/               # auth_provider, content_provider
│   ├── screens/
│   │   ├── auth/                # login, register
│   │   ├── splash/              # splash inicial
│   │   ├── home/                # tela inicial pós-login
│   │   ├── practice/            # aba de módulos/lições
│   │   ├── lesson/              # tela de exercícios da lição
│   │   ├── culture/             # aba Cultura (chips + cards)
│   │   ├── profile/             # aba Perfil
│   │   └── main_scaffold.dart   # casca com bottom nav
│   └── widgets/                 # module_card, culture_card, error_view
│
├── firebase_options.dart        # Gerado pelo flutterfire — NÃO commitado
└── main.dart                    # Ponto de entrada
```

---

## Arquitetura

Clean Architecture simplificada com fluxo de dependência unidirecional:

```
┌────────────────┐
│  Screen (UI)   │  presentation/screens/
└───────┬────────┘
        │  Consumer<ContentProvider>
        ▼
┌────────────────┐
│    Provider    │  presentation/providers/
└───────┬────────┘  ChangeNotifier + cache em memória
        │  chama _repository.fetchXxx()
        ▼
┌────────────────┐
│   Repository   │  data/repositories/  (abstract)
└───────┬────────┘  Contrato — não conhece a fonte
        │  implementado por
        ▼
┌────────────────┐
│    Service     │  data/services/airtable_service.dart
└────────────────┘  Conversa com Airtable REST
```

**Regra de ouro:** camada de cima nunca importa direto de camada que não seja a imediatamente abaixo. Quer trocar Airtable por Firebase? Basta criar `FirebaseContentService implements ContentRepository` e trocar a injeção em `main.dart`.

**Tratamento de erros:** toda falha do `Service` é convertida em `ContentException` com `userMessage` em português. A UI exibe direto sem precisar saber de HTTP ou Airtable.

---

## Conteúdo no Airtable

O conteúdo de aprendizado vive numa base do Airtable com 4 tabelas:

| Tabela | Conteúdo | Campos principais |
|---|---|---|
| `Modules` | Trilhas de aprendizado | `name`, `description`, `language`, `order`, `is_active` |
| `Lessons` | Lições dentro de um módulo | `title`, `module` (link), `order`, `xp_reward` |
| `Words` | Palavras de uma lição | `nheengatu`, `translation`, `pronunciation`, `cultural_note`, `lesson` (link), `order` |
| `CultureContent` | Cards da aba Cultura | `language`, `category`, `title`, `body`, `order`, `is_active` |

**Categorias de `CultureContent`** (single select, valores em inglês minúsculo):
`history`, `cosmology`, `habits`, `curiosities`.

> Linked records do Airtable retornam IDs no JSON, **não nomes**. Por isso `fetchLessonsByModule` e `fetchWordsByLesson` filtram no código em vez de usar `filterByFormula` no servidor. O comentário detalhando isso está em [`airtable_service.dart`](lib/data/services/airtable_service.dart).

---

## Feature flags

Definidas em [`lib/core/constants/app_flags.dart`](lib/core/constants/app_flags.dart).

| Flag | Padrão | Efeito |
|---|---|---|
| `kBypassAuth` | `true` | Pula Splash, Login e Cadastro — abre direto no `MainScaffold`. Util durante desenvolvimento. |

Para reativar o fluxo de login real, mude `kBypassAuth` para `false` e faça hot **restart** (R no terminal, não r minúsculo).

---

## Workflow de contribuição

### Branches

```
main                              # protegida, só recebe merge via PR
├── feat/<feature>                # nova funcionalidade
├── fix/<bug>                     # correção
├── refactor/<area>               # refatoração sem mudar comportamento
├── chore/<tarefa>                # build, deps, IDE config
└── docs/<topico>                 # documentação
```

### Conventional Commits

Mensagens em **português**, no **imperativo**, prefixadas:

```
feat: adiciona aba Cultura com chips de categoria
fix(airtable): filtra licoes no codigo para evitar problema com linked fields
refactor: desacopla provider de service
chore: atualiza configuracoes do IDE
docs: atualiza README com instrucoes de setup
```

### Pull Requests

- Sempre via PR para `main`, nunca commit direto.
- Antes de abrir: rode `flutter analyze` — zero erros novos nos arquivos modificados.
- Antes de mergear: teste localmente com `flutter run` os fluxos afetados.
- PR mergeado pode ser via **squash** ou **merge commit** (o que fizer mais sentido para o histórico).

---

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| `Configuracao do Airtable nao encontrada` | `.env` ausente ou sem `AIRTABLE_API_KEY`/`AIRTABLE_BASE_ID` | Confirme que o arquivo está na raiz e tem as duas chaves preenchidas |
| `Token do Airtable invalido ou expirado` | Token expirou ou está errado | Peça um token novo ao responsável pela base |
| `Base ou tabela "X" nao encontrada` | Nome da tabela no Airtable diferente do código | Confirme nomes reais: `Modules`, `Lessons`, `Words`, `CultureContent` |
| App trava no boot no Chrome | Firebase web não configurado | Rode `flutterfire configure --platforms=web` ou ignore (mensagem é só aviso) |
| `speech_to_text` não reconhece fala | Emulador não tem microfone funcional | Use device físico Android (API 21+) |
| Hot reload (`r`) não pega mudança no Provider | Estado do `ChangeNotifier` cacheado | Use hot **restart** (`R` maiúsculo) |

---

## Equipe

| Papel | Pessoa | Responsabilidade |
|---|---|---|
| Backend + Arquitetura | **Marcos Vinicius** | Firebase, Airtable, lógica de XP, camada `data/` |
| Frontend + UX/UI | **Jeovanna Fonseca** | Telas, navegação, componentes visuais, camada `presentation/` |
| Dados + Linguística | **Emilly Vitória** | Conteúdo no Airtable, curadoria Nheengatu |

---

*UniCatólica Tocantins — Engenharia de Software — 2025/2026*
