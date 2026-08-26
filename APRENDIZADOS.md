# APRENDIZADOS — notas técnicas e gotchas do Mateflow

## 2026-08-26 — v0.11.0 (temas trocáveis em runtime)

### Arquitetura de temas
- `AppPalette` (imutável, `lib/theme/app_colors.dart`) guarda **todas** as
  cores de um tema. Dois temas: `AppPalette.amber` (padrão) e
  `AppPalette.crimson` (Carmesim & Ouro). Adicionar tema = mais uma const em
  `AppPalette.all` (o seletor lê essa lista).
- `AppColors` deixou de ser `static const` e virou **fachada de getters** que
  leem a paleta ativa (`AppColors.apply(palette)`). Os widgets seguem usando
  `AppColors.x` (regra do AGENTS intacta) — mudou só a implementação.
- `ThemeService` (singleton, espelha o `I18n`): `ValueNotifier` que a raiz
  escuta; `load()` aplica antes do 1º build; `setPalette()` aplica + notifica +
  persiste em `shared_preferences` (chave `app_theme`).
- `main.dart`: raiz agora é `ListenableBuilder` com
  `Listenable.merge([I18n.notifier, ThemeService.notifier])` → trocar tema
  reconstrói o `MaterialApp` (o `AppTheme.dark` é getter, recomputa as cores).

### GOTCHA — `const` + cor não-const
- Tornar `AppColors.x` getter quebra **todo** `const` que embutia uma cor
  (`invalid_constant`) e os defaults de parâmetro (`this.color = AppColors.x`
  → `non_constant_default_value`). Foram ~42 sites. Achados por
  `flutter analyze` (o `const` costuma ser multi-linha: `const TextStyle(` numa
  linha, `AppColors.x` na de baixo — grep de mesma-linha NÃO pega).
- Fix: remover o `const` do construtor que embute a cor; para defaults, tornar
  o parâmetro `Color?` e resolver `color ?? AppColors.x` no `build`.

## 2026-08-17 — v0.8.0

### Mate aleatório (surpresa)
- Modo `surpresa` no PuzzleScreen: AppBar "Mate aleatório", header sem o
  contador de lances e sem as barrinhas de progresso (revelariam o N).
- Rating: `registrarResolucao(surpresa: true)` multiplica o delta por
  `bonusSurpresa` (1.3). Teste verifica a razão exata (zera o
  SharedPreferences entre os registros para o `esperado` não variar).
- Fila: mate 2 + mate 3 de todos os níveis, embaralhada (`main.dart`).

### Layout Leipzig
- Removido o `PieceStyle.emoji` (glifos renderizam inconsistentes:
  contorno/preenchido/3D conforme a fonte do aparelho). A leitura da
  preferência salva usa `orElse: () => PieceStyle.merida` — quem tinha
  'emoji' salvo cai no padrão sem quebrar.
- Peças baixadas de `lichess1.org/assets/piece/leipzig/` (o
  raw.githubusercontent do lila deu rate-limit 429; o CDN funciona).
  viewBox ~50 → scale 1.18 como o Merida.

### Dica amarela
- Cores de dica no ChessBoard: `#FFD54F` (clara) / `#E0A800` (escura).

## 2026-08-17 — v0.7.0

### UI sem rolagem na tela de jogo
- O `SingleChildScrollView` fazia o usuário rolar para ver o card de
  sucesso. Troca por `Column` + `Expanded(LayoutBuilder)`: o tabuleiro é
  `SizedBox(min(maxWidth, maxHeight))` — nunca estoura; tudo fica visível.
- Histórico SAN virou `SingleChildScrollView` horizontal (`reverse: true`
  mostra o lance mais recente à esquerda).
- Feedback com altura fixa (`SizedBox(height: 46)`) para não "pular".
- Botão "Próximo" virou `_RoundIconButton(Icons.arrow_forward)` que aparece
  na row de ações quando `_solved` — os testes que procuravam o texto
  "Próximo problema" foram atualizados para `find.byIcon`.

### Pausa do cronômetro
- `_togglePause`: cancela/recria o `Timer.periodic`; `_paused` bloqueia o
  tick dentro do timer (dupla proteção). O chip do AppBar mostra
  "MM:SS pausado" com ícone de pausa.

### Sessão mista (mate 2/3)
- No seletor, `_mate == 0` = misto: fila montada com mate 2 + mate 3.
- Meta de tempo agora é a SOMA dos tempos-alvo de cada problema da fila
  (antes usava o alvo do primeiro — errado para sessões mistas).

## 2026-08-17 — v0.6.0

### Sessão de treino
- `SessionScreen` reusa o `PuzzleScreen` (key por `sessao-{id}-{index}`);
  o callback `onSolved` acumula estatísticas; o avanço ocorre SÓ no botão
  "Próximo problema" (senão contaria duas vezes — o `onNext` apenas avança).
- Meta de tempo da sessão = soma dos tempos-alvo (10/25/60 por problema).
- `findAncestorStateOfType` no seletor para chamar `_startSession` do app.

### Gráfico de evolução
- `RatingChart` (CustomPainter): normaliza pelo min/max do histórico,
  linha de referência em 1000, área com gradiente. Sem dependência externa.
- Histórico persistido no `shared_preferences` como JSON
  `[{r: rating, t: timestamp}]` — carregado com tolerância a corrupção.

## 2026-08-17 — v0.5.0

### Cronômetro / dica / rating
- **Timer** precisa de `dispose()` cancelando (`_timer?.cancel()`) — senão
  vaza em testes/widgets; `_resetState()` sem setState p/ uso no initState,
  `_reset()` = `setState(_resetState)` p/ botões.
- **Testes com Timer.periodic**: `pumpAndSettle` avança o relógio fake — pode
  disparar 1 tick do cronômetro entre o tap e a assert (elapsed 0 → 1). Não
  asserte `elapsed == 0` após refresh; asserte `lessThan(antes)`.
- **Rating** (`lib/services/rating_service.dart`): Elo com resultado contínuo
  [0.15, 1.0]; K=24; esperado = 1/(1+10^((rp-rj)/400)); tempo-alvo 10/25/60s;
  erros 0.8^n; dicas 0.6^n. Singleton com `ValueNotifier` p/ a home atualizar.
  Testes em `test/rating_test.dart` (mock de SharedPreferences).
- **Rating por problema**: todos os problemas do banco têm `rating` (real dos
  Lichess ou estimado por (mate, nível) no `puzzle_gen.py`).
- **Dica**: `Board.moveFromUci()` (parser UCI→Move legal) + `sanFor()` para o
  texto; destaque verde no tabuleiro (`hintFrom`/`hintTo` no ChessBoard).
- **Botão refazer quebrado**: o `_reset` antigo mutava o estado SEM setState —
  a UI não rebuildava. Fix: `setState(_resetState)`.

## 2026-08-17 — v0.4.0

### Assinatura de release (o bug do "pacote em conflito")
- O `flutter create` padrão assina RELEASE com a chave **debug**; no GitHub
  Actions o debug keystore é gerado novo a cada execução → **assinatura
  diferente a cada build** → o Android recusa instalar por cima
  ("pacote em conflito").
- **Correção**: keystore de upload própria (`app/android/app/upload-keystore.jks`,
  alias `upload`, gitignored) com a senha em `key.properties` (gitignored) e o
  backup nos secrets do GitHub (`KEYSTORE_BASE64` + `KEYSTORE_PASSWORD` — o
  workflow já decodifica e injeta). `build.gradle.kts` usa `signingConfig
  release` se `key.properties` existir; sem ele, cai em debug (tolerante).
- ⚠️ A troca de assinatura exige **desinstalar o app antigo UMA vez** (limitação
  do Android); depois, atualizações com o mesmo versionCode crescente instalam
  por cima.
- **Guardar backup da keystore** — sem ela, não dá para atualizar por cima.
  Fonte da verdade: o secret `KEYSTORE_BASE64` no repo.

### Renome para Mateflow
- Nome de exibição: `android:label="Mateflow"` no manifest + `title` do
  MaterialApp. `applicationId` (`com.vinyapps.xadrez_mate`) NÃO muda — mudar
  criaria outro pacote (novo conflito).

## 2026-08-17 — v0.2.0

### Importação do banco do Lichess (tools/import_lichess.py)
- **FORMATO do CSV (pegadinha central)**: "FEN is the position before the
  opponent makes their move. The position to present to the player is after
  applying the first move to that FEN. The second move is the beginning of
  the solution." Ou seja: o JOGADOR controla o lado OPOSTO ao do FEN; a
  posição do puzzle = `FEN + moves[0]`; os lances do jogador são
  `moves[1], moves[3], ...` (índices ímpares). Importar o FEN direto gera
  0 aceitos.
- **Bug do nó terminal**: ao percorrer a linha do Lichess na árvore, o
  verify() devolvia o NÓ TERMINAL (só as chaves do último lance) em vez da
  RAIZ — o validador pegou: chaves do nó profundo ilegais na posição raiz.
  Devolver `sol["tree"]` (a raiz completa).
- **Níveis por terços de rating** dentro de cada categoria (não thresholds
  globais): mate1 nível3 começa ~900, mate3 nível3 ~1600 — o rating é relativo
  à categoria.
- O lichess "mateIn1" permite VÁRIOS lances de mate (todas são chaves) —
  compatível com nossa árvore (todas as chaves de mate aceitas).

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
