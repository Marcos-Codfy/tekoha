<div align="center">

# Tekohá

**Tecnologia como instrumento de preservação de línguas indígenas.**

Aplicativo mobile de ensino gamificado do **Nheengatu** — a língua geral amazônica —
desenvolvido como pesquisa de Iniciação Científica em Engenharia de Software.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase&logoColor=black)
![Tests](https://img.shields.io/badge/testes-209%20passing-2E7D32)
![Arquitetura](https://img.shields.io/badge/arquitetura-Clean%20Architecture-B5451B)

> *Tekohá* — palavra de origem guarani: **"o lugar onde se vive a cultura"**.

</div>

---

## Sumário

- [O projeto](#o-projeto)
- [Por que isso importa](#por-que-isso-importa)
- [Funcionalidades](#funcionalidades)
- [Pedagogia baseada em oralidade](#pedagogia-baseada-em-oralidade)
- [Design fundamentado em ciência](#design-fundamentado-em-ciência)
- [Arquitetura](#arquitetura)
- [Stack](#stack)
- [Como rodar](#como-rodar)
- [Qualidade e testes](#qualidade-e-testes)
- [Ética e cuidado cultural](#ética-e-cuidado-cultural)
- [Referências](#referências)
- [Direitos autorais e uso](#direitos-autorais-e-uso)
- [Autor](#autor)

---

## O projeto

O Tekohá é o artefato de uma pesquisa de **Iniciação Científica** (Centro Universitário
Católica do Tocantins — UniCatólica, Edital 02/2025, linha de pesquisa **Direitos
Humanos**) que investiga uma pergunta central:

> **A tecnologia mobile pode ser um meio efetivo de preservação e revitalização de
> línguas indígenas brasileiras?**

O MVP ensina Nheengatu por uma trilha de aprendizado gamificada, com exercícios
construídos a partir do **som** (ouvir, reconhecer e falar), conteúdo cultural
contextualizado e progresso persistido por usuário. O método é deliberadamente
**replicável**: a arquitetura separa o conteúdo (CMS) do código, de modo que a mesma
base pode servir a outras línguas em risco.

O resultado da pesquisa será submetido à **Jornada de Iniciação Científica** da
UniCatólica, com avaliação heurística conduzida por docentes (10 Heurísticas de
Nielsen, escala de severidade 0–4).

## Por que isso importa

- Antes da colonização, o território brasileiro tinha **mais de 1.200 línguas
  indígenas**. Hoje restam **menos de 180**, a maioria em risco de desaparecimento
  (UNESCO).
- A Constituição Federal reconhece às comunidades indígenas o direito às suas
  línguas e processos próprios de aprendizagem (**CF/88, art. 210 §2º e art. 231**)
  — mas o distanciamento entre o direito formal e a prática é um dos motores desta
  pesquisa.
- O Nheengatu — "língua boa", descendente do Tupinambá — já foi a língua mais falada
  do Brasil e hoje resiste com 8 a 14 mil falantes no Alto Rio Negro, onde é língua
  cooficial de São Gabriel da Cachoeira (AM) desde 2002.

Cada palavra praticada no app é uma palavra que continua viva.

## Funcionalidades

- **Trilha de aprendizado por etapas** — 3 módulos temáticos (Cumprimentos,
  Apresentação, Natureza), cada um dividido em 4 etapas curtas com destravamento
  progressivo. Progressão pedagógica "da raiz ao composto" (aprende-se *puranga*
  antes de *puranga ara*).
- **Exercícios orais** — ouvir e escolher a tradução, ouvir e reconhecer a palavra,
  **ouvir e repetir em voz alta** (reconhecimento de fala com correspondência
  fonética tolerante).
- **Apresentação antes da cobrança** — toda palavra nova abre com uma ficha (grafia,
  áudio, pronúncia, tradução e nota cultural) antes de qualquer exercício.
- **Contas de usuário** — cadastro e login (Firebase Auth) com sessão persistente;
  XP, sequência de dias, etapas e conquistas salvos por usuário no Cloud Firestore.
- **Gamificação fundamentada** — XP variável (8/10/12), 10 conquistas com critérios
  progressivos, celebração de desbloqueio e galeria com metas visíveis.
- **Aba Cultura** — cards sobre história, hábitos e curiosidades da língua,
  gerenciados como conteúdo editorial no Airtable.
- **Resiliência** — cache de conteúdo, pré-download de áudios, tratamento tipado de
  erros com mensagens úteis e degradação graciosa sem conexão.

## Pedagogia baseada em oralidade

As línguas indígenas amazônicas são línguas de **tradição oral** — a escrita
padronizada do Nheengatu é uma convenção acadêmica recente. Por isso o app não
avalia escrita: **todo exercício parte do som**, e o texto aparece apenas como apoio
visual. A sequência de cada palavra segue o ciclo *apresentar → reconhecer → produzir*:

1. **Ficha da palavra** (input compreensível — Krashen)
2. **Ouvir e escolher a tradução** (compreensão)
3. **Ouvir e reconhecer a grafia** (associação som-símbolo)
4. **Ouvir e repetir em voz alta** (produção oral)
5. **Quiz de fixação** (recuperação ativa — Testing Effect)

## Design fundamentado em ciência

Cada decisão de UX/UI do Tekohá é rastreável a literatura revisada — requisito da
pesquisa e diferencial do artefato. Alguns exemplos:

| Decisão no app | Fundamentação |
|---|---|
| XP variável 8/10/12 por acerto | Reforço variável — Skinner (1953) |
| Etapas curtas de 2–3 palavras | Chunking — Miller (1956); Carga Cognitiva — Sweller (1988) |
| "Faltam 2 etapas pra fechar o módulo" | Goal-Gradient — Kivetz et al. (2006) |
| Primeira conquista em ~5 minutos de uso | Endowed Progress — Nunes & Drèze (2006) |
| Celebração ao fim de etapa e módulo | Peak-End Rule — Kahneman et al. (1993) |
| Conquistas travadas visíveis em silhueta | Efeito Zeigarnik (1927); Antin & Churchill (2011) |
| Palavra nova apresentada antes de cobrar | Scaffolding — Wood, Bruner & Ross (1976); Krashen (1982) |
| Streak sem punição ao quebrar | Control-Value Theory — Pekrun (2006) |
| Paleta de pigmentos naturais amazônicos | Color Psychology — Elliot & Maier (2014) |
| Máximo de 4 alternativas por exercício | Lei de Hick-Hyman; consistência — Nielsen H4 |

## Arquitetura

**Clean Architecture** organizada por feature, com dependências unidirecionais:

```
lib/
├── core/          # tema, cores, componentes reutilizáveis, rede, erros, serviços
├── di/            # composition root (get_it)
└── features/
    ├── auth/          # login, cadastro, sessão
    ├── practice/      # módulos e trilha de etapas
    ├── lesson/        # execução da lição (máquina de estado própria)
    ├── progress/      # XP, streak, conquistas — persistência Firestore
    ├── achievements/  # definições de conquistas (CMS)
    ├── culture/       # conteúdo cultural
    ├── home/          # dashboard
    └── profile/       # identidade, estatísticas, galeria de conquistas
        └── (cada feature: domain / data / presentation)
```

Padrões aplicados: **Repository** (contratos no domínio, implementações trocáveis),
**UseCase**, **DTO + Mapper** (o domínio não conhece Airtable/Firestore),
**Result tipado** (`Result<S, Failure>` com hierarquia selada de falhas em PT-BR),
**Service Locator** (`get_it`) e **ChangeNotifier por feature**. O estado do usuário
tem uma única fonte de verdade (`UserProgressProvider`), persistida com escrita
tolerante a falhas de rede.

## Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3 / Dart 3 (Android; iOS configurável) |
| Estado | `provider` (ChangeNotifier) |
| Injeção de dependência | `get_it` |
| Autenticação | Firebase Auth (e-mail/senha, sessão persistente) |
| Persistência por usuário | Cloud Firestore (regras de segurança per-user) |
| CMS de conteúdo | Airtable REST API |
| Áudio | `audioplayers` com pré-download e cache local |
| Reconhecimento de fala | `speech_to_text` (locale pt-BR como aproximação fonética) |
| Testes | `flutter_test` + `mocktail` |

## Como rodar

Pré-requisitos: Flutter SDK 3+, Android Studio (ou VS Code) e um dispositivo/emulador
Android (API 21+).

```bash
git clone https://github.com/Marcos-Codfy/tekoha.git
cd tekoha
flutter pub get
flutter run
```

O projeto depende de credenciais privadas que **não** estão no repositório
(`.gitignore`): `.env` na raiz (`AIRTABLE_API_KEY`, `AIRTABLE_BASE_ID`),
`android/app/google-services.json` e `lib/firebase_options.dart` (gerado pelo
`flutterfire configure`). Sem eles o app compila, mas exibe o aviso de configuração
ausente ao carregar conteúdo.

## Qualidade e testes

```bash
flutter analyze   # zero issues
flutter test      # 209 testes unitários, de widget e de integração
```

A suíte cobre a máquina de estado da lição (XP, tentativas, fala), os geradores de
exercícios e da trilha (funções puras com seed determinística), o cálculo de streak
por dia de calendário, o avaliador de conquistas, os repositórios (com fontes
mockadas) e os fluxos de UI das abas principais. Todo o histórico segue
**Conventional Commits**, com integração via pull request.

## Ética e cuidado cultural

Este projeto trata cultura indígena como patrimônio vivo, não como matéria-prima:

- **Ortografia acadêmica** — todo o conteúdo em Nheengatu segue a convenção de
  Navarro (USP): *k* (não *c/qu*), *u* (não *w*), *i* (não *y*).
- **Sem apropriação visual** — a identidade usa cores de pigmentos naturais
  amazônicos (urucum, jenipapo, caulim), sem reproduzir grafismos étnicos
  identitários (Carneiro da Cunha, 2009).
- **Voz sintetizada declarada** — os áudios do MVP são gerados por síntese de voz a
  partir de guias fonéticos, como aproximação assumida; a substituição por gravações
  com falantes nativos, em parceria com as comunidades, é trabalho futuro
  prioritário.
- **Cosmologia fora do escopo** — narrativas cosmológicas foram deliberadamente
  excluídas do app: contá-las sem consulta e consentimento das comunidades
  detentoras seria eticamente inadequado. A categoria só voltará mediante
  co-curadoria comunitária.
- **Conteúdo autoral** — as notas culturais e microcopy do app foram escritas para
  este projeto com base nas fontes abaixo, sem reprodução literal de material de
  terceiros.

## Referências

Principais fontes do conteúdo linguístico e cultural (referências completas no
material da pesquisa):

- **NAVARRO, E. A.** *Curso de Língua Geral (Nheengatu ou Tupi Moderno): a língua
  das origens da civilização amazônica.* São Paulo, 2011 — base do vocabulário e da
  convenção ortográfica.
- **Tese de doutorado (USP)** — dicionário Nheengatu–Português: fonte lexicográfica
  de apoio.
- **Gramática e fonologia do Nheengatu** (literatura acadêmica especializada) —
  apoio às notas de pronúncia.
- **etnolinguistica.org** — acervo digital de linguística das línguas sul-americanas.
- **GerardiTupi / Zenodo (2021)** — base de dados lexical Tupi-Guarani.
- **Museu Paraense Emílio Goeldi** — documentação sobre línguas amazônicas.
- **UNESCO** — Atlas das línguas do mundo em perigo.

A fundamentação de UX/UI e gamificação (Deci & Ryan; Skinner; Kahneman; Kivetz;
Nunes & Drèze; Sweller; Miller; Krashen; Wood, Bruner & Ross; Zeigarnik; Antin &
Churchill; Hamari; Elliot & Maier; Nielsen; Pekrun; Carneiro da Cunha) integra o
referencial teórico do artigo da pesquisa.

## Direitos autorais e uso

© 2025–2026 Marcos Vinicius Muniz Arruda. Todos os direitos reservados.

Código e conteúdo publicados para fins de **avaliação acadêmica e portfólio**. O
conteúdo linguístico deriva de fontes acadêmicas citadas; as notas culturais e
textos da interface são autorais. Não é concedida licença de reprodução ou uso
comercial sem autorização expressa do autor. Este repositório não representa as
comunidades falantes de Nheengatu nem reivindica titularidade sobre a língua ou
sobre expressões culturais indígenas.

## Autor

**Marcos Vinicius Muniz Arruda** — pesquisa, design e desenvolvimento.

Estudante de Engenharia de Software · Centro Universitário Católica do Tocantins
(UniCatólica) · Iniciação Científica 2025/2026, linha de pesquisa Direitos Humanos.

[github.com/Marcos-Codfy](https://github.com/Marcos-Codfy)

---

<div align="center">

*Tekohá — o lugar onde se vive a cultura.*

</div>
