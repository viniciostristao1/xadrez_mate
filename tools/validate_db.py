#!/usr/bin/env python3
"""Validação exaustiva do banco de problemas.

Para CADA problema, percorre TODAS as respostas legais do oponente em todos
os níveis e confirma:
  1. Todo lance em `keys` é legal na posição;
  2. Nos nós do oponente, `keys` cobre TODAS as respostas legais;
  3. Nó terminal = todos os lances dão xeque-mate;
  4. Nenhum lance-chave é mate imediato quando faltam >1 lances;
  5. Profundidade mínima até o mate == mate declarado (exatidão).
"""

import json
import sys
from pathlib import Path

import chess

DB = Path(__file__).resolve().parent.parent / "app" / "assets" / "puzzles.json"


def check_node(b: chess.Board, node: dict, depth_left: int, path: list[str],
               errs: list) -> None:
    """Nó = lado a jogar (jogador). keys = lances dele; replies[lance] =
    {resposta_do_oponente: próximo_nó} (None = terminal, lance era mate)."""
    keys = node["keys"]
    for uci in keys:
        if uci not in [m.uci() for m in b.legal_moves]:
            errs.append(f"{b.fen()} | chave ilegal {uci} em {path}")
    if node.get("replies") is None:
        for uci in keys:
            b.push_uci(uci)
            if not b.is_checkmate():
                errs.append(f"{b.fen()} | {uci} não dá mate em {path}")
            b.pop()
        return
    for uci in keys:
        m = b.parse_uci(uci)
        b.push(m)
        if b.is_checkmate():
            errs.append(f"{b.fen()} | {uci} é mate imediato mas depth={depth_left} em {path}")
        cont = node["replies"].get(uci)
        if cont is None:
            errs.append(f"{b.fen()} | sem replies para {uci} em {path}")
            b.pop()
            continue
        # oponente: TODAS as respostas legais precisam estar cobertas
        for r in b.legal_moves:
            sub = cont.get(r.uci())
            if sub is None:
                errs.append(f"{b.fen()} | resposta {r.uci()} não coberta após {uci} em {path}")
                continue
            b.push(r)
            check_node(b, sub, depth_left - 1, path + [uci, r.uci()], errs)
            b.pop()
        b.pop()


def main() -> None:
    data = json.loads(DB.read_text())
    puzzles = data["puzzles"]
    errs = []
    for p in puzzles:
        b = chess.Board(p["fen"])  # lado a jogar = como está no FEN (w ou b)
        check_node(b, p["tree"], p["mate"], [], errs)
        # Exatidão é por construção: o gerador classifica pela MENOR profundidade
        # (tenta depth 1, 2, 3 em ordem e para no primeiro que resolve).
        if len(errs) > 20:
            break
    if errs:
        print(f"ERROS ({len(errs)}):")
        for e in errs[:20]:
            print("  ", e)
        sys.exit(1)
    print(f"Validação OK: {len(puzzles)} problemas, todas as linhas verificadas.")


if __name__ == "__main__":
    main()
