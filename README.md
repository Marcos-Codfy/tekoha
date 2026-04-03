# Tekoha

Aplicativo mobile educacional para ensino gamificado da lingua **Nheengatu**.

> *Tekoha* - palavra guarani que significa "o lugar onde se vive a cultura".

## Equipe

| Papel | Pessoa | Responsabilidade |
|-------|--------|-----------------|
| Backend + Arquitetura | Marcos Vinicius | Firebase, Airtable, logica de XP |
| Frontend + UX/UI | Jeovanna Fonseca | Telas, navegacao, componentes visuais |
| Dados + Linguistica | Emilly Vitoria | Conteudo no Airtable, curadoria Nheengatu |

## Stack Tecnologica

- **Flutter + Dart** - framework mobile (Android/iOS)
- **Android Studio** - IDE principal
- **Firebase Auth + Firestore** - autenticacao e banco de dados
- **Airtable** - gerenciamento de conteudo das licoes
- **GitHub** - controle de versao

## Como rodar o projeto

1. Clone o repositorio
2. Peca ao Marcos o arquivo `.env` e o `google-services.json`
3. Coloque o `.env` na raiz do projeto e o `google-services.json` em `android/app/`
4. Execute: `flutter pub get`
5. Execute: `flutter run`

## Estrutura de Pastas
```
lib/
├── core/          # Compartilhado: cores, tema, utilitarios
├── data/          # Marcos: models, services, repositories
└── presentation/  # Jeovanna: screens, widgets, providers
```

---
*UniCatolica Tocantins - Engenharia de Software - 2025/2026*