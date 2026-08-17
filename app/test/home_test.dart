import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xadrez_mate/screens/home_screen.dart';
import 'package:xadrez_mate/theme/app_theme.dart';
import 'package:xadrez_mate/widgets/piece_icon.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester, PieceStyle style) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: HomeScreen(
        onDbLoaded: () async {},
        pieceStyle: style,
        onPieceStyleChanged: (_) {},
        onStartPuzzle: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('home mostra as 3 categorias com os 3 níveis', (tester) async {
    await pumpHome(tester, PieceStyle.merida);
    expect(find.text('Mate em 1'), findsOneWidget);
    expect(find.text('Mate em 2'), findsOneWidget);
    expect(find.text('Mate em 3'), findsOneWidget);
    expect(find.text('Fácil'), findsNWidgets(3));
    expect(find.text('Médio'), findsNWidgets(3));
    expect(find.text('Difícil'), findsNWidgets(3));
  });

  testWidgets('os 3 estilos de peça renderizam', (tester) async {
    for (final style in PieceStyle.values) {
      await pumpHome(tester, style);
      expect(
        find.byType(PieceIcon),
        findsWidgets,
        reason: 'estilo ${style.label} sem ícones',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'erro ao renderizar ${style.label}');
    }
  });
}
