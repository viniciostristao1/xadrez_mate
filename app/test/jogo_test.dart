import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/engine/chess.dart';
import 'package:xadrez_mate/services/i18n.dart';
import 'package:xadrez_mate/screens/jogar_home_screen.dart';
import 'package:xadrez_mate/screens/jogo_screen.dart';
import 'package:xadrez_mate/theme/app_theme.dart';
import 'package:xadrez_mate/widgets/chess_board.dart';
import 'package:xadrez_mate/widgets/piece_icon.dart';

/// Testa o modo Jogar: partida completa, nota de precisão por lance,
/// resposta do rival e o botão de voltar lance.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Centro da casa no tabuleiro (orientação = cor do jogador embaixo).
  Offset sqCenter(WidgetTester tester, String sq, ChessColor bottom) {
    final rect = tester.getRect(find.byType(ChessBoard));
    final s = 'abcdefgh'.indexOf(sq[0]) + int.parse(sq[1]) * 8 - 8;
    final col = s % 8;
    final row = bottom == ChessColor.white ? 7 - s ~/ 8 : s ~/ 8;
    final sqSize = rect.width / 8;
    return rect.topLeft + Offset((col + 0.5) * sqSize, (row + 0.5) * sqSize);
  }

  Future<void> tapSq(
      WidgetTester tester, String sq, ChessColor bottom) async {
    await tester.tapAt(sqCenter(tester, sq, bottom));
  }

  Future<void> pumpJogo(
    WidgetTester tester, {
    ChessColor cor = ChessColor.white,
    int nivel = 3,
    String? fen,
  }) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await I18n.instance.load();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: JogoScreen(
        pieceStyle: PieceStyle.leipzig,
        level: nivel,
        userColor: cor,
        onExit: () {},
        fenInicial: fen ?? Board.fenInicial,
        analysisDepth: 1,
        rivalDelay: const Duration(milliseconds: 10),
      ),
    ));
    await tester.pumpAndSettle();
  }

  JogoScreenState screenOf(WidgetTester tester) =>
      tester.state<JogoScreenState>(find.byType(JogoScreen));

  testWidgets('tela Jogar: escolhe a cor e o nível e inicia', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await I18n.instance.load();
    int? nivel;
    ChessColor? cor;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: JogarHomeScreen(
        onStart: (n, c) {
          nivel = n;
          cor = c;
        },
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pretas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Difícil'));
    await tester.pumpAndSettle();

    expect(nivel, 3);
    expect(cor, ChessColor.black);
  });

  testWidgets('com brancas: nota de precisão e resposta do rival',
      (tester) async {
    await pumpJogo(tester);
    final screen = screenOf(tester);
    expect(screen.testBoard.turn, ChessColor.white);
    expect(screen.testPensando, isFalse);

    await tapSq(tester, 'e2', ChessColor.white);
    await tester.pump();
    await tapSq(tester, 'e4', ChessColor.white);
    await tester.pump();

    expect(screen.testSanMoves.length, 1);
    expect(screen.testQualidades.single, isNotNull);
    expect(screen.testSnapshots, 1);
    expect(screen.testPensando, isTrue);

    // Rival responde depois do atraso.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(screen.testSanMoves.length, 2);
    expect(screen.testBoard.turn, ChessColor.white);
    expect(screen.testPensando, isFalse);
  });

  testWidgets('voltar lance desfaz o lance do jogador e a resposta do rival',
      (tester) async {
    await pumpJogo(tester);
    final screen = screenOf(tester);

    await tapSq(tester, 'e2', ChessColor.white);
    await tester.pump();
    await tapSq(tester, 'e4', ChessColor.white);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(screen.testSanMoves.length, 2);

    await tester.tap(find.byTooltip(S.voltaLance));
    await tester.pumpAndSettle();

    expect(screen.testSanMoves, isEmpty);
    expect(screen.testBoard.fen, Board.fenInicial);
    expect(screen.testSnapshots, 0);
    expect(screen.testBoard.turn, ChessColor.white);
  });

  testWidgets('pausar e retomar o cronômetro', (tester) async {
    await pumpJogo(tester);
    final screen = screenOf(tester);

    await tester.tap(find.byTooltip(S.pausar));
    await tester.pump();
    expect(screen.testPausado, isTrue);
    expect(find.textContaining(S.pausado), findsOneWidget);

    await tester.tap(find.byTooltip(S.retomar));
    await tester.pump();
    expect(screen.testPausado, isFalse);
  });

  testWidgets('com pretas: o rival abre a partida', (tester) async {
    await pumpJogo(tester, cor: ChessColor.black);
    final screen = screenOf(tester);

    expect(screen.testSanMoves.length, 1);
    expect(screen.testQualidades.single, isNull); // lance do rival
    expect(screen.testBoard.turn, ChessColor.black); // vez do jogador
    expect(screen.testPensando, isFalse);
  });

  testWidgets('jogador dá xeque-mate: vitória e nova partida', (tester) async {
    const fen = '6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1';
    await pumpJogo(tester, fen: fen);
    final screen = screenOf(tester);

    await tapSq(tester, 'e1', ChessColor.white);
    await tester.pump();
    await tapSq(tester, 'e8', ChessColor.white);
    await tester.pumpAndSettle();

    expect(screen.testFim, FimDeJogo.vitoria);
    expect(screen.testSnapshots, 1);
    expect(find.textContaining(S.voceVenceu), findsWidgets);

    // Nova partida volta à posição inicial.
    await tester.tap(find.text(S.novaPartida));
    await tester.pumpAndSettle();
    expect(screen.testFim, isNull);
    expect(screen.testSanMoves, isEmpty);
    expect(screen.testBoard.fen, fen);
  });

  testWidgets('layout não estoura em tela pequena (360x640)', (tester) async {
    const fen = '6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1';
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await I18n.instance.load();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: JogoScreen(
        pieceStyle: PieceStyle.merida,
        level: 3,
        userColor: ChessColor.white,
        onExit: () {},
        fenInicial: fen,
        analysisDepth: 1,
        rivalDelay: const Duration(milliseconds: 10),
      ),
    ));
    await tester.pumpAndSettle();

    // Joga até o xeque-mate e confere o card final no espaço restante.
    await tapSq(tester, 'e1', ChessColor.white);
    await tester.pump();
    await tapSq(tester, 'e8', ChessColor.white);
    await tester.pumpAndSettle();
    expect(screenOf(tester).testFim, FimDeJogo.vitoria);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rival dá xeque-mate: derrota', (tester) async {
    const fen = '6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1';
    await pumpJogo(tester, cor: ChessColor.black, fen: fen);
    final screen = screenOf(tester);

    expect(screen.testFim, FimDeJogo.derrota);
    expect(screen.testSanMoves.length, 1);
    expect(find.textContaining(S.rivalVenceu), findsWidgets);
  });
}
