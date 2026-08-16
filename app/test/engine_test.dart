import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xadrez_mate/engine/chess.dart';

void main() {
  final refRaw = File('test/data/legal_moves.json').readAsStringSync();
  final ref = jsonDecode(refRaw) as List<dynamic>;

  group('Motor vs python-chess (referência de ${ref.length} posições)', () {
    for (final entry in ref) {
      final fen = entry['fen'] as String;
      final expected = ((entry['legal'] as List).cast<String>()).toSet();
      test('lances legais de $fen', () {
        final b = Board.fen(fen);
        final got = b.legalMoves().map((m) => m.uci).toSet();
        expect(got, expected, reason: 'lances legais divergentes em $fen');

        final expectedCheck = entry['check'] as bool;
        final expectedMate = entry['mate'] as bool;
        final expectedStale = entry['stalemate'] as bool;
        expect(b.inCheck, expectedCheck, reason: 'xeque divergente em $fen');
        expect(b.isCheckmate, expectedMate, reason: 'mate divergente em $fen');
        expect(b.isStalemate, expectedStale, reason: 'afogado divergente em $fen');
      });
    }
  });

  group('FEN ida e volta', () {
    test('posição inicial', () {
      final b = Board.fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
      expect(
        b.fen,
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
    });

    test('roque direitos e en passant', () {
      final b = Board.fen('r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq e3 0 1');
      expect(b.castlingRights, 0xF);
      expect(b.epSquare, 20);
      final b2 = Board.fen(b.fen);
      expect(b2.castlingRights, 0xF);
      expect(b2.epSquare, 20);
    });

    test('undo restaura FEN exata', () {
      final fen = 'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4';
      final b = Board.fen(fen);
      for (final m in [
        Move(11, 27), // d2d4
        Move(51, 35), // d7d5
        Move(1, 18), // b1c3
        Move(61, 52), // f8e7
        Move(2, 29), // c1f4
        Move(59, 43), // d8d6
      ]) {
        b.makeMove(m);
      }
      while (b.moveCount > 0) {
        b.undoMove();
      }
      expect(b.fen, fen);
    });
  });

  group('Regras específicas', () {
    // helper: lances da peça numa casa específica
    List<Move> movesFrom(Board b, String sq) {
      final s = 'abcdefgh'.indexOf(sq[0]) + int.parse(sq[1]) * 8 - 8;
      return b.legalMoves().where((m) => m.from == s).toList();
    }

    test('cavalo só faz L a partir de d4', () {
      final b = Board.fen('8/8/8/8/3N4/8/8/K6k w - - 0 1');
      final moves = movesFrom(b, 'd4').map((m) => m.uci).toList()..sort();
      expect(moves, ['d4b3', 'd4b5', 'd4c2', 'd4c6', 'd4e2', 'd4e6', 'd4f3', 'd4f5']);
    });

    test('cavalo em b1 só faz L (sem wrap)', () {
      final b = Board.fen('8/8/8/8/8/8/8/1N5K w - - 0 1');
      final moves = movesFrom(b, 'b1').map((m) => m.uci).toSet();
      expect(moves, {'b1a3', 'b1c3', 'b1d2'});
    });

    test('bispo só diagonal a partir de d4', () {
      final b = Board.fen('8/8/8/8/3B4/8/8/K6k w - - 0 1');
      final moves = movesFrom(b, 'd4').map((m) => m.uci).toList()..sort();
      // a1 tem o próprio rei branco -> bispo não vai lá
      expect(moves, [
        'd4a7', 'd4b2', 'd4b6', 'd4c3', 'd4c5', 'd4e3', 'd4e5',
        'd4f2', 'd4f6', 'd4g1', 'd4g7', 'd4h8',
      ]);
    });

    test('torre só reta a partir de d4', () {
      final b = Board.fen('8/8/8/8/3R4/8/8/K6k w - - 0 1');
      final moves = movesFrom(b, 'd4').map((m) => m.uci).toList()..sort();
      expect(moves, [
        'd4a4', 'd4b4', 'd4c4', 'd4d1', 'd4d2', 'd4d3', 'd4d5', 'd4d6',
        'd4d7', 'd4d8', 'd4e4', 'd4f4', 'd4g4', 'd4h4',
      ]);
    });

    test('peão: en passant disponível, nunca captura reto', () {
      final b = Board.fen('rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3');
      final moves = b.legalMoves().map((m) => m.uci).toList();
      expect(moves.contains('e5f6'), isTrue, reason: 'en passant e5xf6');
      expect(moves.contains('e5d6'), isFalse, reason: 'peão não captura reto');
      expect(moves.contains('e5d5'), isFalse, reason: 'peão não captura para trás');
    });

    test('peão preto anda só para frente (a3)', () {
      final b = Board.fen('k7/8/8/8/8/p7/8/K7 b - - 0 1');
      final moves = movesFrom(b, 'a3').map((m) => m.uci).toList()..sort();
      expect(moves, ['a3a2']);
    });

    test('promoção gera 4 lances', () {
      final b = Board.fen('8/1P6/8/8/8/8/8/k6K w - - 0 1');
      final promos = b.legalMoves().where((m) => m.promotion != null).toList();
      expect(promos.length, 4);
      expect(
        promos.map((m) => m.uci).toSet(),
        {'b7b8b', 'b7b8n', 'b7b8q', 'b7b8r'},
      );
    });

    test('roque: rei não pode atravessar casa atacada', () {
      final b = Board.fen('r3k2r/pppppppp/8/8/8/3b4/PPPP1PPP/R3K2R w KQkq - 0 1');
      final moves = b.legalMoves().map((m) => m.uci).toList();
      expect(moves.contains('e1g1'), isFalse, reason: 'f1 atacada pelo bispo d3');
      expect(moves.contains('e1c1'), isTrue, reason: 'd1 não atacada');
    });

    test('roque: bloqueado por peça própria', () {
      final b = Board.fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
      final moves = b.legalMoves().map((m) => m.uci).toList();
      expect(moves.contains('e1g1'), isFalse);
      expect(moves.contains('e1c1'), isFalse);
    });

    test('roque: inválido com rei em xeque', () {
      final b = Board.fen('r3k2r/pppppppp/8/8/8/2b5/PPP1PPPP/R3K2R w KQkq - 0 1');
      final moves = b.legalMoves().map((m) => m.uci).toList();
      expect(moves.contains('e1g1'), isFalse);
      expect(moves.contains('e1c1'), isFalse);
    });

    test('roque válido e torre acompanha (ida e volta)', () {
      final b = Board.fen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      final g1 = b.legalMoves().firstWhere((m) => m.uci == 'e1g1');
      b.makeMove(g1);
      expect(b.pieceAt(6)!.type, PieceType.king);
      expect(b.pieceAt(5)!.type, PieceType.rook);
      expect(b.pieceAt(7), isNull);
      expect(b.pieceAt(4), isNull);
      expect(b.fen, 'r3k2r/8/8/8/8/8/8/R4RK1 b kq - 1 1');
      b.undoMove();
      expect(b.pieceAt(4)!.type, PieceType.king);
      expect(b.pieceAt(7)!.type, PieceType.rook);
      expect(b.pieceAt(5), isNull);
      expect(b.pieceAt(6), isNull);
      expect(b.fen, 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    });

    test('roque dama: torre acompanha e FEN confere', () {
      final b = Board.fen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
      final c1 = b.legalMoves().firstWhere((m) => m.uci == 'e1c1');
      b.makeMove(c1);
      expect(b.pieceAt(2)!.type, PieceType.king);
      expect(b.pieceAt(3)!.type, PieceType.rook);
      expect(b.pieceAt(0), isNull);
      expect(b.pieceAt(4), isNull);
      b.undoMove();
      expect(b.fen, 'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
    });

    test('peça cravada não pode sair da linha do pin', () {
      final b = Board.fen('4r2k/8/8/8/8/8/4R3/4K3 w - - 0 1');
      final moves = b.legalMoves().map((m) => m.uci).toList();
      expect(moves.contains('e2d2'), isFalse, reason: 'torre cravada não sai da fileira');
      expect(moves.contains('e2f2'), isFalse);
      expect(moves.contains('e2e3'), isTrue, reason: 'pode andar ao longo do pin');
      expect(moves.contains('e2e7'), isTrue);
    });

    test('rei não vai para casa atacada', () {
      final b = Board.fen('k7/8/8/8/8/8/8/K1r5 w - - 0 1');
      final moves = b.legalMoves().map((m) => m.uci).toList();
      expect(moves.contains('a1b1'), isFalse, reason: 'b1 atacada pela torre c1');
      expect(moves.contains('a1a2'), isTrue);
    });

    test('xeque-mate detectado (Qxe8#)', () {
      final b = Board.fen('4r1k1/5ppp/8/8/8/8/8/R3Q1K1 w - - 0 1');
      expect(b.isCheckmate, isFalse);
      b.makeMove(b.legalMoves().firstWhere((m) => m.uci == 'e1e8'));
      expect(b.isCheckmate, isTrue);
      expect(b.isGameOver, isTrue);
    });

    test('mate de corredor (Ra8#)', () {
      final b = Board.fen('6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1');
      b.makeMove(b.legalMoves().firstWhere((m) => m.uci == 'a1a8'));
      expect(b.isCheckmate, isTrue);
    });

    test('en passant: aplica e desfaz', () {
      final b = Board.fen('rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3');
      final m = b.legalMoves().firstWhere((x) => x.uci == 'e5f6');
      b.makeMove(m);
      expect(b.pieceAt(37), isNull, reason: 'peão f5 capturado');
      expect(b.pieceAt(45)!.type, PieceType.pawn, reason: 'peão branco em f6');
      b.undoMove();
      expect(b.pieceAt(37)!.color, ChessColor.black);
      expect(b.pieceAt(45), isNull);
      expect(b.fen, 'rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3');
    });

    test('promoção: aplica e desfaz', () {
      final b = Board.fen('8/1P6/8/8/8/8/8/k6K w - - 0 1');
      final m = b.legalMoves().firstWhere((x) => x.uci == 'b7b8q');
      b.makeMove(m);
      expect(b.pieceAt(57)!.type, PieceType.queen);
      b.undoMove();
      expect(b.pieceAt(49)!.type, PieceType.pawn);
      expect(b.pieceAt(57), isNull);
    });

    test('SAN: desambiguação de cavalos (b1 e f3 -> d2)', () {
      final b = Board.fen('8/8/8/8/8/5N2/8/1N5K w - - 0 1');
      final san = b.legalMoves().map((m) => b.sanFor(m)).toSet();
      expect(san.contains('Nbd2'), isTrue);
      expect(san.contains('Nfd2'), isTrue);
    });

    test('SAN: desambiguação de torres na mesma coluna', () {
      final b = Board.fen('k7/8/8/8/R7/8/8/R6K w - - 0 1');
      final san = b.legalMoves().map((m) => b.sanFor(m)).toSet();
      expect(san.contains('Ra3'), isFalse, reason: 'ambíguo sem desambiguação');
      expect(san.contains('R1a3+'), isTrue);
      expect(san.contains('R4a3+'), isTrue);
    });

    test('SAN: xeque e mate', () {
      final b = Board.fen('k7/8/8/8/8/8/8/KR6 w - - 0 1');
      expect(b.sanFor(b.legalMoves().firstWhere((m) => m.uci == 'b1b8')), 'Rb8+');
      final b2 = Board.fen('6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1');
      expect(b2.sanFor(b2.legalMoves().firstWhere((m) => m.uci == 'a1a8')), 'Ra8#');
    });

    test('peão promovendo com xeque no SAN', () {
      final b = Board.fen('4k3/3P4/8/8/8/8/8/4K3 w - - 0 1');
      final m = b.legalMoves().firstWhere((x) => x.uci == 'd7d8q');
      expect(b.sanFor(m), 'd8=Q+');
    });
  });
}
