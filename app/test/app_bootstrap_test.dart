import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/data/defesa_db.dart';
import 'package:xadrez_mate/data/puzzle_db.dart';
import 'package:xadrez_mate/data/tatica_db.dart';
import 'package:xadrez_mate/main.dart';

/// Garante que o app SAI da tela de carregamento (bootstrap completo com os
/// assets reais do pubspec) — regressão do "spinner infinito + tela preta"
/// causado por asset não declarado no pubspec.
void main() {
  testWidgets('bootstrap carrega e mostra a página principal', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MateflowApp());
    // rootBundle só resolve em runAsync (fake async do teste não dispara);
    // no aparelho real isso acontece normalmente.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    // Não pode ficar no spinner
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Home principal visível
    expect(find.text('Mateflow'), findsOneWidget);
    expect(find.text('Mates'), findsOneWidget);
    expect(find.text('Tática'), findsOneWidget);
    expect(find.text('Defesa'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('clicar em Mates e Tática navega para as telas', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MateflowApp());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(find.text('Mates'), findsOneWidget);

    // Mates
    await tester.tap(find.text('Mates'));
    await tester.pumpAndSettle();
    expect(find.text('Mate em 1'), findsOneWidget);
    expect(find.text('Mate em 2'), findsOneWidget);
    expect(find.text('Mate em 3'), findsOneWidget);
    // volta
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Mates'), findsOneWidget);

    // Tática
    await tester.tap(find.text('Tática'));
    await tester.pumpAndSettle();
    expect(find.text('Espeto'), findsOneWidget);
    expect(find.text('Descoberta'), findsOneWidget);
    expect(find.text('Sacrifício'), findsOneWidget);
    // volta
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Defesa
    await tester.tap(find.text('Defesa'));
    await tester.pumpAndSettle();
    expect(find.text('Defender contra mate'), findsOneWidget);
    expect(find.text('Salvar uma peça'), findsOneWidget);
    expect(find.text('Encontrar contra-ataque'), findsOneWidget);
    expect(find.text('Neutralizar uma ameaça'), findsOneWidget);
    expect(find.text('Defesa precisa'), findsOneWidget);
  });

  testWidgets('Defesa tem exercícios em todos os níveis', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MateflowApp());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1500)));
    await tester.pumpAndSettle();
    debugPrint('puzzles: ${PuzzleDb.instance.countFor(1)} '
        'tatica: ${TaticaDb.instance.countTema("espeto")} '
        'defesa: ${DefesaDb.instance.countTema("defenderMate")}');

    await tester.tap(find.text('Defesa'));
    await tester.pumpAndSettle();

    final counts = tester
        .widgetList<Text>(find.descendant(
          of: find.byType(Card),
          matching: find.byType(Text),
        ))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => int.tryParse(s) != null)
        .map(int.parse)
        .toList();
    debugPrint('defesa contagens: $counts');
    expect(counts.length, greaterThanOrEqualTo(15));
    for (final c in counts) {
      expect(c, greaterThan(0), reason: 'tema/nível sem exercícios');
    }

    // clicar num nível entra no primeiro exercício
    await tester.tap(find.text('Fácil').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget,
        reason: 'deveria abrir um exercício de defesa');
  });

  testWidgets('Tática tem exercícios em todos os níveis', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MateflowApp());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tática'));
    await tester.pumpAndSettle();

    // contagens > 0 nos 9 botões (3 temas x 3 níveis)
    final counts = tester
        .widgetList<Text>(find.descendant(
          of: find.byType(Card),
          matching: find.byType(Text),
        ))
        .map((t) => t.data)
        .whereType<String>()
        .where((s) => int.tryParse(s) != null)
        .map(int.parse)
        .toList();
    expect(counts.length, greaterThanOrEqualTo(9));
    for (final c in counts) {
      expect(c, greaterThan(0), reason: 'tema/nível sem exercícios');
    }

    // clicar num nível entra no primeiro exercício
    await tester.tap(find.text('Fácil').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget,
        reason: 'deveria abrir um exercício tático');
  });

  testWidgets('fila de mates: próximo avança e voltar retorna',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MateflowApp());
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fácil').first); // Mate em 1 · Fácil
    await tester.pumpAndSettle();

    // entrou num problema
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

    // seta para a direita (pular) avança para outro problema (id muda)
    int problemaAtual() => int.parse(tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.startsWith('Problema '))
        .split(' ')[1]);
    final primeiro = problemaAtual();
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    final segundo = problemaAtual();
    expect(segundo, isNot(primeiro), reason: 'avançou para outro problema');

    // flecha para a esquerda (voltar) retorna à página de Mates
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Mate em 1'), findsOneWidget);
  });
}
