# AGENTS.md — como contribuir no Xeque-Mate (guia p/ IA)

Este arquivo é o **fluxo de trabalho** para qualquer agente de IA (ou pessoa)
melhorar o Xeque-Mate. O repositório é **self-contained**: tudo que você
precisa está aqui.

## 0. Ordem de leitura (sempre)

1. [`INICIO.md`](INICIO.md) — o que é o app, estado atual, estrutura.
2. **Este `AGENTS.md`** — regras e fluxo.
3. [`APRENDIZADOS.md`](APRENDIZADOS.md) — gotchas (leia antes de mexer em
   motor/gerador de problemas!).
4. O código da área que vai tocar (`app/lib/<área>/` ou `tools/`).

## 1. Regras de ouro (NÃO violar)

- **Projeto isolado.** Só `/root/xadrez_mate/`. NUNCA tocar em
  `/root/trading*`, `/root/calistenia_app`, `/root/carlog_app`,
  `/root/lista_app`, `/root/adm-projetos`.
- **Nunca commitar segredos** (`*.jks`, `key.properties`, tokens).
- **Nunca inventar posição de problema.** Todo problema vem de
  `tools/puzzle_gen.py` (verificado por construção) ou de um clássico
  verificado pelo solver. Depois de mudar o banco: rode `tools/validate_db.py`
  e regenere a referência (`tools/gen_reference.py`).
- **Não compilar APK localmente** (VPS fraca) — build na nuvem (GitHub
  Actions). Verifique só com `analyze` + `test`.
- **Não** mexer no `applicationId` (`com.vinyapps.xadrez_mate`) nem no nome de
  exibição.
- **Não** apagar/editar arquivos que você não criou sem necessidade.

## 2. Convenções de código

- **Português (pt-BR)** em todo texto de UI e comentários.
- **Cores só via `AppColors`** (`lib/theme/app_colors.dart`).
- **Regras de xadrez SÓ no motor** (`lib/engine/chess.dart`) — lógica de
  lance/legalidade nunca em widget. Motivo: os testes de referência comparam
  o motor com o python-chess (737 posições); qualquer divergência quebra.
- **Estado** sem dependência externa: `StatefulWidget` + `setState`.
  Preferência de peças em `shared_preferences` (chave `piece_style`).
- Lógica nova com **teste** (`test/`).

## 3. Verificação local (obrigatória)

```bash
cd /root/xadrez_mate/app
/root/flutter/bin/flutter analyze lib/     # "No issues found!"
/root/flutter/bin/flutter test             # todos verdes (hoje 770)
```

Se mexer no **banco de problemas** (`tools/`):
```bash
cd /root/xadrez_mate
tools_venv/bin/python tools/validate_db.py    # valida todas as árvores
tools_venv/bin/python tools/gen_reference.py  # regenera referência do motor
cd app && /root/flutter/bin/flutter test test/engine_test.dart
```

## 4. Fluxo de release

1. Subir versão em `app/pubspec.yaml` (`X.Y.Z+N` — versionCode cresce; mudança
   visível = MINOR).
2. `git commit` + `git push origin main` → CI compila APK e publica em
   `ci-latest`. Acompanhe: `gh run watch <id> --exit-status`. **SEMPRE fazer
   commit+push imediatamente após `analyze`+`test` verdes — nunca deixar
   mudanças só locais.**
3. CI verde: `scripts/release.sh vX.Y.Z "<nota 1 linha>"` → publica o APK de
   nome fixo `xadrez-mate.apk` (link perene
   `/releases/latest/download/xadrez-mate.apk`).
4. 1 linha em `ATUALIZACOES.md` (se visível ao usuário) + nota técnica em
   `APRENDIZADOS.md`; planos → `IDEIAS.md`.
5. **Sempre enviar ao usuário o link direto do APK:**
   `https://github.com/viniciostristao1/xadrez_mate/releases/latest/download/xadrez-mate.apk`
   (após `scripts/release.sh`; enquanto CI roda, avisar que o link será
   atualizado em ~5 min).

## 5. Definition of Done

- [ ] `flutter analyze lib/` limpo e `flutter test` verde.
- [ ] Texto pt-BR; cores via `AppColors`; regras só no motor.
- [ ] Banco de problemas intacto ou revalidado (validate + gen_reference).
- [ ] Nenhum segredo no diff; nada fora de `/root/xadrez_mate/`.
- [ ] 1 linha em `ATUALIZACOES.md` + nota em `APRENDIZADOS.md`.
