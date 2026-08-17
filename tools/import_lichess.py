#!/usr/bin/env python3
"""Importa problemas reais do Lichess (CC0) e mescla com o banco gerado.

Fonte: https://database.lichess.org/lichess_db_puzzle.csv.zst (CC0).

FORMATO (documentação oficial):
  - "FEN is the position before the opponent makes their move. The position
    to present to the player is after applying the first move to that FEN.
    The second move is the beginning of the solution."
  - Ou seja: o JOGADOR controla o lado oposto ao do FEN; a posição do puzzle
    é `FEN + moves[0]`; os lances do jogador são `moves[1], moves[3], ...`.
  - "All player moves of the solution are only moves. An exception is made
    for mates in one: there can be several. Any move that checkmates should
    win the puzzle."

O importador:
  1. amostra candidatos (tema mateIn1/2/3) balanceados por rating;
  2. aplica moves[0] ao FEN -> posição do puzzle;
  3. resolve com o solver (categoria exata + árvore cobrindo TODAS as
     respostas legais);
  4. PERCORRE a linha de solução do Lichess na árvore: cada lance do jogador
     precisa estar nas chaves do nó; a linha precisa terminar em xeque-mate;
  5. nível = terços do rating dentro de cada categoria (fácil/médio/difícil);
  6. exporta JSON para o merge.

Saída: app/assets/puzzles_lichess.json
"""

import csv
import io
import json
import random
import sys
from pathlib import Path

import zstandard

sys.path.insert(0, str(Path(__file__).parent))
from puzzle_gen import solve

random.seed(424242)

SRC = Path("/tmp/lichess_puzzles.csv.zst")
OUT = Path(__file__).resolve().parent.parent / "app" / "assets" / "puzzles_lichess.json"

CAT_KEY = {"mateIn1": 1, "mateIn2": 2, "mateIn3": 3}
SAMPLE_PER_CAT = {"1": 520, "2": 520, "3": 470}
GOAL_PER_LEVEL_PER_CAT = {"1": 50, "2": 46, "3": 45}


def verify(fen_original: str, all_moves: list[str], expected_mate: int) -> dict | None:
    """Aplica moves[0], resolve e percorre a linha completa do Lichess.

    Estrutura do nó: {keys: [lances do JOGADOR], replies: null | {
        lanceDoJogador: { respostaDoOponente: próximoNó } }}.
    """
    import chess

    b = chess.Board(fen_original)
    try:
        b.push_uci(all_moves[0])
    except Exception:
        return None
    puzzle_fen = b.fen()
    sol = solve(b)
    if sol is None or sol["mate"] != expected_mate:
        return None
    node = sol["tree"]
    opp_map = None  # {respostaDoOponente: próximoNó} do lance anterior
    for i in range(1, len(all_moves)):
        mv = all_moves[i]
        if i % 2 == 1:  # lance do JOGADOR
            if mv not in node["keys"]:
                return None
            if node.get("replies") is None:
                # terminal: este lance é o mate
                if i != len(all_moves) - 1:
                    return None
                return {"fen": puzzle_fen, "mate": sol["mate"],
                        "tree": sol["tree"]}  # raiz completa!
            opp_map = node["replies"][mv]
        else:  # resposta do OPONENTE (precisa estar coberta pela árvore)
            if mv not in opp_map:
                return None
            node = opp_map[mv]
    return None


def main() -> None:
    # 1) amostra candidatos por categoria (espalhado no rating)
    samples = {c: [] for c in "123"}
    with zstandard.ZstdDecompressor().stream_reader(open(SRC, "rb")) as r:
        reader = csv.reader(io.TextIOWrapper(r, encoding="utf-8"))
        next(reader)
        for row in reader:
            themes = set(row[7].split(" ")) if len(row) > 7 else set()
            cat = next((v for k, v in CAT_KEY.items() if k in themes), None)
            if cat is None:
                continue
            lst = samples[str(cat)]
            if len(lst) >= SAMPLE_PER_CAT[str(cat)]:
                continue
            lst.append({"fen": row[1], "moves": row[2].split(), "rating": int(row[3])})
        for cat in "123":
            samples[cat].sort(key=lambda x: x["rating"])

    # 2-4) verifica cada candidato
    picked = {"1": [], "2": [], "3": []}
    for cat in "123":
        for cand in samples[cat]:
            res = verify(cand["fen"], cand["moves"], int(cat))
            if res is not None:
                res["rating"] = cand["rating"]
                res["source"] = "lichess"
                picked[cat].append(res)
        picked[cat].sort(key=lambda x: x["rating"])
        print(f"  mate{cat}: {len(picked[cat])} aceitos de {len(samples[cat])}")

    # 5) níveis por terços de rating dentro de cada categoria
    puzzles = []
    for cat in "123":
        lst = picked[cat]
        n = len(lst)
        if n == 0:
            continue
        # seleciona até GOAL*3 espalhados (sem concentrar no meio)
        step = max(1, n // (GOAL_PER_LEVEL_PER_CAT[cat] * 3))
        lst = lst[::step][:GOAL_PER_LEVEL_PER_CAT[cat] * 3]
        n = len(lst)
        t1 = lst[n // 3]["rating"] if n >= 3 else lst[-1]["rating"]
        t2 = lst[(2 * n) // 3]["rating"] if n >= 3 else lst[-1]["rating"]
        for p in lst:
            if p["rating"] <= t1:
                p["level"] = 1
            elif p["rating"] <= t2:
                p["level"] = 2
            else:
                p["level"] = 3
        puzzles.extend(lst)
        from collections import Counter
        print(f"  mate{cat} níveis: {dict(Counter(p['level'] for p in lst))} "
              f"(faixas: <= {t1} / <= {t2} / +)")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"puzzles": puzzles}, indent=0))
    print(f"→ {len(puzzles)} problemas Lichess verificados → {OUT}")


if __name__ == "__main__":
    main()
