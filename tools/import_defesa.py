#!/usr/bin/env python3
"""Importa problemas de DEFESA do Lichess (CC0) para a categoria Defesa.

Tema-fonte: `defensiveMove` (defesa é o lance-chave do puzzle).
A posição do puzzle = FEN + moves[0]; os lances do jogador = moves[1::2].

Classifica cada problema em 5 subtemas (heurísticas verificáveis):
  - contraAtaque:  o lance de defesa dá XEQUE ou captura peça valiosa (≥5);
  - defesaPrecisa: o oponente AMEAÇA mate em 1 e só 1 lance legal evita;
  - defenderMate:  o oponente ameaça mate em 1 (e há ≥2 defesas);
  - salvarPeca:    há peça própria atacada e a defesa é um lance calmo;
  - neutralizar:   defesa sem as características acima.

Saída: app/assets/defesa.json
  [{id, tema, level, rating, fen, linha}]
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
OUT = Path(__file__).resolve().parent.parent / "app" / "assets" / "defesa.json"

SAMPLE = 900
GOAL_PER_NIVEL = {"1": 12, "2": 10, "3": 8}  # por subtema (30/tema, 150 total)

VALOR = {chess.PAWN: 1, chess.KNIGHT: 3, chess.BISHOP: 3,
         chess.ROOK: 5, chess.QUEEN: 9, chess.KING: 0}


def tem_mate_em_1(b: chess.Board, cor) -> bool:
    b = b.copy()
    b.turn = cor
    for m in b.legal_moves:
        b.push(m)
        if b.is_checkmate():
            b.pop()
            return True
        b.pop()
    return False


def peca_atacada(b: chess.Board, cor) -> bool:
    oponente = chess.WHITE if cor == chess.BLACK else chess.BLACK
    for sq in range(64):
        p = b.piece_at(sq)
        if p and p.color == cor and b.is_attacked_by(oponente, sq):
            return True
    return False


def vulnerabilidades(b: chess.Board, cor) -> int:
    """Peças de `cor` atacadas sem defesa suficiente (heurística simples)."""
    oponente = chess.WHITE if cor == chess.BLACK else chess.BLACK
    n = 0
    for sq in range(64):
        p = b.piece_at(sq)
        if p and p.color == cor:
            atac = b.attackers(oponente, sq)
            defs = b.attackers(cor, sq)
            if len(atac) > len(defs):
                n += 1
    return n


def classificar(b: chess.Board, linha: list[str]) -> str | None:
    """Classifica o puzzle nos 5 subtemas (None = descartar)."""
    jogador = b.turn
    oponente = chess.WHITE if jogador == chess.BLACK else chess.BLACK
    lance = b.parse_uci(linha[0])

    # 1) contra-ataque: xeque ou captura valiosa
    if b.gives_check(lance):
        return "contraAtaque"
    if b.is_capture(lance):
        alvo = b.piece_at(lance.to_square)
        # en passant: a casa de destino fica vazia; o peão capturado vale 1
        valor_alvo = VALOR.get(alvo.piece_type, 1) if alvo else 1
        if valor_alvo >= 5:
            return "contraAtaque"

    # ameaça de mate em 1 do oponente?
    ameaca_mate = tem_mate_em_1(b, oponente)
    if ameaca_mate:
        # defesas: lances legais que impedem o mate em 1 do oponente
        defesas = 0
        for m in b.legal_moves:
            b.push(m)
            if not tem_mate_em_1(b, oponente):
                defesas += 1
            b.pop()
        if defesas == 1:
            return "defesaPrecisa"
        return "defenderMate"

    # 2) defesa precisa: o lance de defesa é o ÚNICO lance "seguro"
    #    (sem peças próprias atacadas sem defesa suficiente)
    seguros = 0
    for m in b.legal_moves:
        b.push(m)
        if vulnerabilidades(b, jogador) == 0:
            seguros += 1
        b.pop()
    if seguros == 1:
        return "defesaPrecisa"

    # 3) defender contra mate: o jogador está em XEQUE (a defesa evita o
    #    mate que segue) ou o oponente ameaça mate (já tratado acima)
    if b.is_check():
        return "defenderMate"

    # 4) salvar peça: peça atacada + lance calmo
    if peca_atacada(b, jogador) and not b.is_capture(lance):
        return "salvarPeca"

    return "neutralizar"


def main() -> None:
    cands = []
    with zstandard.ZstdDecompressor().stream_reader(open(SRC, "rb")) as r:
        reader = csv.reader(io.TextIOWrapper(r, encoding="utf-8"))
        next(reader)
        for row in reader:
            themes = set(row[7].split(" ")) if len(row) > 7 else set()
            if "defensiveMove" not in themes:
                continue
            moves = row[2].split()
            if len(moves) < 3:
                continue
            cands.append({"fen": row[1], "moves": moves, "rating": int(row[3])})
            if len(cands) >= SAMPLE:
                break

    picked = {}
    for cand in cands:
        b = chess.Board(cand["fen"])
        try:
            b.push_uci(cand["moves"][0])
        except Exception:
            continue
        linha = cand["moves"][1:]
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
        tema = classificar(b, linha)
        if tema is None:
            continue
        picked.setdefault(tema, []).append(
            {"tema": tema, "rating": cand["rating"], "fen": b.fen(), "linha": linha})

    print("aceitos por tema:",
          {t: len(v) for t, v in sorted(picked.items())})

    # níveis por terços de rating dentro de cada tema + corte por meta
    puzzles = []
    seen = set()
    for tema in ("contraAtaque", "defesaPrecisa", "defenderMate",
                 "salvarPeca", "neutralizar"):
        lst = sorted(picked.get(tema, []), key=lambda x: x["rating"])
        if not lst:
            continue
        total_meta = sum(GOAL_PER_NIVEL.values())
        step = max(1, len(lst) // (total_meta * 3))
        lst = lst[::step][:total_meta * 3]
        n = len(lst)
        t1 = lst[max(0, n // 3 - 1)]["rating"]
        t2 = lst[max(0, (2 * n) // 3 - 1)]["rating"]
        for p in lst:
            p["level"] = 1 if p["rating"] <= t1 else (2 if p["rating"] <= t2 else 3)
            if p["fen"] in seen:
                continue
            seen.add(p["fen"])
            puzzles.append(p)
        print(f"  {tema}: {len(lst)} (faixas <= {t1} / <= {t2} / +)")

    for i, p in enumerate(puzzles, 1):
        p["id"] = i

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"version": 1, "puzzles": puzzles}, indent=0))
    print(f"→ {len(puzzles)} problemas de defesa → {OUT}")
    print("  por tema/nível:",
          dict(Counter((p["tema"], p["level"]) for p in puzzles)))


if __name__ == "__main__":
    main()
