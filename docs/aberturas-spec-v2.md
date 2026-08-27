# Mateflow — Spec Aberturas V2 (CONGELADA) — 2026-08-27

> **Status:** congelada para implementação. Não acrescentar complexidade antes do MVP da Italiana.
> **Regra global:** Priorizar compreensão e tomada de decisão sobre memorização de sequências. Sempre levar o usuário a entender por que um lance é jogado, reconhecer a estrutura e identificar o plano seguinte.

## 1. Conceito central

Não ensinar abertura como sequência decorada. Ensinar transição:
**princípios → posição-chave (Tabiya) → decisão → plano**

Diferencial: usuário sai sabendo reconhecer a posição e o que fazer nela, não "esqueci o lance 7".

## 2. Arquitetura

```
ABERTURAS
├── 0. Fundamentos
│   ├── Centro
│   ├── Desenvolvimento
│   ├── Rei seguro
│   ├── Não mova sem propósito
│   └── 5 Erros comuns (visual ❌)
├── 1. Famílias
│   ├── 1.e4
│   ├── 1.d4
│   ├── 1.c4
│   └── 1.Nf3
├── 2. Aprenda uma abertura (template 13 passos)
│   ├── Do Zero → Tabiya → Escolha → Por quê → Reação → Armadilhas → Erros → Plano
│   └── Jogue (Bot Teórico + Bot Adaptativo) → Revisão
└── 3. Revisão (repetição espaçada nos erros)
```

Fluxo por abertura: `Fundamentos → Famílias → Ideia → Do Zero → Tabiya ⭐ → Escolha → Por quê → Reação ⭐ → Armadilhas → Erros → Plano ⭐ → Jogue → Revisão`
Progressão: Memória → Reconhecimento → Decisão/Cálculo → Estratégia.

## 3. Quando acaba a abertura (definição pedagógica, não algoritmo)

Não usar regra absoluta "roque + torres conectadas = acabou" nem número fixo de lances.

Texto oficial:
> "A abertura está terminando quando os objetivos iniciais foram cumpridos e a posição começa a exigir um plano de meio-jogo."

Indicadores (🟢 checklist, não gatilho automático):
- Desenvolvimento das peças relevantes concluído
- Rei relativamente seguro
- Controle/ocupação do centro
- Dama desenvolvida quando necessário
- Torres próximas de se conectar
- Surge decisão estratégica própria da posição

Referência de lances: "Na maioria das posições de iniciantes essa transição acontece aproximadamente nos primeiros 8–12 lances, mas não existe número fixo. Xadrez não é relógio de lances."

**Regra de sistema (ajuste 2):** A transição não depende de detecção automática de "fim da teoria". O conteúdo de cada abertura define uma ou mais posições de transição apropriadas para o nível do aluno. "Poucos lances em teoria forçada" é conceito pedagógico, não critério algorítmico.

Visual: `Abertura → Transição → Meio-jogo` (barra, não ponto).

## 4. CAMADA 0 — Fundamentos

4 princípios + 5 erros em cards visuais.

Princípios: Centro, Desenvolvimento, Rei seguro, Não mova peças sem propósito.
5 erros: mover mesma peça sem necessidade, tirar dama cedo, ignorar centro, deixar rei no centro quando deveria buscar segurança, muitos movimentos de peões sem necessidade.

## 5. CAMADA 1 — Famílias

Apresentação por primeiro lance das Brancas (como Lichess/Chess.com/Chessable), com ECO A-E como metadado interno:
- Abertas 1.e4 e5
- Semi-Abertas 1.e4 c5/d5/e6/c6 (Siciliana, Francesa, Caro-Kann)
- Fechadas 1.d4 d5 (Gambito da Dama)
- Semi-Fechadas 1.d4 Nf6 (Índia do Rei, Nimzo-Índia)
- Flanco 1.c4, 1.Nf3 (Inglesa, Réti)

## 6. MVP — 12 aberturas explícitas (ajuste 1)

Brancas (4):
1. Italiana (1.e4 e5 2.Nf3 Nc6 3.Bc4) — **primeira a implementar completa**
2. Ruy Lopez (Espanhola)
3. London System
4. Gambito da Dama

Pretas vs 1.e4 (3):
5. Siciliana
6. Francesa
7. Caro-Kann

Pretas vs 1.d4 (3):
8. Defesa Índia do Rei
9. Gambito da Dama Recusado
10. Nimzo-Índia

Flanco (2):
11. Inglesa (1.c4)
12. Réti (1.Nf3)

Texto oficial: "Conjunto enxuto que cobre as principais estruturas e ideias encontradas por iniciantes." Sem promessa de "90%".

## 7. Template por abertura — 13 passos

Para cada uma das 12:

1. O que é? — 1 frase. Ex: "A Italiana desenvolve rápido e pressiona f7."
2. Por que jogar? — 2-3 vantagens
3. Princípios — quais dos 4 estão sendo aplicados
4. Do Zero — primeiros lances com árvore + "por que" em cada lance (ex: 2.Nf3 → desenvolve, ataca e5, prepara roque)
5. Tabiya ⭐ — posição-chave. "Você chegou aqui. É sua vez. O que jogaria?"
6. Escolha o lance — usuário encontra o movimento
7. Por quê? — quiz de entendimento. Ex: Por que Bc4? A) Atacar rei B) Desenvolver+preparar roque ... Acertou → 🧠 Entendimento +XP (separa saber o lance de saber a ideia)
8. Reação ⭐ — "Adversário fez diferente. O que mudou?" Treino de adaptação fora da linha principal
9. Armadilhas — poucas e importantes (ex: Mate do Pastor)
10. Erros comuns — erro + consequência
11. Encontre o Plano ⭐ — MECÂNICA (ajuste 3), não só tela:
    a) Posição de transição: "A abertura está terminando. Qual é seu plano?" — escolha entre 3-4 planos
    b) Por que esse plano?
    c) Jogue 3-5 lances tentando executar o plano
12. Jogue — 🟢 Bot Teórico (segue linha principal) + 🔵 Bot Adaptativo (sai da teoria, mais valioso)
13. Revisão — repetição espaçada focada nos pontos que o usuário errou

Árvore interativa sempre com "por quê" em cada nó, não só sequência.

## 8. Mecânicas e pontuação

- Tabiya como entrada principal (Do Zero é opcional para iniciante absoluto)
- Reação obrigatória após Tabiya
- Dois bots por abertura
- XP duplo: XP de lance correto + 🧠 XP de entendimento (quiz por quê)
- Revisão prioriza erros de entendimento e de plano

## 9. Plano de implementação

Fase 1: Italiana completa com 13 passos funcionando (valida mecânica).
Fase 2: Replicar modelo para as outras 11.
Não produzir conteúdo das 12 antes de validar a Italiana em teste com usuários.

## 10. O que NÃO fazer

- Não detectar fim de teoria automaticamente
- Não prometer cobertura percentual
- Não usar bot só de linha principal
- Não ensinar decoreba sem porquê/plano
