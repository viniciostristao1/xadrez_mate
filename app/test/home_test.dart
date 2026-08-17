import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/services/i18n.dart';
import 'package:xadrez_mate/services/rating_service.dart';
import 'package:xadrez_mate/screens/home_screen.dart';
import 'package:xadrez_mate/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pump(WidgetTester tester, {VoidCallback? onConfig}) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await RatingService.instance.load();
    await I18n.instance.load();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: HomeScreen(
        onMates: () {},
        onTatica: () {},
        onDefesa: () {},
        onConfig: onConfig ?? () {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('página principal tem Mates e Tática', (tester) async {
    await pump(tester);
    expect(find.text('Mateflow'), findsOneWidget);
    expect(find.text('Mates'), findsOneWidget);
    expect(find.text('Tática'), findsOneWidget);
    expect(find.text('Defesa'), findsOneWidget);
  });

  testWidgets('engrenagem abre configurações com idioma e peças',
      (tester) async {
    var aberto = false;
    await pump(tester, onConfig: () => aberto = true);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(aberto, isTrue);
  });
}
