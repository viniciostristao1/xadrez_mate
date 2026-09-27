import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/board_style.dart';

/// Seleção do estilo de TABULEIRO, persistida em `shared_preferences`.
/// Espelha o `ThemeService`: singleton + `ValueNotifier` que a raiz do app
/// escuta para reconstruir a árvore com as cores novas.
class BoardService {
  static final BoardService instance = BoardService._();
  BoardService._();

  static const _prefsKey = 'board_style';

  final ValueNotifier<int> notifier = ValueNotifier(0);
  BoardStyle _style = BoardStyle.doTema;

  BoardStyle get style => _style;

  /// Carrega o estilo salvo (ou o padrão) e aplica ANTES do primeiro build.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _style = BoardStyle.byId(prefs.getString(_prefsKey));
    AppColors.applyBoard(_style);
    notifier.value++;
  }

  /// Troca o estilo ativo, notifica a raiz e persiste a escolha.
  Future<void> setStyle(BoardStyle style) async {
    if (_style.id == style.id) return;
    _style = style;
    AppColors.applyBoard(style);
    notifier.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, style.id);
  }
}
