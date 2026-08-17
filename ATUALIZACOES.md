# ATUALIZAÇÕES — changelog do usuário (topo = mais recente)

## v0.9.2 (2026-08-17)
- 🐛 **Correção**: os botões da página inicial (Mates, Tática, engrenagem)
  não abriam as telas — a navegação usava o contexto errado. Agora a
  navegação usa o `navigatorKey` e tudo abre normalmente.

## v0.9.1 (2026-08-17)
- 🐛 **Correção**: o app não carregava (tela preta + símbolo de carregando
  infinito) porque um dos arquivos de problemas não foi incluído no pacote.
  Agora o banco de Tática entra no APK e, se qualquer carga falhar, o app
  abre mesmo assim (sem travar).

## v0.9.0 (2026-08-17)
**Tática + idiomas + mais mates difíceis!**
- 🏠 **Nova página inicial**: escolha **Mates** ou **Tática** em botões
  grandes.
- ⚔️ **Seção Tática** com 3 temas: **Espeto**, **Descoberta** e
  **Sacrifício** (126 problemas reais de partidas, verificados, com os
  mesmos níveis Fácil/Médio/Difícil, cronômetro, dica e rating).
- ⚙️ **Engrenagem de configurações**: **idioma** (Português, English,
  Español) e **layout das peças** (movido para lá).
- 📈 **Banco de mates maior**: agora **543 problemas** — os níveis difíceis
  passaram de ~20 para **45–49 por categoria** (mate em 1, 2 e 3).

## v0.8.1 (2026-08-17)
- ⬆️ Botões de **dica, pausar, refazer e próximo** subiram: ficam mais
  perto do tabuleiro, sem colar no pé da tela.

## v0.8.0 (2026-08-17)
**Mate aleatório (surpresa) + peças Leipzig + dica em amarelo!**
- 🎲 **Mate aleatório**: no lugar da Sessão de treino. Problemas de mate em
  2 ou 3 misturados — **sem revelar quantos lances** são necessários, é
  surpresa! Resolver nesse modo dá **+30% de pontos** no rating.
- ♞ **Peças Leipzig** (estilo clássico de diagramas de livros) substituem o
  layout Emoji (que renderizava peças inconsistentes em alguns aparelhos).
- 💡 **Dica com destaque amarelo intenso** nas casas do lance sugerido.
- A Sessão de treino foi substituída pelo Mate aleatório.

## v0.7.1 (2026-08-17)
- ➡️ Botão de **próximo problema** (seta para a direita) sempre visível à
  direita do botão de refazer — antes de resolver, ele pula para o próximo.
- 🏁 Mensagem "Xeque-mate! Você conseguiu!" agora cabe inteira no topo do
  card de sucesso (removido o "Lance final" — o código da jogada continua
  abaixo do tabuleiro, como antes).

## v0.7.0 (2026-08-17)
**Ajustes de usabilidade!**
- 📜 **Página principal rola** até a Sessão de treino e a Evolução do rating.
- ⏸ **Pausar o cronômetro** com um botão entre a dica e o refazer (pausa/
  retoma quando quiser; o tempo pausado não conta).
- 🎯 **Sessão de treino mista**: nova opção "Misto 2/3" — problemas de mate
  em 2 ou 3 sorteados na mesma sessão (meta de tempo calculada por problema).
- ➡️ Botão de **próximo problema** (seta para a direita) ao lado dos demais
  quando você resolve.
- 🏁 Tela de jogo **sem rolagem**: o tabuleiro se ajusta e a mensagem de
  "Xeque-mate!" com o lance final aparece inteira na tela.
- 🗑️ Removida a caixa "Seu lance (1 de 1)" embaixo do tabuleiro (redundante).
- 🔤 **Mateflow** com o logo no canto superior esquerdo, menor.

## v0.6.0 (2026-08-17)
**Sessão de treino + evolução do rating!**
- ⚡ **Sessão de treino**: escolha lances até o mate (1/2/3), nível e
  quantidade (5, 10 ou 15 problemas) — o app mostra o progresso, o tempo
  total contra a meta (10s/25s/60s por problema) e um resumo ao final
  (acertos, erros, dicas, tempo e rating). Dá para refazer a sessão.
- 📈 **Gráfico de evolução do rating** na página principal — veja sua curva
  subir a cada problema resolvido.

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
