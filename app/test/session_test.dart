import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/engine/chess.dart';
import 'package:xadrez_mate/models/puzzle.dart';
import 'package:xadrez_mate/screens/puzzle_screen.dart';
import 'package:xadrez_mate/screens/session_screen.dart';
import 'package:xadrez_mate/theme/app_theme.dart';
import 'package:xadrez_mate/widgets/chess_board.dart';
import 'package:xadrez_mate/widgets/piece_icon.dart';

/// Sessão de treino: resolve a sequência e confere o resumo.
void main() {
  final raw = File('assets/puzzles.json').readAsStringSync();
  final puzzles = ((jsonDecode(raw) as Map<String, dynamic>)['puzzles'] as List)
      .map((p) => Puzzle.fromJson(p as Map<String, dynamic>))
      .toList();

  Offset sqCenter(WidgetTester tester, String sq, ChessColor bottom) {
    final rect = tester.getRect(find.byType(ChessBoard));
    final s = 'abcdefgh'.indexOf(sq[0]) + int.parse(sq[1]) * 8 - 8;
    final col = s % 8;
    final row = bottom == ChessColor.white ? 7 - s ~/ 8 : s ~/ 8;
    final sqSize = rect.width / 8;
    return rect.topLeft + Offset((col + 0.5) * sqSize, (row + 0.5) * sqSize);
  }

  Future<void> pumpSession(
      WidgetTester tester, List<Puzzle> seq) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: SessionScreen(
        puzzles: seq,
        size: seq.length,
        pieceStyle: PieceStyle.emoji,
        onPieceStyleChanged: (_) {},
        onExit: () {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> resolveAtual(WidgetTester tester, Puzzle p) async {
    final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));
    for (var guard = 0; guard < 10 && !screen.testSolved; guard++) {
      final node = screen.testNode;
      final key = node.keys.first;
      await tester.tapAt(sqCenter(tester, key.substring(0, 2), p.sideToMove));
      await tester.pumpAndSettle();
      await tester.tapAt(sqCenter(tester, key.substring(2, 4), p.sideToMove));
      await tester.pumpAndSettle();
    }
    expect(screen.testSolved, isTrue);
  }

  testWidgets('sessão: resolve 2 problemas e mostra resumo', (tester) async {
    final mate1 = puzzles.where((x) => x.mate == 1).take(2).toList();
    await pumpSession(tester, mate1);

    // Problema 1
    expect(find.text('Sessão 1 de 2'), findsOneWidget);
    await resolveAtual(tester, mate1[0]);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    // Problema 2
    expect(find.text('Sessão 2 de 2'), findsOneWidget);
    await resolveAtual(tester, mate1[1]);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    // Resumo
    expect(find.text('Fim da sessão'), findsOneWidget);
    expect(find.textContaining('Problemas resolvidos'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Refazer sessão'), findsOneWidget);
  });

  testWidgets('sessão: erros acumulam no resumo', (tester) async {
    final p = puzzles.firstWhere((x) => x.mate == 1);
    await pumpSession(tester, [p]);

    final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));
    final wrong = screen.testBoard
        .legalMoves()
        .firstWhere((m) => m.uci != p.tree.keys.first);
    await tester.tapAt(sqCenter(tester, _sq(wrong.from), p.sideToMove));
    await tester.pumpAndSettle();
    await tester.tapAt(sqCenter(tester, _sq(wrong.to), p.sideToMove));
    await tester.pumpAndSettle();

    await resolveAtual(tester, p);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.text('Fim da sessão'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    // 1 erro no resumo
    expect(find.text('1'), findsWidgets);
  });
}

String _sq(int sq) => 'abcdefgh'[sq % 8] + '12345678'[sq ~/ 8];
