#!/usr/bin/env python3
"""Importa problemas TÁTICOS do Lichess (CC0) para a seção Tática.

Temas (3 de momento): skewer (espeto), discoveredAttack (descoberta),
sacrifice (sacrifício).

FORMATO (documentação oficial):
  - "FEN is the position before the opponent makes their move. The position
    to present to the player is after applying the first move to that FEN.
    The second move is the beginning of the solution."
  - O jogador controla o lado OPOSTO ao do FEN; posição do puzzle =
    `FEN + moves[0]`; lances do jogador = moves[1], moves[3], ...
  - "All player moves of the solution are only moves."

Cada problema tático é uma LINHA de solução linear (diferente dos mates,
que têm árvore completa): o app mostra a posição, o jogador joga o lance
previsto, o oponente responde com o lance da linha, e assim até o fim.

Saída: app/assets/tatica.json
  [{tema, level, rating, fen, linha: [lances alternados (jogador, oponente)]}]
"""

import csv
import io
import json
import sys
from collections import Counter
from pathlib import Path

import chess
import zstandard

sys.path.insert(0, str(Path(__file__).parent))

SRC = Path("/tmp/lichess_puzzles.csv.zst")
OUT = Path(__file__).resolve().parent.parent / "app" / "assets" / "tatica.json"

TEMAS = {
    "skewer": "espeto",
    "discoveredAttack": "descoberta",
    "sacrifice": "sacrificio",
}
# Chave canônica gravada no JSON (a UI usa estes nomes):
TEMA_PT = {"skewer": "espeto", "discoveredAttack": "descoberta", "sacrifice": "sacrificio"}
SAMPLE_PER_TEMA_NIVEL = 220
GOAL_PER_NIVEL = {"1": 16, "2": 14, "3": 12}  # por tema (total ~42/tema)
MIN_LINHA = 3  # mínimo de lances totais na linha (prefere linhas mais ricas)


def level_por_rating(r: int, faixas) -> int:
    if r <= faixas[0]:
        return 1
    if r <= faixas[1]:
        return 2
    return 3


def main() -> None:
    # 1) amostra candidatos por tema/nível de rating
    buckets = {t: {1: [], 2: [], 3: []} for t in TEMAS}
    with zstandard.ZstdDecompressor().stream_reader(open(SRC, "rb")) as r:
        reader = csv.reader(io.TextIOWrapper(r, encoding="utf-8"))
        next(reader)
        for row in reader:
            themes = set(row[7].split(" ")) if len(row) > 7 else set()
            tema = next((k for k in TEMAS if k in themes), None)
            if tema is None:
                continue
            rating = int(row[3])
            moves = row[2].split()
            if len(moves) < MIN_LINHA:
                continue
            nivel = 1 if rating < 1300 else (2 if rating < 1700 else 3)
            lst = buckets[tema][nivel]
            if len(lst) >= SAMPLE_PER_TEMA_NIVEL:
                continue
            lst.append({"fen": row[1], "moves": moves, "rating": rating})

    # 2) valida: aplica moves[0], confere legalidade da linha e o primeiro
    #    lance do jogador é "only move" plausível (não exigimos — o lichess
    #    garante); guarda a linha alternada.
    picked = {t: {1: [], 2: [], 3: []} for t in TEMAS}
    for tema in TEMAS:
        for nivel in (1, 2, 3):
            for cand in sorted(buckets[tema][nivel], key=lambda x: x["rating"]):
                b = chess.Board(cand["fen"])
                try:
                    b.push_uci(cand["moves"][0])
                except Exception:
                    continue
                puzzle_fen = b.fen()
                linha = cand["moves"][1:]  # índices pares = jogador
                # valida a linha completa
                ok = True
                b2 = b.copy()
                for mv in linha:
                    try:
                        b2.push_uci(mv)
                    except Exception:
                        ok = False
                        break
                if not ok:
                    continue
                picked[tema][nivel].append(
                    {"tema": TEMA_PT[tema], "level": nivel,
                     "rating": cand["rating"], "fen": puzzle_fen,
                     "linha": linha}
                )
            print(f"  {tema} nível{nivel}: {len(picked[tema][nivel])} aceitos")

    # 3) seleciona espalhado no rating e numera
    puzzles = []
    seen = set()
    for tema in TEMAS:
        for nivel in (1, 2, 3):
            lst = picked[tema][nivel]
            step = max(1, len(lst) // (GOAL_PER_NIVEL[str(nivel)] * 2))
            lst = lst[::step][:GOAL_PER_NIVEL[str(nivel)]]
            for p in lst:
                if p["fen"] in seen:
                    continue
                seen.add(p["fen"])
                puzzles.append(p)
    for i, p in enumerate(puzzles, 1):
        p["id"] = i

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"version": 1, "puzzles": puzzles}, indent=0))
    print(f"→ {len(puzzles)} problemas táticos → {OUT}")
    print("  por tema/nível:", dict(Counter((p["tema"], p["level"]) for p in puzzles)))


if __name__ == "__main__":
    main()
