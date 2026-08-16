# IDEIAS — planos e futuro do Xeque-Mate

## Próximos passos (ordem sugerida)

1. **Dica** — botão que revela o lance correto (com custo: contador de dicas
   por problema).
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

## Decisões em aberto

- Revelar o lance certo depois de 2 erros? (hoje: nunca — só avisa).
- A resposta do oponente é aleatória entre as legais; seria interessante
  escolher a "mais resistente" (linha mais longa) para treinar mais?
