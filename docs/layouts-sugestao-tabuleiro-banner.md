# 10 sugestões de layout — Tabuleiro + “Brancas/Pretas jogam”

> Pedido: (1) tabuleiro maior ocupando largura total + botões (Dica, Pausar, Refazer, Próximo) mais próximos/colados; (2) “Pretas jogam / Brancas jogam • lance X de Y” mais destacado e legível.

O **v0.10.2** já publicado é a **Opção 1** abaixo (implementação atual). As outras 9 são variações **não aplicadas** — escolha 1 ou combine elementos.

**APK atual (Opção 1):** https://github.com/viniciostristao1/xadrez_mate/releases/latest/download/xadrez-mate.apk

---

### 1) Atual v0.10.2 — Banner âmbar com borda (APLICADO)
- Padding lateral 8px (antes 16), gap header→tabuleiro 4px, tabuleiro→botões 2px
- Banner: fundo âmbar 18% + borda âmbar 1.6px, borderRadius 12, ícone ● (branco/preto), texto 16px w800 `Brancas jogam • lance 0 de 1`
- Barras de progresso 34×6 logo abaixo
- Pros: legível, mantém identidade âmbar, sem ocupar muito espaço

### 2) Faixa full-width cor da vez
- Banner ocupa 100% largura sem margem, fundo = branco (se brancas) ou preto (se pretas), texto cor oposta 17px w800 + `• lance X de Y` menor 14px
- Tabuleiro edge-to-edge (padding 0), botões pill com label
- Pros: máxima clareza de quem joga

### 3) Banner preto/branco sólido com selo
- Pill central 70% largura, fundo sólido branco/preto, borda cinza 1px, texto preto/branco 16px w800
- Selo circular ● 18px à esquerda com sombra
- Tabuleiro padding 4px

### 4) Duas linhas hierárquicas
- Linha 1: `BRANCAS JOGAM` 18px w900 caixa alta, linha 2: `lance 1 de 2` 13px w600 dim, dentro do mesmo banner âmbar claro
- Pros: escaneamento rápido, lance separado visualmente

### 5) Estilo Lichess — faixa azul + ícone
- Banner azul escuro #2E5AAC, ícone 👑 16px, texto branco 16px w800
- Tabuleiro com sombra forte, botões 56px
- Pros: familiar para quem usa Lichess

### 6) Minimal gigante sem fundo
- Sem banner: texto 20px w900 âmbar, centralizado: `● Brancas jogam — lance 1/3`
- Linha fina âmbar 2px abaixo + barras
- Pros: limpo, maior fonte sem ocupar card

### 7) Badge sobreposto no tabuleiro
- Pequeno badge flutuante no canto superior do tabuleiro (top: 8, left: 8), fundo âmbar, `Brancas • 1/3` 13px
- Header só com `Problema 42`
- Pros: economiza espaço vertical, tabuleiro ainda maior

### 8) Barra de progresso integrada
- Banner âmbar com barras DENTRO (embaixo do texto), sem Row separada: texto + 3 barras finas 4px dentro do card
- Pros: compacto, tudo em um elemento

### 9) Card elevado com sombra + ícone coroa
- Banner branco #1E2228 elevado (elevation 4), borda âmbar 2px, ícone ♔/♛ 20px, texto 16px w800, subtítulo `lance X de Y` 13px w700
- Botões em barra pill única (segmented control) colada no tabuleiro
- Pros: destaque máximo, parece “call to action”

### 10) Inversão — banner verde resolvido / âmbar jogando
- Mesmo que Opção 1 para “jogando”, mas quando `solved` banner verde ok 18% + ícone ✓ 18px + `Resolvido!` 16px w800
- Tabuleiro com borda verde 2px quando resolvido
- Pros: feedback de conclusão muito visível

---

## Como escolher
Responda com o número (ex: “quero a 4 + tabuleiro edge-to-edge da 2” ou “misturar 1 com botões da 9”). Eu aplico em <5 min, gerando novo APK no mesmo link fixo acima.

Próximo build manterá o link: `https://github.com/viniciostristao1/xadrez_mate/releases/latest/download/xadrez-mate.apk`
