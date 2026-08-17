#!/usr/bin/env python3
"""Gera o banco de problemas de xeque-mate (mate em 1, 2 ou 3) do Xeque-Mate.

Estratégia (construtiva + verificação exaustiva):
  1. Constrói posições de mate em 1 diretamente (rei no canto + escudos +
     peça que dá xeque-mate + defesas).
  2. Deriva candidatas de mate em 2/3 a partir das de mate 1 (remover/mover
     atacante, adicionar defensor preto) + posições aleatórias enviesadas.
  3. Clássicos conhecidos.
  4. Cada candidata passa pelo SOLVER: categoria EXATA (mate em 1/2/3) e
     árvore COMPLETA de solução (todas as respostas legais do oponente).

Garantia: a árvore cobre TODAS as respostas legais do oponente, então o app
sempre sabe responder certo. Saída: app/assets/puzzles.json
"""

import chess
import json
import random
import sys
from pathlib import Path

random.seed(20260816)

OUT = Path(__file__).resolve().parent.parent / "app" / "assets" / "puzzles.json"
LICHESS = Path(__file__).resolve().parent.parent / "app" / "assets" / "puzzles_lichess.json"

CORNERS = [chess.A8, chess.H8, chess.A1, chess.H1]
EDGE = [chess.square(f, r) for r in (0, 7) for f in range(8)] + \
       [chess.square(f, r) for f in (0, 7) for r in range(1, 7)]


def neighbors(sq: int) -> list[int]:
    f, r = chess.square_file(sq), chess.square_rank(sq)
    out = []
    for df in (-1, 0, 1):
        for dr in (-1, 0, 1):
            if df == 0 and dr == 0:
                continue
            nf, nr = f + df, r + dr
            if 0 <= nf < 8 and 0 <= nr < 8:
                out.append(chess.square(nf, nr))
    return out


def _flights(sq: int) -> list[int]:
    return [n for n in neighbors(sq) if chess.square_distance(n, sq) <= 1]


# ---------------------------------------------------------------------------
# Solver exaustivo
# ---------------------------------------------------------------------------


def _mate_in_1_keys(b: chess.Board) -> list[str]:
    keys = []
    for m in b.legal_moves:
        if b.gives_check(m):
            b.push(m)
            if b.is_checkmate():
                keys.append(m.uci())
            b.pop()
    return keys


def build_node(b: chess.Board, depth: int) -> dict | None:
    """Nó de solução: {keys: [...], replies: {uci: subnó}} ou None."""
    if depth <= 0:
        return None
    if depth == 1:
        keys = _mate_in_1_keys(b)
        return {"keys": keys, "replies": None} if keys else None
    keys, replies, ok = [], {}, True
    for m in b.legal_moves:
        if b.gives_check(m):
            b.push(m)
            if b.is_checkmate():
                b.pop()
                continue  # mate imediato não é chave para depth>1
        else:
            b.push(m)
        cont, okk = {}, True
        for r in list(b.legal_moves):
            b.push(r)
            sub = build_node(b, depth - 1)
            b.pop()
            if sub is None:
                okk = False
                break
            cont[r.uci()] = sub
        b.pop()
        if okk:
            keys.append(m.uci())
            replies[m.uci()] = cont
    return {"keys": keys, "replies": replies} if keys else None


def solve(b: chess.Board) -> dict | None:
    b = b.copy()
    for depth in (1, 2, 3):
        node = build_node(b, depth)
        if node is not None:
            return {"mate": depth, "tree": node}
    return None


# ---------------------------------------------------------------------------
# Construção de candidatas
# ---------------------------------------------------------------------------


def _place(b: chess.Board, pt: chess.PieceType, color: chess.Color, sq: int) -> bool:
    if sq < 0 or sq > 63 or b.piece_at(sq) is not None:
        return False
    if pt == chess.PAWN and chess.square_rank(sq) in (0, 7):
        return False
    b.set_piece_at(sq, chess.Piece(pt, color))
    return True


def _finish(b: chess.Board) -> chess.Board | None:
    """Valida legalidade e devolve o tabuleiro pronto (brancas a jogar)."""
    b.turn = chess.WHITE
    b.castling_rights = chess.Bitboard(0)
    b.ep_square = None
    b.halfmove_clock = 0
    b.fullmove_number = 1
    if not b.is_valid():
        return None
    wk = b.king(chess.WHITE)
    if wk is None or b.is_attacked_by(chess.BLACK, wk):
        return None
    if b.is_check() or len(list(b.legal_moves)) < 1:
        return None
    return b


def _white_king_spot(b: chess.Board) -> int:
    spots = [s for s in (0, 7, 56, 63) if b.piece_at(s) is None]
    return random.choice(spots) if spots else 63


ATTACKERS = {
    chess.KNIGHT: lambda sq: [chess.square(f, r) for f in range(8) for r in range(8)
                              if chess.square_distance(chess.square(f, r), sq) == 2
                              and chess.square_file(chess.square(f, r)) != chess.square_file(sq)
                              and chess.square_rank(chess.square(f, r)) != chess.square_rank(sq)],
    chess.QUEEN: lambda sq: [s for s in range(64) if s != sq and (
        chess.square_file(s) == chess.square_file(sq)
        or chess.square_rank(s) == chess.square_rank(sq)
        or abs(chess.square_file(s) - chess.square_file(sq))
        == abs(chess.square_rank(s) - chess.square_rank(sq)))],
    chess.ROOK: lambda sq: [s for s in range(64) if s != sq and (
        chess.square_file(s) == chess.square_file(sq)
        or chess.square_rank(s) == chess.square_rank(sq))],
    chess.BISHOP: lambda sq: [s for s in range(64) if s != sq and
                              abs(chess.square_file(s) - chess.square_file(sq))
                              == abs(chess.square_rank(s) - chess.square_rank(sq))],
}


def constructive_mate1() -> chess.Board | None:
    """Rei preto no canto + escudos + atacante com xeque + defensores."""
    b = chess.Board(None)
    bk = random.choice(CORNERS)
    b.set_piece_at(bk, chess.Piece(chess.KING, chess.BLACK))

    # Escudos pretos em 1-3 casas de fuga
    fl = [n for n in _flights(bk) if chess.square_rank(n) not in (0, 7)]
    random.shuffle(fl)
    for n in fl[:random.choice((1, 2, 2, 3))]:
        _place(b, chess.PAWN, chess.BLACK, n)

    # Atacante que dá xeque: escolhe tipo e casa de xeque
    pt = random.choice((chess.QUEEN, chess.ROOK, chess.BISHOP, chess.KNIGHT))
    cand = [s for s in ATTACKERS[pt](bk) if b.piece_at(s) is None]
    if not cand:
        return None
    random.shuffle(cand)
    atk_sq = cand[0]
    b.set_piece_at(atk_sq, chess.Piece(pt, chess.WHITE))

    # Defensor do atacante (para o rei não capturar) + cobertura de fugas
    defended = False
    for _ in range(2):
        if b.is_attacked_by(chess.WHITE, atk_sq) and any(
                chess.square_distance(n, atk_sq) <= 1 for n in _flights(bk)):
            defended = True
        dpt = random.choice((chess.ROOK, chess.BISHOP, chess.KNIGHT, chess.QUEEN))
        dc = [s for s in ATTACKERS[dpt](atk_sq) if b.piece_at(s) is None
              and chess.square_distance(s, bk) >= 2]
        if not dc:
            continue
        random.shuffle(dc)
        _place(b, dpt, chess.WHITE, dc[0])

    # Peça extra aleatória perto (cobre fugas / variedade)
    for _ in range(random.choice((0, 1, 2))):
        ept = random.choice((chess.KNIGHT, chess.BISHOP, chess.ROOK, chess.QUEEN))
        ring = [n for n in _flights(bk) if b.piece_at(n) is None and
                chess.square_rank(n) not in (0, 7)]
        if not ring:
            break
        sq = random.choice(ring)
        if _place(b, ept, chess.WHITE, sq) and random.random() < 0.3:
            break

    b.set_piece_at(_white_king_spot(b), chess.Piece(chess.KING, chess.WHITE))
    return _finish(b)


def random_bias() -> chess.Board | None:
    """Posição aleatória enviesada: rei preso, 3-5 atacantes próximos."""
    b = chess.Board(None)
    bk = random.choice(CORNERS + EDGE)
    b.set_piece_at(bk, chess.Piece(chess.KING, chess.BLACK))
    fl = [n for n in _flights(bk) if chess.square_rank(n) not in (0, 7)]
    random.shuffle(fl)
    for n in fl[:random.choice((1, 2, 3))]:
        _place(b, chess.PAWN, chess.BLACK, n)

    pool = [chess.QUEEN] * 2 + [chess.ROOK] * 3 + [chess.BISHOP] * 3 + [chess.KNIGHT] * 3
    random.shuffle(pool)
    for pt in pool[:random.choice((3, 4, 4, 5))]:
        cand = [s for s in range(64) if b.piece_at(s) is None
                and chess.square_distance(s, bk) <= 3
                and chess.square_distance(s, bk) >= 1]
        if not cand:
            break
        _place(b, pt, chess.WHITE, random.choice(cand))

    b.set_piece_at(_white_king_spot(b), chess.Piece(chess.KING, chess.WHITE))
    return _finish(b)


def variants_from_mate1(base: chess.Board) -> list[chess.Board]:
    """Deriva candidatas de mate 2/3 a partir de uma posição de mate 1."""
    outs = []
    white_pcs = [(s, p.piece_type) for s in range(64)
                 for p in [base.piece_at(s)] if p and p.color == chess.WHITE
                 and p.piece_type != chess.KING]
    random.shuffle(white_pcs)
    # 1) Remover um atacante branco
    for s, pt in white_pcs[:2]:
        b = base.copy()
        b.remove_piece_at(s)
        if _finish(b) is not None:
            outs.append(b)
    # 2) Adicionar um defensor preto (peão/cavalo) perto do rei
    for _ in range(2):
        b = base.copy()
        ring = [n for n in _flights(base.king(chess.BLACK)) if base.piece_at(n) is None
                and chess.square_rank(n) not in (0, 7)]
        if not ring:
            break
        sq = random.choice(ring)
        pt = random.choice((chess.PAWN, chess.PAWN, chess.KNIGHT))
        if _place(b, pt, chess.BLACK, sq) and _finish(b) is not None:
            outs.append(b)
    return outs


CLASSICS = [
    # Mate do louco — pretas dão mate em 1 (Qh4#)
    ("rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2", 1),
    # Mate escolar — brancas dão mate em 1 (Qxf7#)
    ("r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4", 1),
    # Mate no corredor (back rank) clássico
    ("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1", 1),
    # Corredor duplo — mate em 2 (Qe8+ Rf8 Qxf8#)
    ("4r1k1/5ppp/8/8/8/8/8/R3Q1K1 w - - 0 1", 2),
    # Corredor triplo — mate em 3 (Qe8+ Rf8 Qxf8+ Rxf8 Ra8#)
    ("2r1r1k1/5ppp/8/8/8/8/8/R3Q1K1 w - - 0 1", 3),
    # Dama vs rei — mate em 3 clássico
    ("8/8/8/8/8/4k3/8/4Q1K1 w - - 0 1", 3),
]


def heuristic_level(p: dict) -> int:
    """Nível heurístico para problemas gerados (1=fácil, 2=médio, 3=difícil).

    - Várias chaves de mate → fácil;
    - pouco material → fácil;
    - muito material (muitas defesas) → difícil;
    - chave silenciosa em mate>1 (não dá xeque) → mais difícil.
    """
    b = chess.Board(p["fen"])
    pieces = sum(1 for sq in range(64) if b.piece_at(sq))
    nkeys = len(p["tree"]["keys"])
    key = p["tree"]["keys"][0]
    m = b.parse_uci(key)
    quiet = not b.gives_check(m)
    score = 1
    if nkeys >= 2:
        score -= 1
    if pieces >= 9:
        score += 1
    if quiet and p["mate"] > 1:
        score += 1
    return max(1, min(3, score))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    goals = {"1": int(sys.argv[1]) if len(sys.argv) > 1 else 26,
             "2": int(sys.argv[2]) if len(sys.argv) > 2 else 20,
             "3": int(sys.argv[3]) if len(sys.argv) > 3 else 14}
    found = {"1": [], "2": [], "3": []}
    attempts = {"1": 0, "2": 0, "3": 0}
    max_attempts = {"1": 3000, "2": 12000, "3": 12000}

    def add(b: chess.Board):
        sol = solve(b)
        if sol is None:
            return
        cat = str(sol["mate"])
        if len(found[cat]) >= goals[cat]:
            return
        found[cat].append({"fen": b.fen(), **sol})

    # Clássicos
    for fen, _ in CLASSICS:
        add(chess.Board(fen))

    # Fase 1: mates construtivos (mate em 1 principalmente)
    while len(found["1"]) < goals["1"] and attempts["1"] < max_attempts["1"]:
        attempts["1"] += 1
        b = constructive_mate1()
        if b is not None:
            add(b)
    print(f"Fase 1: mate1={len(found['1'])}/{goals['1']} "
          f"({attempts['1']} tentativas)")

    # Fase 2: derivadas das posições de mate 1 (viram mate 2/3)
    base_pos = [chess.Board(p["fen"]) for p in found["1"]]
    random.shuffle(base_pos)
    while sum(len(found[c]) for c in "23") < goals["2"] + goals["3"]:
        attempts["2"] += 1
        if attempts["2"] > max_attempts["2"]:
            break
        if not base_pos:
            break
        base = base_pos.pop()
        for var in variants_from_mate1(base):
            add(var)

    # Fase 3: aleatórias enviesadas (completa mate 2/3)
    while (len(found["2"]) < goals["2"] or len(found["3"]) < goals["3"]) \
            and attempts["3"] < max_attempts["3"]:
        attempts["3"] += 1
        b = random_bias()
        if b is not None:
            add(b)

    # Espelha tudo (outro lado a jogar) para dobrar a variedade
    extra = {"1": [], "2": [], "3": []}
    for cat in "123":
        for p in list(found[cat]):
            bm = chess.Board(p["fen"]).mirror()
            sol = solve(bm)
            if sol:
                extra[str(sol["mate"])].append({"fen": bm.fen(), **sol})

    puzzles, seen = [], set()
    for cat in "123":
        for p in found[cat] + extra[cat]:
            if p["fen"] in seen:
                continue
            seen.add(p["fen"])
            p["level"] = heuristic_level(p)
            puzzles.append(p)

    # Problemas reais do Lichess (verificados, com rating e nível por terços)
    if LICHESS.exists():
        lich = json.loads(LICHESS.read_text()).get("puzzles", [])
        for p in lich:
            if p["fen"] in seen:
                continue
            seen.add(p["fen"])
            puzzles.append(p)

    puzzles.sort(key=lambda p: (p["mate"], p["level"], p["fen"]))
    for i, p in enumerate(puzzles, 1):
        p["id"] = i

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"version": 2, "puzzles": puzzles}, indent=1))

    from collections import Counter
    per_cat = Counter((p["mate"], p["level"]) for p in puzzles)
    print(f"Total: {len(puzzles)} problemas "
          f"(mate1={sum(1 for p in puzzles if p['mate']==1)}, "
          f"mate2={sum(1 for p in puzzles if p['mate']==2)}, "
          f"mate3={sum(1 for p in puzzles if p['mate']==3)})")
    for mate in (1, 2, 3):
        for lvl in (1, 2, 3):
            print(f"  mate{mate} nível{lvl}: {per_cat.get((mate, lvl), 0)}")
    print(f"→ {OUT}")


if __name__ == "__main__":
    main()
