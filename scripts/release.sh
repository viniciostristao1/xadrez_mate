#!/usr/bin/env bash
# release.sh — corta um release nomeado a partir do build mais recente do CI.
#
# Uso:
#   scripts/release.sh <versao> "<nota de changelog em 1 linha>"
#   ex: scripts/release.sh v0.1.0 "Primeira versão: 120 problemas de mate 1/2/3"
#
# Pré-requisito: o commit já foi PUSHADO e o CI ficou VERDE (publica em 'ci-latest').
#   Acompanhe:  gh run watch <id> --exit-status   antes de chamar isto.
#
# O que faz:
#   1. baixa o APK arm64 do release rolling 'ci-latest';
#   2. cria o release <versao> com asset versionado + de NOME FIXO (xadrez-mate.apk).
#
# O nome fixo faz o link abaixo apontar SEMPRE pro APK mais novo (sem trocar de URL):
#   https://github.com/viniciostristao1/xadrez_mate/releases/latest/download/xadrez-mate.apk
set -euo pipefail
REPO=viniciostristao1/xadrez_mate

VER="${1:?uso: scripts/release.sh <versao> \"<nota>\"  (ex: v0.1.0)}"
NOTA="${2:-$VER}"
NUM="${VER#v}"; NUM="${NUM%%-*}"   # "0.1.0" a partir de "v0.1.0"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

echo "→ Baixando o build de 'ci-latest'…"
gh release download ci-latest -R "$REPO" -p app-arm64-v8a-release.apk --clobber

# sanidade: APK íntegro e assinado (v2)
unzip -t app-arm64-v8a-release.apk >/dev/null || { echo "APK corrompido"; exit 1; }
grep -aq 'APK Sig Block 42' app-arm64-v8a-release.apk || { echo "APK sem assinatura v2"; exit 1; }

cp app-arm64-v8a-release.apk "xadrez-mate-${NUM}-arm64.apk"
cp app-arm64-v8a-release.apk "xadrez-mate.apk"    # NOME FIXO (link /latest/download)

echo "→ Criando release ${VER}…"
gh release create "$VER" -R "$REPO" --title "$VER" --notes "$NOTA" \
  "xadrez-mate-${NUM}-arm64.apk" "xadrez-mate.apk"

echo
echo "✓ Release ${VER} publicado."
echo "  APK SEMPRE-A-ÚLTIMA (link fixo p/ o usuário):"
echo "      https://github.com/$REPO/releases/latest/download/xadrez-mate.apk"
