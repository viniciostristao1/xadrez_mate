# APRENDIZADOS — notas técnicas e gotchas do Mateflow

## 2026-09-19 — v0.18.0 (home compacta, 5 categorias sem rolagem)

- `_BigButton`: padding vertical 26→11, ícone 58→46, título 21→18, subtítulo
  13.5→12 com **`maxLines: 2` + ellipsis** (traduções longas não esticam o card),
  chevron 30→26. Espaço entre cards 18→8; logo 84→60; paddings do corpo menores.
- Altura total estimada ~500px + AppBar (~556) → cabe em 360x640.
- Teste de regressão em `home_test.dart`: viewport **360x640** e
  `getBottomLeft(find.byType(Card).last).dy <= 640` — falha se a home voltar a
  exigir rolagem em tela pequena.

## 2026-09-19 — v0.17.0 (modo Jogar: partida completa + precisão por lance)

### Mini-motor de IA (`lib/engine/ai.dart`, Dart puro)
- Busca **negamax + alfa-beta + quiescência** (só capturas/promoções, cap 4) com
  avaliação **material + PSQT** (Michniewski) e ordenação **MVV-LVA**.
- Níveis do rival: **1** = prof. 1 + 30% de lance aleatório + sorteio entre os
  lances a 150cp do melhor; **2** = prof. 2 + sorteio a 60cp; **3** = prof. 3
  determinístico.
- Bench na VPS: análise prof. 3 ≤ ~90ms (4 posições); escolha do rival ≤ ~40ms.
  Celular é mais lento, mas a análise roda 1× por lance do jogador (aceitável).
- GOTCHA de performance: `Board.makeMove` re-checa legalidade (regenera TODOS os
  legais → O(n²) na busca). Adicionado `Board.makeMoveUnchecked` para lances já
  validados. **Nunca** usar com lance de entrada não confiável.
- Truque da análise: com poda no root, só o lance que sobe o alfa tem score
  exato; o lance jogado (se não subiu) é re-buscado de janela cheia. Filho
  buscado com alpha=-inf e sem beta-cutoff é exato — por isso não precisa
  buscar TODOS os root moves de janela cheia.

### Precisão (metodologia da Lichess — `lichess.org/page/accuracy`)
- Win% = `50 + 50*(2/(1+exp(-0.00368208*cp)) - 1)`, cp limitado a ±1000
  (mate = ±1000). Fonte: `scalachess/eval.scala` (`WinPercent`).
- Precisão do lance = `103.1668100711649*exp(-0.04354415386753951*perda)
  - 3.166924740191411 + 1`, clamp [0,100] (o +1 é o bônus de incerteza).
  Fonte: `lila/AccuracyPercent.scala`.
- **Limiares** (mesmos Judgements da Lichess): perda **<10pp = bom**;
  **10–20 = médio** (Inaccuracy); **≥20 = ruim** (Mistake/Blunder).
- Casos de mate (de `lila/Advice.scala`): perdeu mate forçado → 30pp (ruim);
  12pp se, mesmo sem mate, seguia ganhando >999cp. Permitiu mate → 30pp (ruim);
  12pp se já estava perdido (≤-1000cp). Mate apenas adiado → 0 (segue bom).
- ⚠️ A avaliação é rasa (prof. 3): pega peça pendurada e tática de 1–2 lances;
  não é Stockfish e não deve ser vendida como verdade absoluta em finais.

### Tela do jogo (`lib/screens/jogo_screen.dart`)
- Snapshot (FEN + tamanhos das listas) **a cada lance do jogador**; "Voltar
  lance" restaura e desfaz junto a resposta do rival. `_generation` invalida
  respostas pendentes (undo, nova partida, dispose) — sem isso, "Nova partida"
  durante o delay do rival aplicava um lance no tabuleiro novo.
- O snapshot é sempre da vez do jogador → ao voltar, `_thinking = false`.
- Fim de jogo: mate (vitória/derrota), afogado, **50 lances**
  (`Board.isFiftyMoveDraw`) e **material insuficiente**
  (`Board.isInsufficientMaterial`, movido para o motor — regra "regras só no
  engine"). Sem repetição tripla nesta versão (ver IDEIAS).
- Testes: `rivalDelay` e `analysisDepth` injetáveis (10ms/1) — senão o teste
  fica lento/flaky. Teste de layout em **360x640** pega overflow de verdade
  (botões do card final → `Wrap`; textos → `Flexible`+ellipsis).
- GOTCHA: adicionar um 5º card na home empurrou "Defesa" para fora do viewport
  padrão (800x600) dos testes antigos → `app_bootstrap_test.dart` ganhou
  `physicalSize` 800x1500. Home é scrollável; o usuário rola no aparelho.

## 2026-09-05 — v0.16.0 (3 temas Cread preenchidos)

### Novos temas
- 3 paletas preenchidas adicionadas a `AppPalette.all`: `terracotaBloco` (#FFF5E6/#B5652E), `noiteEstrelada` (#0B1026/#FFD54F) e `escuroPremium` (#0A0A0A/#FFC857). `lightSquare/darkSquare` sólidos, `hint` 60% branco nos escuros, 40% preto no claro. Total 6 temas; seletor em `Configurações → Tema` sem migração (chave `app_theme`).
- Tabuleiros com borda `border` 3px e contraste alto; BigButtons `surface` sólido + ícone `accent`.

## 2026-09-05 — Fluxo de entrega (REGRA OBRIGATÓRIA)

### Sempre enviar link direto do APK após push
- **REGRA:** Toda nova versão (commit+push em `main`) DEVE terminar com o envio do **link direto perene** ao usuário: `https://github.com/viniciostristao1/xadrez_mate/releases/latest/download/xadrez-mate.apk`
- **Quando:** imediatamente após `git push origin main` (e, se for release versionada, após `scripts/release.sh vX.Y.Z` com CI verde).
- **Por quê:** usuário pediu explicitamente para nunca esquecer (2026-09-05). O link é o mesmo sempre (`latest/download/xadrez-mate.apk`), atualizado pelo `release.sh`.
- **Checklist:** `flutter analyze` + `flutter test` verdes → `git commit` + `git push` → `gh run watch` → `scripts/release.sh` → **enviar link**.
- Nunca deixar mudanças só locais; nunca terminar sem enviar o link.

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
