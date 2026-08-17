/// Motor de xadrez puro (sem dependências de UI) usado pelo app de problemas.
///
/// Implementa as regras completas do xadrez:
///   - cavalo só faz "L", bispo só diagonal, torre só reta, etc.;
///   - peão: 1 casa, 2 na inicial, captura diagonal, en passant, promoção;
///   - rei: 1 casa + roque (com todas as restrições);
///   - xeque, xeque-mate e afogado;
///   - FEN (parse/serialização) e SAN para exibição.
library;

enum ChessColor { white, black }

enum PieceType { pawn, knight, bishop, rook, queen, king }

class Piece {
  final PieceType type;
  final ChessColor color;
  const Piece(this.type, this.color);
}

/// Casa: a1 = 0, h8 = 63. file = sq % 8, rank = sq ~/ 8.
class Move {
  final int from;
  final int to;

  /// Peça de promoção (se promoção).
  final PieceType? promotion;

  /// Flags internas para desfazer o lance corretamente.
  final int flags;
  static const int flagNone = 0;
  static const int flagKingCastle = 1;
  static const int flagQueenCastle = 2;
  static const int flagEnPassant = 4;
  static const int flagDoublePush = 8;
  static const int flagPromotion = 16;

  const Move(this.from, this.to, {this.promotion, this.flags = flagNone});

  bool get isCastle => flags & (flagKingCastle | flagQueenCastle) != 0;

  String get uci {
    final b = _sqName(from);
    final e = _sqName(to);
    if (promotion != null) {
      return '$b$e${_promoChar(promotion!)}';
    }
    return '$b$e';
  }

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.from == from &&
      other.to == to &&
      other.promotion == promotion;

  @override
  int get hashCode => Object.hash(from, to, promotion);

  @override
  String toString() =>
      'Move(${_sqName(from)}->${_sqName(to)}${promotion != null ? '=${_promoChar(promotion!)}' : ''})';
}

String _sqName(int i) => 'abcdefgh'[i % 8] + '12345678'[i ~/ 8];
String _promoChar(PieceType t) => switch (t) {
      PieceType.pawn => 'p',
      PieceType.knight => 'n',
      PieceType.bishop => 'b',
      PieceType.rook => 'r',
      PieceType.queen => 'q',
      PieceType.king => 'k',
    };

/// Posição de xadrez com histórico (para desfazer).
class Board {
  final List<Piece?> _squares = List.filled(64, null);

  ChessColor turn = ChessColor.white;
  int castlingRights = 0; // bits: 1=K(branco), 2=Q(branco), 4=k(preto), 8=q(preto)
  int? epSquare;
  int halfmoveClock = 0;
  int fullmoveNumber = 1;

  // Histórico p/ desfazer
  final List<({int from, int to, PieceType? promo, int flags, Piece? captured,
      int castlingRights, int? epSquare, int halfmoveClock})> _history = [];

  Board();

  factory Board.fen(String fen) {
    final b = Board();
    b.parseFen(fen);
    return b;
  }

  Piece? pieceAt(int sq) => _squares[sq];

  /// Nº de lances jogados desde o FEN inicial (para desfazer).
  int get moveCount => _history.length;

  static int sq(int file, int rank) => rank * 8 + file;

  /// Rei da cor; -1 se ausente (posição malformada).
  int? kingSquare(ChessColor color) {
    for (var i = 0; i < 64; i++) {
      final p = _squares[i];
      if (p != null && p.type == PieceType.king && p.color == color) return i;
    }
    return null;
  }

  // ------------------------------------------------------------------
  // FEN
  // ------------------------------------------------------------------

  void parseFen(String fen) {
    final parts = fen.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) {
      throw FormatException('FEN inválida: $fen');
    }
    _squares.fillRange(0, 64, null);
    final rows = parts[0].split('/');
    if (rows.length != 8) throw FormatException('FEN: 8 fileiras esperadas');
    for (var r = 0; r < 8; r++) {
      var f = 0;
      for (final ch in rows[7 - r].split('')) {
        if (ch.codeUnitAt(0) >= 0x31 && ch.codeUnitAt(0) <= 0x38) {
          f += int.parse(ch);
        } else {
          final (pt, color) = _fromFenChar(ch);
          _squares[r * 8 + f] = Piece(pt, color);
          f++;
        }
      }
      if (f != 8) throw FormatException('FEN: fileira $r com $f casas');
    }
    turn = parts[1] == 'b' ? ChessColor.black : ChessColor.white;
    castlingRights = 0;
    for (final ch in parts[2].split('')) {
      if (ch == 'K') castlingRights |= 1;
      if (ch == 'Q') castlingRights |= 2;
      if (ch == 'k') castlingRights |= 4;
      if (ch == 'q') castlingRights |= 8;
    }
    epSquare = parts[3] == '-' ? null : _parseSq(parts[3]);
    halfmoveClock = parts.length > 4 ? int.tryParse(parts[4]) ?? 0 : 0;
    fullmoveNumber = parts.length > 5 ? int.tryParse(parts[5]) ?? 1 : 1;
    _history.clear();
  }

  String get fen {
    final b = StringBuffer();
    for (var r = 7; r >= 0; r--) {
      var empty = 0;
      for (var f = 0; f < 8; f++) {
        final p = _squares[r * 8 + f];
        if (p == null) {
          empty++;
        } else {
          if (empty > 0) {
            b.write(empty);
            empty = 0;
          }
          b.write(_fenChar(p));
        }
      }
      if (empty > 0) b.write(empty);
      if (r > 0) b.write('/');
    }
    final kr = StringBuffer();
    if (castlingRights & 1 != 0) kr.write('K');
    if (castlingRights & 2 != 0) kr.write('Q');
    if (castlingRights & 4 != 0) kr.write('k');
    if (castlingRights & 8 != 0) kr.write('q');
    final rights = kr.isEmpty ? '-' : kr.toString();
    return '$b ${turn == ChessColor.white ? 'w' : 'b'} $rights '
        '${epSquare == null ? '-' : _sqName(epSquare!)} $halfmoveClock $fullmoveNumber';
  }

  static (PieceType, ChessColor) _fromFenChar(String ch) {
    final lower = ch.toLowerCase();
    final type = switch (lower) {
      'p' => PieceType.pawn,
      'n' => PieceType.knight,
      'b' => PieceType.bishop,
      'r' => PieceType.rook,
      'q' => PieceType.queen,
      'k' => PieceType.king,
      _ => throw FormatException('Peça FEN inválida: $ch'),
    };
    return (type, ch == lower ? ChessColor.black : ChessColor.white);
  }

  static String _fenChar(Piece p) {
    final c = switch (p.type) {
      PieceType.pawn => 'p',
      PieceType.knight => 'n',
      PieceType.bishop => 'b',
      PieceType.rook => 'r',
      PieceType.queen => 'q',
      PieceType.king => 'k',
    };
    return p.color == ChessColor.white ? c.toUpperCase() : c;
  }

  static int _parseSq(String s) {
    if (s.length != 2) throw FormatException('Casa inválida: $s');
    final f = 'abcdefgh'.indexOf(s[0]);
    final r = int.parse(s[1]);
    if (f < 0 || r < 1 || r > 8) throw FormatException('Casa inválida: $s');
    return (r - 1) * 8 + f;
  }

  // ------------------------------------------------------------------
  // Ataques
  // ------------------------------------------------------------------

  static const List<(int, int)> _knightDeltas = [
    (1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2),
  ];
  static const List<(int, int)> _kingDeltas = [
    (0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (-1, 1),
  ];
  static const List<(int, int)> _rookDirs = [(0, 1), (0, -1), (1, 0), (-1, 0)];
  static const List<(int, int)> _bishopDirs = [(1, 1), (1, -1), (-1, 1), (-1, -1)];

  bool _onBoard(int f, int r) => f >= 0 && f < 8 && r >= 0 && r < 8;

  /// A casa `sq` está atacada por alguma peça da cor `by`?
  bool isAttacked(int sq, ChessColor by) {
    final f = sq % 8, r = sq ~/ 8;
    // Peões: um peão branco em (f±1, r-1) ataca (f, r); preto em (f±1, r+1)
    final pr = by == ChessColor.white ? r - 1 : r + 1;
    if (_onBoard(f - 1, pr)) {
      final p = _squares[pr * 8 + (f - 1)];
      if (p != null && p.color == by && p.type == PieceType.pawn) return true;
    }
    if (_onBoard(f + 1, pr)) {
      final p = _squares[pr * 8 + (f + 1)];
      if (p != null && p.color == by && p.type == PieceType.pawn) return true;
    }
    // Cavalos: (|df|, |dr|) ∈ {(1,2),(2,1)}
    for (final (df, dr) in _knightDeltas) {
      final nf = f + df, nr = r + dr;
      if (!_onBoard(nf, nr)) continue;
      final p = _squares[nr * 8 + nf];
      if (p != null && p.color == by && p.type == PieceType.knight) return true;
    }
    // Rei: |df| ≤ 1 e |dr| ≤ 1
    for (final (df, dr) in _kingDeltas) {
      final nf = f + df, nr = r + dr;
      if (!_onBoard(nf, nr)) continue;
      final p = _squares[nr * 8 + nf];
      if (p != null && p.color == by && p.type == PieceType.king) return true;
    }
    // Deslizantes (torre/bispo/dama)
    for (final (df, dr) in _rookDirs) {
      var ff = f + df, rr = r + dr;
      while (_onBoard(ff, rr)) {
        final p = _squares[rr * 8 + ff];
        if (p != null) {
          if (p.color == by && (p.type == PieceType.rook || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
        ff += df;
        rr += dr;
      }
    }
    for (final (df, dr) in _bishopDirs) {
      var ff = f + df, rr = r + dr;
      while (_onBoard(ff, rr)) {
        final p = _squares[rr * 8 + ff];
        if (p != null) {
          if (p.color == by && (p.type == PieceType.bishop || p.type == PieceType.queen)) {
            return true;
          }
          break;
        }
        ff += df;
        rr += dr;
      }
    }
    return false;
  }

  // ------------------------------------------------------------------
  // Geração de lances
  // ------------------------------------------------------------------

  /// Lances legais de quem joga (já filtrando xeque/roque/afogado).
  List<Move> legalMoves() {
    final moves = <Move>[];
    for (var sq = 0; sq < 64; sq++) {
      final p = _squares[sq];
      if (p == null || p.color != turn) continue;
      final ms = _movesFrom(sq, p);
      moves.addAll(ms);
    }
    final legal = <Move>[];
    final mover = turn;
    final opp = mover == ChessColor.white ? ChessColor.black : ChessColor.white;
    for (final m in moves) {
      // Roque: rei não pode estar em xeque nem passar por casa atacada
      if (m.isCastle) {
        if (_inCheck(mover)) continue;
        final mid = m.from + (m.flags & Move.flagKingCastle != 0 ? 1 : -1);
        if (isAttacked(mid, opp)) continue;
      }
      _makeMoveInternal(m);
      final ok = !_inCheck(mover); // rei de quem moveu não pode ficar em xeque
      undoMove();
      if (ok) legal.add(m);
    }
    return legal;
  }

  List<Move> _movesFrom(int sq, Piece p) {
    final f = sq % 8, r = sq ~/ 8;
    return switch (p.type) {
      PieceType.pawn => _pawnMoves(sq, f, r, p.color),
      PieceType.knight => _knightMoves(sq, f, r, p.color),
      PieceType.bishop => _sliding(sq, f, r, p.color, _bishopDirs),
      PieceType.rook => _sliding(sq, f, r, p.color, _rookDirs),
      PieceType.queen => _sliding(sq, f, r, p.color, [..._rookDirs, ..._bishopDirs]),
      PieceType.king => _kingMoves(sq, f, r, p.color),
    };
  }


  List<Move> _knightMoves(int sq, int f, int r, ChessColor c) {
    final out = <Move>[];
    for (final (df, dr) in _knightDeltas) {
      final nf = f + df, nr = r + dr;
      if (!_onBoard(nf, nr)) continue;
      final t = _squares[nr * 8 + nf];
      if (t == null || t.color != c) out.add(Move(sq, nr * 8 + nf));
    }
    return out;
  }

  List<Move> _kingMoves(int sq, int f, int r, ChessColor c) {
    final out = <Move>[];
    for (final (df, dr) in _kingDeltas) {
      final nf = f + df, nr = r + dr;
      if (!_onBoard(nf, nr)) continue;
      final t = _squares[nr * 8 + nf];
      if (t == null || t.color != c) out.add(Move(sq, nr * 8 + nf));
    }
    // Roque
    final backRank = c == ChessColor.white ? 0 : 7;
    if (r == backRank) {
      final kingsideBit = c == ChessColor.white ? 1 : 4;
      final queensideBit = c == ChessColor.white ? 2 : 8;
      if (castlingRights & kingsideBit != 0 &&
          _squares[backRank * 8 + 5] == null &&
          _squares[backRank * 8 + 6] == null &&
          _squares[backRank * 8 + 7] != null &&
          _squares[backRank * 8 + 7]!.type == PieceType.rook &&
          _squares[backRank * 8 + 7]!.color == c) {
        out.add(Move(sq, sq + 2, flags: Move.flagKingCastle));
      }
      if (castlingRights & queensideBit != 0 &&
          _squares[backRank * 8 + 1] == null &&
          _squares[backRank * 8 + 2] == null &&
          _squares[backRank * 8 + 3] == null &&
          _squares[backRank * 8 + 0] != null &&
          _squares[backRank * 8 + 0]!.type == PieceType.rook &&
          _squares[backRank * 8 + 0]!.color == c) {
        out.add(Move(sq, sq - 2, flags: Move.flagQueenCastle));
      }
    }
    return out;
  }

  List<Move> _sliding(int sq, int f, int r, ChessColor c, List<(int, int)> dirs) {
    final out = <Move>[];
    for (final (df, dr) in dirs) {
      var ff = f + df, rr = r + dr;
      while (_onBoard(ff, rr)) {
        final t = _squares[rr * 8 + ff];
        if (t == null) {
          out.add(Move(sq, rr * 8 + ff));
        } else {
          if (t.color != c) out.add(Move(sq, rr * 8 + ff));
          break;
        }
        ff += df;
        rr += dr;
      }
    }
    return out;
  }

  List<Move> _pawnMoves(int sq, int f, int r, ChessColor c) {
    final out = <Move>[];
    final dir = c == ChessColor.white ? 1 : -1;
    final startRank = c == ChessColor.white ? 1 : 6;
    final promoRank = c == ChessColor.white ? 7 : 0;
    final nr = r + dir;
    if (!_onBoard(f, nr)) return out;
    final isPromo = nr == promoRank;

    void addStraight(int to, {bool withPromo = false, int flags = Move.flagNone}) {
      if (withPromo) {
        for (final pt in const [
          PieceType.queen,
          PieceType.rook,
          PieceType.bishop,
          PieceType.knight,
        ]) {
          out.add(Move(sq, to, promotion: pt, flags: flags | Move.flagPromotion));
        }
      } else {
        out.add(Move(sq, to, flags: flags));
      }
    }

    // Frente
    if (_squares[nr * 8 + f] == null) {
      addStraight(nr * 8 + f, withPromo: isPromo);
      final nr2 = r + 2 * dir;
      if (r == startRank && _squares[nr2 * 8 + f] == null) {
        out.add(Move(sq, nr2 * 8 + f, flags: Move.flagDoublePush));
      }
    }
    // Capturas diagonais + en passant
    for (final df in const [-1, 1]) {
      final nf = f + df;
      if (!_onBoard(nf, nr)) continue;
      final t = _squares[nr * 8 + nf];
      if (t != null && t.color != c) {
        addStraight(nr * 8 + nf, withPromo: isPromo);
      } else if (epSquare == nr * 8 + nf) {
        out.add(Move(sq, nr * 8 + nf, flags: Move.flagEnPassant));
      }
    }
    return out;
  }

  // ------------------------------------------------------------------
  // Aplicar / desfazer
  // ------------------------------------------------------------------

  bool isLegal(Move m) => legalMoves().any((x) => x == m);

  /// Converte UCI ("e2e4", "e7e8q") em Move, se for lance legal.
  Move? moveFromUci(String uci) {
    if (uci.length < 4 || uci.length > 5) return null;
    final int from, to;
    try {
      from = _parseSq(uci.substring(0, 2));
      to = _parseSq(uci.substring(2, 4));
    } catch (_) {
      return null;
    }
    PieceType? promo;
    if (uci.length == 5) {
      promo = switch (uci[4].toLowerCase()) {
        'q' => PieceType.queen,
        'r' => PieceType.rook,
        'b' => PieceType.bishop,
        'n' => PieceType.knight,
        _ => null,
      };
      if (promo == null) return null;
    }
    final candidates = legalMoves()
        .where((m) => m.from == from && m.to == to && m.promotion == promo);
    return candidates.isEmpty ? null : candidates.first;
  }

  void makeMove(Move m) {
    if (!isLegal(m)) {
      throw StateError('Lance ilegal: ${m.uci}');
    }
    _makeMoveInternal(m);
  }

  void _makeMoveInternal(Move m) {
    final moving = _squares[m.from]!;
    final captured = _squares[m.to];
    Piece? epCaptured;
    if (m.flags & Move.flagEnPassant != 0) {
      final capSq = m.to + (moving.color == ChessColor.white ? -8 : 8);
      epCaptured = _squares[capSq];
      _squares[capSq] = null;
    }
    _history.add((
      from: m.from,
      to: m.to,
      promo: m.promotion,
      flags: m.flags,
      captured: captured ?? epCaptured,
      castlingRights: castlingRights,
      epSquare: epSquare,
      halfmoveClock: halfmoveClock,
    ));

    _squares[m.from] = null;
    // Roque: a torre acompanha o rei (torre h1->f1 ou a1->d1)
    if (m.flags & Move.flagKingCastle != 0) {
      final rook = _squares[m.to + 1]!;
      _squares[m.to + 1] = null;
      _squares[m.to - 1] = rook;
    } else if (m.flags & Move.flagQueenCastle != 0) {
      final rook = _squares[m.to - 2]!;
      _squares[m.to - 2] = null;
      _squares[m.to + 1] = rook;
    }
    _squares[m.to] =
        m.promotion != null ? Piece(m.promotion!, moving.color) : moving;

    // Atualiza roque
    if (moving.type == PieceType.king) {
      castlingRights &= (moving.color == ChessColor.white ? 0x3 : 0xC) ^ 0xF;
    }
    if (moving.type == PieceType.rook) {
      if (m.from == 0) castlingRights &= ~2;
      if (m.from == 7) castlingRights &= ~1;
      if (m.from == 56) castlingRights &= ~8;
      if (m.from == 63) castlingRights &= ~4;
    }
    if (captured != null && captured.type == PieceType.rook) {
      if (m.to == 0) castlingRights &= ~2;
      if (m.to == 7) castlingRights &= ~1;
      if (m.to == 56) castlingRights &= ~8;
      if (m.to == 63) castlingRights &= ~4;
    }

    // En passant alvo
    epSquare = m.flags & Move.flagDoublePush != 0 ? (m.from + m.to) ~/ 2 : null;

    halfmoveClock = (moving.type == PieceType.pawn ||
            captured != null ||
            epCaptured != null)
        ? 0
        : halfmoveClock + 1;
    if (moving.color == ChessColor.black) fullmoveNumber++;
    turn = moving.color == ChessColor.white ? ChessColor.black : ChessColor.white;
  }

  void undoMove() {
    if (_history.isEmpty) return;
    final h = _history.removeLast();
    final moved = _squares[h.to]!;
    _squares[h.from] = h.promo != null ? Piece(PieceType.pawn, moved.color) : moved;
    if (h.flags & Move.flagEnPassant != 0) {
      final capSq = h.to + (h.from ~/ 8 < h.to ~/ 8 ? -8 : 8);
      _squares[h.to] = null;
      _squares[capSq] = h.captured;
    } else if (h.flags & Move.flagKingCastle != 0) {
      _squares[h.to + 1] = _squares[h.to - 1];
      _squares[h.to - 1] = null;
      _squares[h.to] = null;
    } else if (h.flags & Move.flagQueenCastle != 0) {
      _squares[h.to - 2] = _squares[h.to + 1];
      _squares[h.to + 1] = null;
      _squares[h.to] = null;
    } else {
      _squares[h.to] = h.captured;
    }
    castlingRights = h.castlingRights;
    epSquare = h.epSquare;
    halfmoveClock = h.halfmoveClock;
    turn = turn == ChessColor.white ? ChessColor.black : ChessColor.white;
    if (turn == ChessColor.black) fullmoveNumber--;
  }

  // ------------------------------------------------------------------
  // Xeque / mate / afogado
  // ------------------------------------------------------------------

  bool _inCheck(ChessColor c) {
    final k = kingSquare(c);
    return k != null &&
        isAttacked(k, c == ChessColor.white ? ChessColor.black : ChessColor.white);
  }

  bool get inCheck => _inCheck(turn);

  bool get isCheckmate {
    if (!inCheck) return false;
    return legalMoves().isEmpty;
  }

  bool get isStalemate {
    if (inCheck) return false;
    return legalMoves().isEmpty;
  }

  bool get isGameOver => isCheckmate || isStalemate;

  // ------------------------------------------------------------------
  // SAN (para exibição)
  // ------------------------------------------------------------------

  String sanFor(Move m) {
    if (m.flags & Move.flagKingCastle != 0) return 'O-O';
    if (m.flags & Move.flagQueenCastle != 0) return 'O-O-O';
    final moving = _squares[m.from]!;
    final captured = _squares[m.to] != null || m.flags & Move.flagEnPassant != 0;
    _makeMoveInternal(m);
    final isCheck = _inCheck(turn);
    final isMate = legalMoves().isEmpty && isCheck;
    undoMove();

    final suffix = isMate ? '#' : (isCheck ? '+' : '');
    final base =
        m.promotion != null ? '=${_promoChar(m.promotion!).toUpperCase()}' : '';

    if (moving.type == PieceType.pawn) {
      return (captured ? '${_sqName(m.from)[0]}x${_sqName(m.to)}' : _sqName(m.to)) +
          base +
          suffix;
    }
    final pieceChar = switch (moving.type) {
      PieceType.knight => 'N',
      PieceType.bishop => 'B',
      PieceType.rook => 'R',
      PieceType.queen => 'Q',
      PieceType.king => 'K',
      _ => '',
    };
    // Desambiguação
    String disamb = '';
    final same = <Move>[];
    for (var i = 0; i < 64; i++) {
      final p = _squares[i];
      if (p == null ||
          p.type != moving.type ||
          p.color != moving.color ||
          i == m.from) {
        continue;
      }
      for (final cm in _movesFrom(i, p)) {
        if (cm.to == m.to && cm.promotion == m.promotion) {
          _makeMoveInternal(cm);
          final ok = !_inCheck(p.color); // rei de quem move não pode ficar em xeque
          undoMove();
          if (ok) same.add(cm);
        }
      }
    }
    if (same.isNotEmpty) {
      final sameFile = same.any((x) => x.from % 8 == m.from % 8);
      final sameRank = same.any((x) => x.from ~/ 8 == m.from ~/ 8);
      if (!sameFile) {
        disamb = _sqName(m.from)[0];
      } else if (!sameRank) {
        disamb = _sqName(m.from)[1];
      } else {
        disamb = _sqName(m.from);
      }
    }
    return '$pieceChar$disamb${captured ? 'x' : ''}${_sqName(m.to)}$base$suffix';
  }
}
