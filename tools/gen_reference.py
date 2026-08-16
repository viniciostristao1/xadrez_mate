#!/usr/bin/env python3
"""Gera referência de lances legais (python-chess) para validar o motor Dart.

Saída: app/test/data/legal_moves.json
  [{fen, legal: [uci, ...]}, ...]

Cobre: os 90 problemas do banco + posições aleatórias legais + casos
especiais (roque, en passant, promoção, xeques).
"""

import json
import random
from pathlib import Path

import chess

random.seed(424242)

OUT = Path(__file__).resolve().parent.parent / "app" / "test" / "data" / "legal_moves.json"
DB = Path(__file__).resolve().parent.parent / "app" / "assets" / "puzzles.json"

SPECIALS = [
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
    "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
    "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1",
    "r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1",
    "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3",
    "8/8/8/8/8/8/6k1/5K1Q w - - 0 1",  # Dama afogando
    "k7/5ppp/8/8/8/8/8/R5K1 w - - 0 1",
    "k7/8/8/8/8/8/8/KR6 w - - 0 1",  # mate de corredor
    "4k3/8/4P3/8/8/8/8/4K3 w - - 0 1",  # afogado
    "8/4P3/8/8/8/8/8/K6k w - - 0 1",  # promoção
    "8/1P6/8/8/8/8/8/k6K w - - 0 1",  # promoção com captura
    "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1",
    # en passant: brancas podem capturar
    "rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3",
    # roque bloqueado
    "r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1",
    # roque impossível (rei passa por xeque)
    "r3k2r/pppppppp/8/8/8/2b5/PPPPPPPP/R3K2R w KQkq - 0 1",
    # roque impossível (rei em xeque)
    "r3k2r/pppppppp/8/8/8/3r4/PPPPPPPP/R3K2R w KQkq - 0 1",
    # xeques duplos e cravadas
    "4k3/4q3/8/8/8/8/8/4KR2 w - - 0 1",
    # 50 movimentos e contagem
    "8/8/8/4k3/8/4K3/8/8 w - - 40 60",
]

data = []


def add(fen: str):
    b = chess.Board(fen)
    data.append({
        "fen": fen,
        "legal": sorted(m.uci() for m in b.legal_moves),
        "check": b.is_check(),
        "mate": b.is_checkmate(),
        "stalemate": b.is_stalemate(),
    })


for fen in SPECIALS:
    add(fen)

db = json.loads(DB.read_text())
for p in db["puzzles"]:
    add(p["fen"])

# Aleatórias legais (posições com poucas peças tendem a ser legais)
for _ in range(600):
    b = chess.Board()
    for _ in range(random.randint(4, 30)):
        moves = list(b.legal_moves)
        if not moves:
            break
        b.push(random.choice(moves))
    if b.is_game_over():
        continue
    add(b.fen())

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps(data, indent=0))
print(f"Referência gerada: {len(data)} posições → {OUT}")
