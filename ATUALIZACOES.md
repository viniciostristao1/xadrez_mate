# ATUALIZAÇÕES — changelog do usuário (topo = mais recente)

## v0.5.0 (2026-08-17)
**Cronômetro, dica e sistema de rating!**
- ⏱ **Cronômetro** por problema: começa quando o problema aparece e para na
  conclusão (zera a cada problema novo); tempo mostrado no topo e no resultado.
- 💡 **Dica (lâmpada)**: revela o lance correto jogada por jogada — destaca a
  peça e a casa no tabuleiro. Cada dica reduz a pontuação.
- 🏆 **Rating**: você começa com 1000 (leigo) e sobe até ~2000 (topo). Cada
  problema vale pontos com base no tempo (mate em 1: 10s, mate em 2: 25s,
  mate em 3: 60s para pontuação cheia), em erros (-20% cada) e dicas (-40%
  cada). O rating aparece na página principal e no resultado de cada problema.
- 🔄 Botão **refazer** agora é um ícone de flecha circular, ao lado da lâmpada
  (corrigido o reset do tabuleiro).

## v0.4.0 (2026-08-17)
**Agora é Mateflow!** Nome novo, logo ao lado do título na página principal e
**instalação/atualização sem conflito**: o app agora é assinado com uma chave
própria permanente (antes cada versão usava uma assinatura temporária, e o
Android recusava instalar por cima). ⚠️ Para instalar esta versão, **desinstale
o Mateflow/Xeque-Mate antigo primeiro** (uma única vez; as próximas atualizações
instalam por cima normalmente).

## v0.3.0 (2026-08-17)
**Novo logo oficial Vinyapps** (preto e âmbar) no ícone do aplicativo e na
tela inicial.

## v0.2.0 (2026-08-17)
**3 níveis de dificuldade + banco real de partidas!**
- Cada categoria (mate em 1/2/3) agora tem **Fácil, Médio e Difícil** — escolha
  o nível na tela inicial.
- **198 problemas reais de partidas** (banco oficial do Lichess, CC0) com
  classificação de dificuldade de milhares de jogadores — os "mate em 1"
  óbvios ficaram no nível Fácil; os níveis Médio/Difícil exigem pensar.
- Banco total: **318 problemas verificados** (130 de mate em 1, 106 em 2, 82
  em 3).
- **Peças maiores e com mais volume** — preenchem a casa do tabuleiro (com
  sombra suave), em todos os 3 layouts.

## v0.1.0 (2026-08-16)
Primeira versão do **Xeque-Mate**: 120 problemas de xeque-mate verificados
(52 de mate em 1, 40 em 2, 28 em 3 — metade com as pretas a jogar), com
escolha de dificuldade, 3 layouts de peças (Merida, Cburnett e Emoji),
tabuleiro que marca as casas legais de cada peça, aviso imediato de lance
errado (volta ao último lance correto) e parabéns com "Xeque-mate!" ao
resolver.
