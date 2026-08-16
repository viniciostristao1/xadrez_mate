# APRENDIZADOS — notas técnicas e gotchas do Xeque-Mate

## 2026-08-16 — v0.1.0

### Motor de xadrez (Dart)
- **Geração de lances legais**: gere pseudo-lances e filtre "rei de quem move
  não pode ficar em xeque" usando o **mover** (turno ANTES do lance), não o
  turno depois — bug clássico que invertia a filtragem (todos os lances com
  xeque eram descartados).
- **Cavalo/rei**: use deltas `(df, dr)` com verificação de fileira E coluna —
  offsets numéricos (17/15/10/6…) quebram nas bordas (wrap de fileira).
- **Roque**: no `makeMove`, a **torre** vai para `to-1`/`to+1` (não o rei!);
  o undo precisa restaurar a torre na casa original ANTES de limpar as casas
  intermediárias.
- **Ataque de peão**: branco ataca (f±1, r-1); preto (f±1, r+1) — fácil de
  inverter.
- **En passant**: o peão capturado fica ATRÁS do destino (`to ± 8`); no undo,
  restaurar nessa casa e limpar o destino.
- **SAN de promoção**: `d8=Q+` — sufixo de xeque/mate depois da peça.

### Validação cruzada (a técnica que salva)
- Gere uma **referência externa** (python-chess) com lances legais de posições
  (banco + casos especiais + jogos aleatórios) e compare como conjunto no
  teste Dart. Pegou TODOS os bugs acima de uma vez.
- O gerador do banco usa a mesma biblioteca (python-chess) para a árvore de
  solução — a árvore cobre TODAS as respostas legais do oponente; o validador
  (`tools/validate_db.py`) percorre a árvore inteira conferindo legalidade,
  cobertura e xeque-mate.

### Geração de problemas
- Posições aleatórias puras têm baixa densidade de mate em ≤3 (24/4000
  tentativas). **Geração construtiva** (rei no canto + escudos + atacante que
  dá xeque + defensor) rende muito mais (52 mate-1 em ~80 tentativas).
- O espelhamento (`board.mirror()` do python-chess) **dobra** a variedade e
  balanceia brancas/pretas a jogar (60/60).
- Categoria exata: o solver tenta profundidades 1, 2, 3 **em ordem** e para na
  primeira que resolve — posição com mate em 1 nunca entra como mate em 2.

### App
- `PuzzleScreenState` é público (não `_...`) para testes de fluxo via
  `tester.state<>()`; expor `@visibleForTesting` getters (board, node, solved).
- Viewport de teste padrão (800x600) é menor que o tabuleiro → definir
  `tester.view.physicalSize` + `devicePixelRatio = 1.0` (e reset no teardown).
- `flutter_launcher_icons` gera os mipmaps do launcher (ícone com cavalo ♞).
- Peças Merida/Cburnett: baixadas de lichess (`lila/piece/merida`) e Wikimedia
  Commons (`Chess_*t45.svg`); Emoji usa glifos Unicode (♞/♘) com sombra.

### FEN (gotcha do teste)
- FENs inventadas em testes deram dor de cabeça (peão no e5 já jogado, bispo
  f1 já movido, peões bloqueando a diagonal do bispo). Prefira FENs **do banco
  validado** ou monte com cuidado e confira o roundtrip `fen -> parse -> fen`.
