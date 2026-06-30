# Componentes reutilizáveis do Tekohá

> Biblioteca de widgets compartilhados entre features. Reutilizar daqui em
> vez de duplicar `ElevatedButton.icon(...)` em cada tela.

## Estrutura

```
lib/core/components/
├── buttons/      # TekohaPrimaryButton, TekohaSecondaryButton
├── badges/       # TekohaXpBadge, TekohaStatusPill
├── chips/        # TekohaCategoryChip
├── banners/      # TekohaErrorBanner
├── loaders/      # TekohaLoader, TekohaButtonLoader
└── texts/        # TekohaPurposeText, TekohaSectionLabel, TekohaEncouragementText
```

## Convenção de nomes

Todos os componentes começam com `Tekoha` — facilita autocomplete no IDE
("digita Tekoha + Ctrl+Space e vê a lista").

## Como adicionar componente novo

1. Crie o arquivo na pasta certa (ou crie nova pasta se for uma categoria nova).
2. Nomeie `Tekoha<Algo>` em PascalCase.
3. Adicione um comentário no topo explicando: o que é, onde usar, qual conceito
   científico fundamenta (quando aplicável — ver `plans/crispy-questing-dragonfly.md`).
4. Importe via barrel se preferir.

## Por que componentizar?

- **Consistência visual** — heurística Nielsen #4 (Consistência e padrões)
- **Carga cognitiva reduzida no desenvolvimento** — Sweller (1988)
- **Manutenibilidade** — mudar 1 botão = mudar 1 arquivo, não 8 telas
- **Testabilidade** — componente isolado é fácil de validar em isolamento
