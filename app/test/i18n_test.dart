import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xadrez_mate/services/i18n.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('idioma padrão é português', () async {
    await I18n.instance.load();
    expect(I18n.instance.idioma, Idioma.pt);
    expect(S.mates, 'Mates');
    expect(S.facil, 'Fácil');
  });

  test('muda para inglês e espanhol', () async {
    await I18n.instance.load();
    await I18n.instance.setIdioma(Idioma.en);
    expect(S.xequeMate, 'Checkmate! You got it!');
    expect(S.facil, 'Easy');
    expect(S.dicaJogue('Qh4#'), 'Hint: play Qh4#');

    await I18n.instance.setIdioma(Idioma.es);
    expect(S.xequeMate, '¡Jaque mate! ¡Lo lograste!');
    expect(S.dificil, 'Difícil');
    expect(S.espeto, 'Pincho');
  });

  test('preferência de idioma persiste', () async {
    await I18n.instance.load();
    await I18n.instance.setIdioma(Idioma.es);
    // recarrega "do disco"
    await I18n.instance.load();
    expect(I18n.instance.idioma, Idioma.es);
  });
}
