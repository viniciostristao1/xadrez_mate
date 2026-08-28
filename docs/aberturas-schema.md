# Aberturas — Schema definitivo (golden template = Italiana) — CONGELADO

> **Contrato de dados.** Não altera arquitetura/código. `OpeningEngine/Data/Lesson` genéricos consomem este JSON. Italiana é referência. Outras 11 devem seguir exatamente este formato. **Máx. conteúdo, zero lógica.**

## Arquivo

`app/assets/aberturas.json` → `{ "aberturas": [ Abertura ×12 ] }` — UTF-8, uma entrada por abertura, `id` único 1..12, ordem = ordem do MVP.

## Abertura (top-level)

| Campo | Tipo | Obrig. | Regras |
|---|---|---|---|
| `id` | int | ✅ | 1..12, coincide com MVP: 1 Italiana, 2 Ruy Lopez, 3 London, 4 Gambito Dama, 5 Siciliana, 6 Francesa, 7 Caro-Kann, 8 Índia Rei, 9 GDR, 10 Nimzo, 11 Inglesa, 12 Réti |
| `nome` | string | ✅ | Nome curto exato do MVP |
| `eco` | string | ✅ | Código ECO curto (ex `C50`, `C60`, `D00`…) |
| `cor` | enum string | ✅ | `brancas` \| `pretasVsE4` \| `pretasVsD4` \| `flanco` — **case-sensitive** como no `AberturaCor` |
| `descricaoCurta` | string | ✅ | 1 frase curta (≤120c), ideia central |
| `fenInicial` | FEN | ✅ | Posição inicial do fluxo (geralmente inicial `rnbqkbnr/... w KQkq - 0 1`) — deve ser FEN válida, lado a jogar coerente |
| `fenTabiya` | FEN | ✅ | Tabiya principal (posição-chave após linha principal curta) — FEN válida, branca/preta a jogar conforme abertura |
| `steps` | array(13) | ✅ | Exatamente 13 objetos `AberturaStep` na ordem do template (ver § Steps) |
| `plano` | Plano | ✅ | Objeto `AberturaPlano` — obrigatório, define transição para meio-jogo |
| `botTeorico` | string[] UCI | ✅ | ≥4 UCIs, linha principal completa do início até transição (intercala brancas/pretas, ex Italiana: `e2e4 e7e5 g1f3 b8c6 f1c4 f8c5...`) |
| `botAdaptativo` | string[] UCI | ✅ | ≥4 UCIs, mesma estrutura mas com desvio da teoria (`...d7d6/h7h6/c8g4`) para forçar adaptação |

## FEN — formato

`peças w/b direitosFEN - halfmove fullmove` — validada com `python-chess`. `direitos` = `KQkq` ou `-`, `ep = -` se não houver. `turn` (`w`/`b`) deve corresponder a quem joga na posição exibida (Tabiya brancas→`w`, etc). Todas FENs de `fen`, `fenInicial`, `fenTabiya`, `fenTransicao` devem ser legais e alcançáveis.

## Sequência de lances

`sequencia: [{uci,san,porQue}]`
- `uci`: `e2e4`, `g1f3`, `e7e8q` — 4..5 chars, validado `board.moveFromUci != null`
- `san`: `1.e4`, `1...e5`, `Nf3` — informativo, deve corresponder ao uci naquela posição
- `porQue`: 1 frase curta explicando ideia (ex `Ocupa centro, libera bispo`) — obrigatório e não vazio
- `sequencia` em `doZero` = linha desde `fen` passo a passo, intercalando cores, todos legais consecutivos. Em `escolhaLance` = 2-3 alternativas legais a partir da FEN do passo.

## AberturaStep — 13 tipos fixos na ordem

`tipo` enum exato: `oQueE | porQueJogar | principios | doZero | tabiya | escolhaLance | porQue | reacao | armadilhas | errosComuns | plano | jogue | revisao` — **ordem obrigatória**, 13 entradas, `checkSpecCoverage()==0`.

Campos por tipo:

| tipo | `titulo` | `texto` | `fen` | `sequencia` | `quizzes` | `bullets` |
|---|---|---|---|---|---|---|
| `oQueE` | ✅ 1 frase | ✅ | — | — | — | — |
| `porQueJogar` | ✅ | ✅ | — | — | — | ✅ 2-3 bullets vantagens |
| `principios` | ✅ | ✅ | — | — | — | ✅ 4 bullets (Centro, Desenvolvimento, Rei, Não mova sem propósito) |
| `doZero` | ✅ | ✅ | ✅ (=`fenInicial`) | ✅ 5 UCIs (ex `e2e4…f1c4`) todos legais | — | — |
| `tabiya` | ✅ `Tabiya ⭐` | ✅ `É sua vez…` | ✅ (=`fenTabiya`) | — | ✅ 1 quiz 4 opções sobre ideia das **brancas** na Tabiya | — |
| `escolhaLance` | ✅ | ✅ | ✅ (=`fenTabiya`) | ✅ 2 UCIs legais (ex `c2c3` `d2d3`) | — | — |
| `porQue` | ✅ `Entenda…🧠` | ✅ | — | — | ✅ 1 quiz 4 opções (`correta` 0..3) | — |
| `reacao` | ✅ `Reação…` | ✅ `adversário saiu…` | ✅ FEN após desvio (ex `...d7d6` → `r1bqkbnr/...`) | — | ✅ 1 quiz adaptação | — |
| `armadilhas` | ✅ | ✅ | — | — | — | ✅ 2 bullets curtas (ex Mate Pastor, Evans) |
| `errosComuns` | ✅ | ✅ | — | — | — | ✅ 3-4 bullets (`Qh5?` etc) |
| `plano` | ✅ `Encontre o Plano ⭐` | ✅ | — (usa `plano.fenTransicao`) | — | — | — |
| `jogue` | ✅ | ✅ | — | — | — | ✅ 2 bullets `🟢 Teórico` `🔵 Adaptativo` |
| `revisao` | ✅ | ✅ | — | — | — | — |

Campos comuns: `titulo` non-empty, `texto` non-empty exceto quando bullets/quizzes cobrem, `extra` opcional ignorado.

## Quiz

`{pergunta, opcoes[4], correta, explicacao}`
- `pergunta` non-empty, termina com `?`
- `opcoes` exatamente 4 strings non-empty
- `correta` int 0..3
- `explicacao` 1 frase, explica estrutura > decoreba

## Plano

`{fenTransicao, pergunta, planos[3..4], planoCorreto, porQuePlano, sequenciaPlano}`
- `fenTransicao` FEN válida, transição (ex após `4.c3 Nf6` → `r1bqk2r/... w …`) — lado a jogar = quem deve executar plano (geralmente brancas)
- `pergunta` = `A abertura está terminando. Qual é seu plano?`
- `planos` 3-4 strings, `planoCorreto` índice do correto
- `porQuePlano` explicação 1-2 frases
- `sequenciaPlano` 3-5 UCIs legais consecutivos a partir de `fenTransicao` (ex `d2d4 e5d4 c3d4 c5b6`) — validado

## Validação automática

Rodar `tools_venv/bin/python tools/validate_aberturas.py [--abertura 1]` — verifica: FEN válida, lado correto, lances legais, 13 passos, Tabiya alcançável, quiz resposta válida, Reação/Plano FEN válida, sequência Plano legal, campos obrigatórios. Falha = bloqueia lote. Ver spec doc para lista completa.

## Exemplo mínimo (Italiana — referência)

Ver `app/assets/aberturas.json` id=1 para 13 steps completos, FENs `rnbqkbnr … w -`, Tabiya `r1bqk1nr/...Bc5 w …`, Reação `r1bqkbnr/...d6 w …`, Plano `r1bqk2r/...c3 Nf6 w …` + `d4 exd4 cxd4 Bb6`.

## Produção em lotes (recomendado)

Lote1 Ruy Lopez/London/Gambito Dama → lote2 Siciliana/Francesa/Caro-Kann → lote3 Índia Rei/GDR/Nimzo → lote4 Inglesa/Réti. **1 abertura por vez**, validar FEN+legalidade→testar→revisar conteúdo, sem alterar `OpeningEngine`. Novos temas futuros (Pirc etc) = novo JSON, mesmo schema.
