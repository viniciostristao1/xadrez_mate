import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
