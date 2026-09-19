# IDEIAS — planos e futuro do Xeque-Mate

## Próximos passos (ordem sugerida)

1. **Histórico de rating** ✅ (v0.6.0) — gráfico de evolução na home.
2. **Sessão de treino** ✅ (v0.6.0) — sequência com meta de tempo e resumo.
3. **Modo racha** — sessão cronometrada onde o tempo é a nota (estreia já
   com o tempo-alvo definido); ranking local de melhores sessões.
4. **Mais estatísticas** — erros por categoria, taxa de acerto por nível,
   melhor sequência.
5. **Tema de tabuleiro** — cores do tabuleiro (clássico, verde, madeira…).
6. **Modo "lado contrário"** — resolver do outro lado do tabuleiro.
2. **Contador de erros** — registrar quantas tentativas erradas o usuário fez
   por problema; mostrar no fim ("resolvido em X tentativas").
3. **Estatísticas locais** — problemas resolvidos/errados por categoria,
   persistidos em `shared_preferences`.
4. **Mais problemas** — rodar o gerador com sementes diferentes para ampliar
   o banco (hoje 120; meta 500+). Adicionar clássicos famosos (Anastasia,
   Boden, Legal, Arabian…) com FENs verificadas.
5. **Modo sequência** — sessão de N problemas com racha (contagem de erros e
   tempo).
6. **Nível de dificuldade por tema** (roteiro: corredor, mate de cavalo,
   afogado…) — exigiria etiquetar posições no gerador.
7. **Tema de tabuleiro** (cores do tabuleiro: clássico, verde, madeira…).
8. **Modo "lado contrário"** — resolver do outro lado do tabuleiro
   (espelhar já no app).
9. **Som de lance/mate** — pequenos efeitos sonoros (opcional, off por padrão).
10. **Play Store** — seguir o mesmo caminho do CarLog (AAB no lançamento).

## Modo Jogar (v0.17.0) — evoluções possíveis

1. **Repetição tripla** — hoje o empate automático cobre afogado, 50 lances e
   material insuficiente; falta a repetição tripla (precisa de chave de
   posição no `Board`).
2. **Dica no modo Jogar** — lâmpada com o melhor lance (a análise já calcula
   o melhor lance; custaria precisão na nota, como nas dicas dos Mates).
3. **Revisão pós-partida** — lista dos lances ruins/médios com o melhor lance
   e navegação para reviver cada posição.
4. **Rating do modo Jogar** — Elo próprio contra os níveis do rival,
   separado do rating dos Mates.
5. **Abertura preferida** — deixar o usuário começar de uma abertura
   (reusar o banco de `AberturasDb`) em vez da posição inicial.
6. **Tempo por lance** — opção de relógio (ex.: 10 min + incremento) medindo
   também a precisão sob pressão.

## Decisões em aberto

- Revelar o lance certo depois de 2 erros? (hoje: nunca — só avisa).
- A resposta do oponente é aleatória entre as legais; seria interessante
  escolher a "mais resistente" (linha mais longa) para treinar mais?
