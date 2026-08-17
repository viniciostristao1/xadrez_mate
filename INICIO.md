# Mateflow — INÍCIO (ler primeiro em toda tarefa)

App **Flutter** de treino de xadrez com **problemas de xeque-mate** (mate em
**1, 2 ou 3 lances**). O usuário escolhe a dificuldade, seleciona uma peça,
vê as **casas legais marcadas** (regras de xadrez puras: cavalo só faz "L",
bispo só diagonal, etc.) e joga o lance exato. **Errou? Aviso imediato** e o
tabuleiro volta ao último lance correto. Acertou tudo? **Xeque-mate! 🎉**

> ⚠️ Projeto isolado. Vive **só** em `/root/xadrez_mate/`.
> NUNCA tocar em `/root/trading/`, `/root/trading_acoes/`, `/root/trading_opcoes/`,
> `/root/calistenia_app/`, `/root/carlog_app/`, `/root/lista_app/`, `/root/adm-projetos/`.

> 📓 **Fluxo fixo (harness):** ao fim de cada bloco significativo →
> 1. `cd app && /root/flutter/bin/flutter analyze lib/` e `flutter test` limpos;
> 2. **subir a versão** em `app/pubspec.yaml` (`X.Y.Z+N` → o `+N` é o versionCode,
>    tem de crescer; a tag do release = `vX.Y.Z`);
> 3. registrar em [`APRENDIZADOS.md`](APRENDIZADOS.md) (técnico) e, se for visível
>    ao usuário, UMA LINHA em [`ATUALIZACOES.md`](ATUALIZACOES.md) (topo = mais
>    recente); planos → [`IDEIAS.md`](IDEIAS.md);
> 4. **commit + push na `main`** → o CI compila o APK na nuvem e publica no
>    `ci-latest`; depois `scripts/release.sh vX.Y.Z "<nota>"` corta o release
>    nomeado (link perene `xadrez-mate.apk`).

Papéis dos docs: referência (`INICIO`) · como contribuir (`AGENTS.md` — ler
antes de editar código) · técnico/gotchas (`APRENDIZADOS`) · changelog do
usuário (`ATUALIZACOES`) · futuro (`IDEIAS`).

## ⭐ ESTADO ATUAL (2026-08-17) — ler primeiro pós-/clear

**v0.5.0 — CRONÔMETRO + DICA + RATING** (tempo por problema, lâmpada de
dica jogada a jogada, rating estilo Elo inicial 1000, botão refazer como
ícone de flecha circular). Base anterior:

**v0.4.0 — MATEFLOW + ASSINATURA PRÓPRIA** (nome novo, logo ao lado do
título na home, keystore de upload permanente — instala/atualiza sem
conflito; ver APRENDIZADOS §assinatura).

**v0.3.0 — LOGO VINYAPPS** (ícone do launcher + home, preto/âmbar).

**v0.2.0 — NÍVEIS + BANCO REAL** (`flutter analyze` limpo, **969 testes**
passando, sendo 935 contra referência do python-chess). App completo:

- **Home** — escolhe **Mate em 1 / 2 / 3** e o **nível de dificuldade**
  (**Fácil / Médio / Difícil**, com contagem) + **layout das peças**:
  **Merida**, **Cburnett** ou **Emoji** (preferência salva).
- **Tabuleiro interativo** — orientado para o lado que joga (problemas com
  brancas OU pretas); toca na peça → **casas legais marcadas**; toca no
  destino → joga.
- **Problemas** — **318 verificados** (130 mate-1, 106 mate-2, 82 mate-3):
  **198 reais de partidas** (banco oficial do Lichess, CC0, com rating real de
  dificuldade) + 120 gerados/espelhados. Cada um tem a **árvore completa de
  solução**: TODAS as respostas legais do oponente têm continuação exata.
- **Cronômetro** — roda desde o problema aparecer até concluir; zera a cada
  problema novo; tempo exibido no topo e no resultado.
- **Dica (lâmpada)** — revela o lance correto do momento (peça e casa
  destacadas); usada jogada por jogada. Cada dica custa pontos.
- **Rating (Elo)** — inicial 1000 (leigo); tempo-alvo p/ pontuação cheia:
  mate1 = 10s, mate2 = 25s, mate3 = 60s; erros -20% cada; dicas -40% cada.
  `lib/services/rating_service.dart` (verificado por testes).
- **Feedback imediato** — lance errado: aviso na hora + volta ao último lance
  correto (não aplica o lance). Lance certo: segue; resposta do oponente
  automática. Fim: **"Xeque-mate! Você conseguiu"** + próximo problema.
- **Refazer** — ícone de flecha circular ao lado da lâmpada (reinicia o
  problema e o cronômetro).
- **Histórico de lances em SAN** (ex.: `1...Qh4#`), contador de lances,
  realce do último lance, xeque em vermelho, reiniciar problema.
- **Promoção** — diálogo de escolha da peça quando um peão chega à última
  fileira.

**Geração do banco**: `tools/puzzle_gen.py` (construtivos: rei no canto +
escudos + atacantes, resolvidos por busca exaustiva com python-chess) +
`tools/import_lichess.py` (problemas reais do Lichess, re-verificados pelo
solver). Níveis: terços do rating do Lichess (reais) ou heurística
(chaves múltiplas/pouco material = fácil; muito material/chave silenciosa =
difícil) nos gerados. Validação independente em `tools/validate_db.py`
(varre toda a árvore de cada problema).

## O que o app faz (MVP)

1. Tela inicial: **3 cartões** (Mate em 1/2/3), cada um com **3 níveis**
   (Fácil/Médio/Difícil) + contagem.
2. Tela do problema: tabuleiro + instrução ("Brancas jogam · lance 1 de 2").
3. Jogador seleciona peça → casas legais com marcador; só pode jogar legal.
4. Errou: **"Lance incorreto (X). Volte a pensar!"** + shake, sem avançar.
5. Acertou todos: **"Xeque-mate! Você conseguiu!"** → próximo problema.

## Princípios (não violar)

1. **Lances exatos** — o jogo só aceita o lance previsto para aquele
   problema; qualquer desvio é erro na hora (não espera terminar os lances).
2. **Regras de xadrez puras** — o motor gera TODOS os lances legais e o
   tabuleiro só marca essas casas (cavalo = "L", peão não volta, cravada não
   expõe o rei, roque não atravessa xeque, etc.).
3. **Sem posição inventada** — todo problema é verificado por construção
   (gerador + validador + testes contra python-chess).
4. **Rápido** — poucos toques para jogar; feedback instantâneo.

## Técnico

- Flutter **3.44.7** / Dart **3.12.2** em `/root/flutter`.
- **Sem estado externo** — `shared_preferences` só para a preferência de
  peças. Motor de xadrez puro em `lib/engine/chess.dart` (sem dependência de
  UI, testável).
- Banco: `assets/puzzles.json` (gerado por `tools/puzzle_gen.py` +
  `tools/import_lichess.py`, validado por `tools/validate_db.py`; referência
  de lances legais em `test/data/legal_moves.json` via
  `tools/gen_reference.py`).
- Arquitetura feature-based: `lib/screens/`, `lib/widgets/`, `lib/models/`,
  `lib/data/`, `lib/engine/`, `lib/theme/`.
- Pacote Android: **com.vinyapps.xadrez_mate** (applicationId — NÃO mudar).
  Nome de exibição: **Xeque-Mate**. Ícone gerado por `flutter_launcher_icons`.

## Estrutura do código (`app/lib/`)

- `engine/chess.dart` — **motor completo** (FEN, lances legais, xeque/mate/
  afogado, roque, en passant, promoção, SAN) — sem import de Flutter.
- `models/puzzle.dart` — `Puzzle` + `PuzzleNode` (árvore de solução).
- `data/puzzle_db.dart` — carrega/indexa `assets/puzzles.json`.
- `screens/home_screen.dart` — dificuldade + layout das peças.
- `screens/puzzle_screen.dart` — fluxo de resolução (correto/errado/mate).
- `widgets/chess_board.dart` — tabuleiro interativo (destaques, marcadores).
- `widgets/piece_icon.dart` — peças nos 3 estilos (Merida/Cburnett SVG,
  Emoji Unicode).
- `theme/` — `app_colors.dart` (tokens) e `app_theme.dart` (tema escuro).

## Testes

```bash
cd /root/xadrez_mate/app
/root/flutter/bin/flutter analyze lib/   # "No issues found!"
/root/flutter/bin/flutter test           # 770 testes
```

- `test/engine_test.dart` — motor: **935 posições de referência** (lances
  legais do python-chess) + regras específicas (cavalo L, peões, roque,
  cravadas, en passant, promoção, SAN, FEN ida-e-volta).
- `test/puzzle_flow_test.dart` — fluxo real com o banco (acertar mate 1/2/3,
  erro imediato, seleção só de casas legais, tabuleiro invertido p/ pretas).
- `test/home_test.dart` — home + renderização dos 3 estilos de peça.

## Entrega & Release

A VPS não compila Android bem → build na **nuvem** (GitHub Actions,
`.github/workflows/build-apk.yml`, tolerante a secrets ausentes — sem
keystore assina em debug). Ciclo:

1. Editar; `analyze`/`test` limpos; subir versão no `pubspec.yaml`.
2. `git commit` + `git push origin main` → CI compila o APK arm64 e publica no
   release rolling `ci-latest`. Acompanhar: `gh run watch <id> --exit-status`.
3. CI verde: `scripts/release.sh vX.Y.Z "<nota 1 linha>"` → cria o release com
   o APK de **nome fixo** `xadrez-mate.apk` (link perene abaixo).

### 🔗 Link "latest" perene

- **Página:** `https://github.com/viniciostristao1/xadrez_mate/releases/latest`
- **APK direto:** `https://github.com/viniciostristao1/xadrez_mate/releases/latest/download/xadrez-mate.apk`

⚠️ Repo é **PÚBLICO** (escolha do usuário por limite da conta) — o link
funciona para qualquer pessoa, sem login.

## Ambiente

VPS: ~1 vCPU, pouca RAM. OK para codar/`analyze`/`test`; **build de APK sai
na nuvem**.
