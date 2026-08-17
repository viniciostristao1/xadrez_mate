import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/engine/chess.dart';
import 'package:xadrez_mate/models/tatica_puzzle.dart';
import 'package:xadrez_mate/screens/tatica_screen.dart';
import 'package:xadrez_mate/services/rating_service.dart';
import 'package:xadrez_mate/theme/app_theme.dart';
import 'package:xadrez_mate/widgets/chess_board.dart';
import 'package:xadrez_mate/widgets/piece_icon.dart';

/// Tela de TÁTICA: resolver a linha de solução (banco real).
void main() {
  final raw = File('assets/tatica.json').readAsStringSync();
  final puzzles = ((jsonDecode(raw) as Map<String, dynamic>)['puzzles'] as List)
      .map((p) => TaticaPuzzle.fromJson(p as Map<String, dynamic>))
      .toList();

  Offset sqCenter(WidgetTester tester, String sq, ChessColor bottom) {
    final rect = tester.getRect(find.byType(ChessBoard));
    final s = 'abcdefgh'.indexOf(sq[0]) + int.parse(sq[1]) * 8 - 8;
    final col = s % 8;
    final row = bottom == ChessColor.white ? 7 - s ~/ 8 : s ~/ 8;
    final sqSize = rect.width / 8;
    return rect.topLeft + Offset((col + 0.5) * sqSize, (row + 0.5) * sqSize);
  }

  Future<void> pumpTatica(WidgetTester tester, TaticaPuzzle p) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: TaticaScreen(
        puzzle: p,
        pieceStyle: PieceStyle.leipzig,
        onNext: () {},
        onExit: () {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('resolve a linha tática completa', (tester) async {
    final p = puzzles.first;
    await pumpTatica(tester, p);
    final screen =
        tester.state<TaticaScreenState>(find.byType(TaticaScreen));
    expect(screen.testSolved, isFalse);

    // joga todos os lances do jogador (índices pares da linha)
    for (final uci in p.linha.whereIndexed((i, _) => i.isEven)) {
      await tester.tapAt(sqCenter(tester, uci.substring(0, 2), p.sideToMove));
      await tester.pumpAndSettle();
      await tester.tapAt(sqCenter(tester, uci.substring(2, 4), p.sideToMove));
      await tester.pumpAndSettle();
    }

    expect(screen.testSolved, isTrue);
    expect(find.textContaining('conseguiu'), findsWidgets);
  });

  testWidgets('lance errado avisa e não avança', (tester) async {
    final p = puzzles.first;
    await pumpTatica(tester, p);
    final screen =
        tester.state<TaticaScreenState>(find.byType(TaticaScreen));

    final esperado = p.linha.first;
    final wrong = screen.testBoard
        .legalMoves()
        .firstWhere((m) => m.uci != esperado);
    await tester.tapAt(sqCenter(tester, _sq(wrong.from), p.sideToMove));
    await tester.pumpAndSettle();
    await tester.tapAt(sqCenter(tester, _sq(wrong.to), p.sideToMove));
    await tester.pumpAndSettle();

    expect(screen.testSolved, isFalse);
    expect(screen.testFeedback, contains('incorreto'));
    expect(screen.testBoard.fen, p.fen);
  });
}

extension on Iterable<String> {
  Iterable<String> whereIndexed(bool Function(int, String) test) sync* {
    var i = 0;
    for (final e in this) {
      if (test(i, e)) yield e;
      i++;
    }
  }
}

String _sq(int sq) => 'abcdefgh'[sq % 8] + '12345678'[sq ~/ 8];
