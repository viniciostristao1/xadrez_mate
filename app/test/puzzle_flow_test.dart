import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/engine/chess.dart';
import 'package:xadrez_mate/models/puzzle.dart';
import 'package:xadrez_mate/services/rating_service.dart';
import 'package:xadrez_mate/screens/puzzle_screen.dart';
import 'package:xadrez_mate/theme/app_theme.dart';
import 'package:xadrez_mate/widgets/chess_board.dart';
import 'package:xadrez_mate/widgets/piece_icon.dart';

/// Testa o fluxo completo de resolução de problemas com o banco REAL
/// (assets/puzzles.json): lances certos avançam, errados avisam na hora.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  final raw = File('assets/puzzles.json').readAsStringSync();
  final puzzles = ((jsonDecode(raw) as Map<String, dynamic>)['puzzles'] as List)
      .map((p) => Puzzle.fromJson(p as Map<String, dynamic>))
      .toList();

  // Centro da casa no board (orientação = lado a jogar embaixo)
  Offset sqCenter(WidgetTester tester, String sq, ChessColor bottom) {
    final rect = tester.getRect(find.byType(ChessBoard));
    final s = 'abcdefgh'.indexOf(sq[0]) + int.parse(sq[1]) * 8 - 8;
    final col = s % 8;
    final row = bottom == ChessColor.white ? 7 - s ~/ 8 : s ~/ 8;
    final sqSize = rect.width / 8;
    return rect.topLeft + Offset((col + 0.5) * sqSize, (row + 0.5) * sqSize);
  }

  Future<void> pumpPuzzle(WidgetTester tester, Puzzle p) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: PuzzleScreen(
        puzzle: p,
        pieceStyle: PieceStyle.leipzig,
        onPieceStyleChanged: (_) {},
        onNext: () {},
        onExit: () {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Toca a sequência de lances corretos resolvendo o problema.
  Future<void> solve(WidgetTester tester, Puzzle p) async {
    final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));
    for (var guard = 0; guard < 12 && !screen.testSolved; guard++) {
      final node = screen.testNode;
      final key = node.keys.first;
      await tester.tapAt(sqCenter(tester, key.substring(0, 2), p.sideToMove));
      await tester.pumpAndSettle();
      await tester.tapAt(sqCenter(tester, key.substring(2, 4), p.sideToMove));
      await tester.pumpAndSettle();
    }
  }

  group('Fluxo de resolução (banco real)', () {
    PuzzleScreenState screenSolved(WidgetTester tester) =>
        tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));
    testWidgets('mate em 1: resolver mostra sucesso', (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 1);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));
      expect(screen.testSolved, isFalse);

      await solve(tester, p);

      expect(screen.testSolved, isTrue);
      expect(find.textContaining('Xeque-mate'), findsWidgets);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('mate em 2: dois lances + respostas do rival', (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 2);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));

      await solve(tester, p);

      expect(screen.testSolved, isTrue);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('mate em 3: três lances do jogador', (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 3);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));

      await solve(tester, p);

      expect(screen.testSolved, isTrue);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('lance errado: avisa na hora e não avança', (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 1);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));

      final wrong = screen.testBoard
          .legalMoves()
          .firstWhere((m) => m.uci != p.tree.keys.first);
      await tester.tapAt(sqCenter(tester, _sq(wrong.from), p.sideToMove));
      await tester.pumpAndSettle();
      await tester.tapAt(sqCenter(tester, _sq(wrong.to), p.sideToMove));
      await tester.pumpAndSettle();

      expect(screen.testSolved, isFalse, reason: 'não resolve com lance errado');
      expect(screen.testFeedback, contains('incorreto'));
      // Tabuleiro continua na posição inicial (recomeça do último lance certo)
      expect(screen.testBoard.fen, p.fen);
    });

    testWidgets('selecionar peça marca só as casas legais', (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 1);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));

      final key = p.tree.keys.first;
      final fromSq = key.substring(0, 2);
      await tester.tapAt(sqCenter(tester, fromSq, p.sideToMove));
      await tester.pumpAndSettle();

      final from = _parseSq(fromSq);
      expect(screen.testSelected, from);
      // Casas marcadas = lances LEGAIS da peça (regras de xadrez), não mais
      final expected = screen.testBoard
          .legalMoves()
          .where((m) => m.from == from)
          .map((m) => m.to)
          .toSet();
      expect(screen.testTargets, expected);
      expect(screen.testTargets, isNotEmpty);
    });

    testWidgets('problema com pretas a jogar (tabuleiro invertido)',
        (tester) async {
      final p = puzzles.firstWhere(
          (x) => x.sideToMove == ChessColor.black && x.mate == 1);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));

      await solve(tester, p);

      expect(screen.testSolved, isTrue);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('lâmpada (dica) revela o lance correto', (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 1);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));

      final key = p.tree.keys.first;
      await tester.tap(find.byIcon(Icons.lightbulb_outline));
      await tester.pumpAndSettle();

      expect(screen.testFeedback, contains('Dica'));
      expect(screen.testHintFrom, _parseSq(key.substring(0, 2)));
      expect(screen.testHintTo, _parseSq(key.substring(2, 4)));
      // jogar o lance da dica resolve o mate em 1
      await tester.tapAt(sqCenter(tester, key.substring(0, 2), p.sideToMove));
      await tester.pumpAndSettle();
      await tester.tapAt(sqCenter(tester, key.substring(2, 4), p.sideToMove));
      await tester.pumpAndSettle();
      expect(screen.testSolved, isTrue);
    });

    testWidgets('flecha circular refaz o problema (zera cronômetro)',
        (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 1);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));

      // comete um erro (não resolve)
      final wrong = screen.testBoard
          .legalMoves()
          .firstWhere((m) => m.uci != p.tree.keys.first);
      await tester.tapAt(sqCenter(tester, _sq(wrong.from), p.sideToMove));
      await tester.pumpAndSettle();
      await tester.tapAt(sqCenter(tester, _sq(wrong.to), p.sideToMove));
      await tester.pumpAndSettle();
      expect(screen.testErrors, greaterThan(0));
      await tester.pump(const Duration(seconds: 2));
      expect(screen.testElapsed, greaterThanOrEqualTo(2), reason: 'cronômetro rodou');

      final elapsedAntes = screen.testElapsed;
      final refreshFinder = find.byIcon(Icons.refresh);
      expect(refreshFinder.evaluate().length, 1);
      await tester.tap(refreshFinder, warnIfMissed: true);
      await tester.pumpAndSettle();

      expect(screen.testErrors, 0, reason: 'erros zerados');
      // cronômetro zerou (elapsed < antes do refresh)
      expect(screen.testElapsed, lessThan(elapsedAntes), reason: 'cronômetro zerado');
      expect(screen.testBoard.fen, p.fen);
      expect(screen.testSolved, isFalse);
    });

    testWidgets('cronômetro corre enquanto não resolve e para no mate',
        (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 1);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));

      await tester.pump(const Duration(seconds: 3));
      expect(screen.testElapsed, 3);

      await solve(tester, p);
      expect(screen.testSolved, isTrue);
      final frozen = screen.testElapsed;
      await tester.pump(const Duration(seconds: 2));
      expect(screen.testElapsed, frozen, reason: 'cronômetro parou no mate');
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('modo surpresa não revela o nº de lances', (tester) async {
      // puzzle de mate 2 rodando em modo surpresa
      final p = puzzles.firstWhere((x) => x.mate == 2);
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: PuzzleScreen(
          puzzle: p,
          pieceStyle: PieceStyle.leipzig,
          onPieceStyleChanged: (_) {},
          onNext: () {},
          onExit: () {},
          surpresa: true,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Mate aleatório'), findsOneWidget);
      expect(find.textContaining('lance 1 de 2'), findsNothing);
      expect(find.textContaining('de 2'), findsNothing);
      expect(find.textContaining('de 3'), findsNothing);

      await solve(tester, p);
      expect(screenSolved(tester).testSolved, isTrue);
      expect(find.textContaining('Xeque-mate! Você conseguiu!'), findsOneWidget);
    });

    testWidgets('seta de próximo sempre visível à direita do refazer',
        (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 1);
      await pumpPuzzle(tester, p);
      // antes de resolver já existe (pular problema)
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      await solve(tester, p);
      // após resolver, continua; e o card mostra o parabéns sem "Lance final"
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(find.textContaining('Xeque-mate! Você conseguiu!'), findsOneWidget);
      expect(find.textContaining('Lance final'), findsNothing);
    });

    testWidgets('pausar cronômetro congela o tempo; retomar segue',
        (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 1);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));

      await tester.pump(const Duration(seconds: 3));
      expect(screen.testElapsed, 3);

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();
      final parado = screen.testElapsed;
      await tester.pump(const Duration(seconds: 2));
      expect(screen.testElapsed, parado, reason: 'pausado não incrementa');
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      expect(screen.testElapsed, parado + 2, reason: 'retomou o cronômetro');
    });

    testWidgets('clique em peça inimiga não seleciona', (tester) async {
      final p = puzzles.firstWhere((x) => x.mate == 1);
      await pumpPuzzle(tester, p);
      final screen = tester.state<PuzzleScreenState>(find.byType(PuzzleScreen));
      final opp = p.sideToMove == ChessColor.white
          ? ChessColor.black
          : ChessColor.white;
      final oppKing = screen.testBoard.kingSquare(opp)!;
      await tester.tapAt(sqCenter(tester, _sq(oppKing), p.sideToMove));
      await tester.pumpAndSettle();
      expect(screen.testSelected, isNull);
      expect(screen.testTargets, isEmpty);
    });
  });
}

int _parseSq(String s) => 'abcdefgh'.indexOf(s[0]) + int.parse(s[1]) * 8 - 8;
String _sq(int sq) => 'abcdefgh'[sq % 8] + '12345678'[sq ~/ 8];
