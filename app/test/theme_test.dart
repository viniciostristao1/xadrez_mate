import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/services/theme_service.dart';
import 'package:xadrez_mate/theme/app_colors.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tema padrão é Âmbar Clássico', () async {
    await ThemeService.instance.load();
    expect(ThemeService.instance.palette.id, 'amber');
    expect(AppColors.accent, AppPalette.amber.accent);
  });

  test('troca para Azul Royal aplica em AppColors e persiste', () async {
    await ThemeService.instance.load();
    await ThemeService.instance.setPalette(AppPalette.azulRoyal);

    expect(ThemeService.instance.palette.id, 'azulRoyal');
    expect(AppColors.accent, AppPalette.azulRoyal.accent);
    expect(AppColors.background, AppPalette.azulRoyal.background);

    await ThemeService.instance.load();
    expect(ThemeService.instance.palette.id, 'azulRoyal');
    expect(AppColors.accent, AppPalette.azulRoyal.accent);

    await ThemeService.instance.setPalette(AppPalette.amber);
  });

  test('troca para Minimal Outline aplica', () async {
    await ThemeService.instance.load();
    await ThemeService.instance.setPalette(AppPalette.minimalOutline);
    expect(ThemeService.instance.palette.id, 'minimalOutline');
    expect(AppColors.accent, AppPalette.minimalOutline.accent);
    await ThemeService.instance.setPalette(AppPalette.amber);
  });

  test('byId cai no padrão (âmbar) para id desconhecido ou nulo', () {
    expect(AppPalette.byId('inexistente').id, 'amber');
    expect(AppPalette.byId(null).id, 'amber');
  });

  test('todos os temas têm id único e nome não vazio', () {
    final ids = AppPalette.all.map((p) => p.id).toSet();
    expect(ids.length, AppPalette.all.length);
    for (final p in AppPalette.all) {
      expect(p.nome, isNotEmpty);
    }
  });
}
