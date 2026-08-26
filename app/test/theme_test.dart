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

  test('troca para Carmesim & Ouro aplica em AppColors e persiste', () async {
    await ThemeService.instance.load();
    await ThemeService.instance.setPalette(AppPalette.crimson);

    expect(ThemeService.instance.palette.id, 'crimson');
    // AppColors espelha a paleta ativa.
    expect(AppColors.accent, AppPalette.crimson.accent);
    expect(AppColors.background, AppPalette.crimson.background);

    // Recarrega "do disco": a escolha persistiu.
    await ThemeService.instance.load();
    expect(ThemeService.instance.palette.id, 'crimson');
    expect(AppColors.accent, AppPalette.crimson.accent);

    // Volta ao padrão para não vazar estado entre testes.
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
