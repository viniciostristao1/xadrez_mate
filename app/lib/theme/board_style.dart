import 'package:flutter/material.dart';

/// Estilo de TABULEIRO, independente do tema do app (`AppPalette`).
/// Cores nulas = usar as da paleta ativa. Só o tabuleiro (casas + seleção)
/// muda; o resto do app continua seguindo o `ThemeService`.
@immutable
class BoardStyle {
  final String id;
  final String nome;
  final Color? lightSquare;
  final Color? darkSquare;
  final Color? select;

  const BoardStyle({
    required this.id,
    required this.nome,
    this.lightSquare,
    this.darkSquare,
    this.select,
  });

  /// Padrão: o tabuleiro acompanha o tema (comportamento antigo).
  static const doTema = BoardStyle(id: 'doTema', nome: 'Do tema');

  /// Tabuleiro clássico do Lichess (marrom) + seleção âmbar do app.
  static const lichess = BoardStyle(
    id: 'lichess',
    nome: 'Lichess (marrom)',
    lightSquare: Color(0xFFF0D9B5),
    darkSquare: Color(0xFFB58863),
    select: Color(0xFFFFE08A),
  );

  /// Todos os estilos disponíveis (a ordem é a ordem do seletor).
  static const all = <BoardStyle>[doTema, lichess];

  static BoardStyle byId(String? id) =>
      all.firstWhere((b) => b.id == id, orElse: () => doTema);
}
