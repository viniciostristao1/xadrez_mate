import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xadrez_mate/screens/mates_home_screen.dart';
import 'package:xadrez_mate/theme/app_theme.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MatesHomeScreen(
        onDbLoaded: () async {},
        onStartPuzzle: (_, __) {},
        onStartSurpresa: (_) {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra as 3 categorias com os 3 níveis', (tester) async {
    await pumpHome(tester);
    expect(find.text('Mate em 1'), findsOneWidget);
    expect(find.text('Mate em 2'), findsOneWidget);
    expect(find.text('Mate em 3'), findsOneWidget);
    // 3 categorias + Mate aleatório = 4 níveis de cada
    expect(find.text('Fácil'), findsNWidgets(4));
    expect(find.text('Médio'), findsNWidgets(4));
    expect(find.text('Difícil'), findsNWidgets(4));
  });

  testWidgets('rola até Mate aleatório e Evolução do rating', (tester) async {
    await pumpHome(tester);
    await tester.dragUntilVisible(
      find.text('Evolução do rating'),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    expect(find.text('Evolução do rating'), findsOneWidget);
    expect(find.text('Mate aleatório'), findsOneWidget);
  });

  testWidgets('as categorias cabem sem rolar em tela pequena (360x640)',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MatesHomeScreen(
        onDbLoaded: () async {},
        onStartPuzzle: (_, __) {},
        onStartSurpresa: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mate em 3'), findsOneWidget);
    // O card de Mate aleatório é o último da lista de categorias e tem de
    // terminar dentro da tela (só a Evolução do rating pode ficar abaixo).
    final surpresa = find.ancestor(
      of: find.text('Mate aleatório'),
      matching: find.byType(Card),
    );
    expect(tester.getBottomLeft(surpresa).dy, lessThanOrEqualTo(640));
  });
}
