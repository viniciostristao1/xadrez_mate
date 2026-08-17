# ♞ Xeque-Mate

Treinador de **problemas de xeque-mate** para Android: mate em **1, 2 ou 3
lances**, com tabuleiro interativo que marca as casas legais de cada peça,
aviso imediato de lance errado e xeque-mate ao final.

- **318 problemas verificados** em **3 níveis** (Fácil / Médio / Difícil):
  198 são reais, de partidas (banco oficial do Lichess, CC0, com rating de
  dificuldade) — cada um com a árvore completa de solução (todas as respostas
  legais do oponente têm continuação exata).
- **3 layouts de peças**: Merida, Cburnett e Emoji (escolha salva).
- **Regras de xadrez puras**: cavalo só faz "L", cravada não expõe o rei,
  roque não atravessa xeque, en passant, promoção com escolha de peça.
- **Feedback imediato**: lance errado avisa na hora e volta ao último lance
  correto; resolver todos os lances mostra "Xeque-mate! 🎉".

## Instalar

Baixe o APK mais recente (link perene):

```
https://github.com/viniciostristao1/xadrez_mate/releases/latest/download/xadrez-mate.apk
```

## Desenvolvimento

- App: `app/` (Flutter 3.44.7, Dart 3.12.2).
- Motor de xadrez puro: `app/lib/engine/chess.dart` (969 testes, sendo 935
  contra referência do python-chess).
- Banco de problemas: gerado e validado em `tools/` (python-chess).
- Build do APK: GitHub Actions (nuvem). Ver `INICIO.md`/`AGENTS.md`.
