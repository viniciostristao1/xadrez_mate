import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/services/board_service.dart';
import 'package:xadrez_mate/services/theme_service.dart';
import 'package:xadrez_mate/theme/app_colors.dart';
import 'package:xadrez_mate/theme/board_style.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.instance.load();
    await ThemeService.instance.setPalette(AppPalette.azulRoyal);
    await BoardService.instance.load();
    await BoardService.instance.setStyle(BoardStyle.doTema);
  });

  test('padrão é "Do tema" (tabuleiro segue a paleta)', () async {
    await BoardService.instance.load();
    expect(BoardService.instance.style.id, 'doTema');
    expect(AppColors.lightSquare, AppPalette.azulRoyal.lightSquare);
    expect(AppColors.darkSquare, AppPalette.azulRoyal.darkSquare);
  });

  test('Lichess aplica casas marrons e persiste', () async {
    await BoardService.instance.setStyle(BoardStyle.lichess);

    expect(AppColors.lightSquare, const Color(0xFFF0D9B5));
    expect(AppColors.darkSquare, const Color(0xFFB58863));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('board_style'), 'lichess');

    // Persistiu: um novo load (como reabrir o app) mantém o estilo.
    await BoardService.instance.load();
    expect(BoardService.instance.style.id, 'lichess');
    expect(AppColors.lightSquare, const Color(0xFFF0D9B5));
  });

  test('trocar o tema do app NÃO muda o tabuleiro fixado', () async {
    await BoardService.instance.setStyle(BoardStyle.lichess);
    await ThemeService.instance.setPalette(AppPalette.minimalOutline);

    expect(AppColors.lightSquare, const Color(0xFFF0D9B5));
    expect(AppColors.darkSquare, const Color(0xFFB58863));
  });

  test('byId cai em "Do tema" para id desconhecido ou nulo', () {
    expect(BoardStyle.byId('inexistente').id, 'doTema');
    expect(BoardStyle.byId(null).id, 'doTema');
  });

  test('todos os estilos têm id único e nome não vazio', () {
    final ids = BoardStyle.all.map((b) => b.id).toSet();
    expect(ids.length, BoardStyle.all.length);
    for (final b in BoardStyle.all) {
      expect(b.nome, isNotEmpty);
    }
  });
}
