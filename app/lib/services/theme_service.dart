import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

/// Seleção do tema (paleta) do app, persistida em `shared_preferences`.
/// Espelha o padrão do `I18n`: singleton + `ValueNotifier` que a raiz do app
/// escuta para reconstruir a árvore com as cores novas.
class ThemeService {
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  static const _prefsKey = 'app_theme';

  final ValueNotifier<int> notifier = ValueNotifier(0);
  AppPalette _palette = AppPalette.azulRoyal;

  AppPalette get palette => _palette;

  /// Carrega a paleta salva (ou o padrão) e aplica ANTES do primeiro build.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _palette = AppPalette.byId(prefs.getString(_prefsKey));
    AppColors.apply(_palette);
    notifier.value++;
  }

  /// Troca a paleta ativa, notifica a raiz e persiste a escolha.
  Future<void> setPalette(AppPalette palette) async {
    if (_palette.id == palette.id) return;
    _palette = palette;
    AppColors.apply(palette);
    notifier.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, palette.id);
  }
}
