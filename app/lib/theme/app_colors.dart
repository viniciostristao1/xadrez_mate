import 'package:flutter/material.dart';

/// Uma paleta completa do app (imutável). É trocável em runtime pelo
/// `ThemeService`; os widgets continuam lendo as cores por `AppColors.x`.
@immutable
class AppPalette {
  final String id;
  final String nome;

  // Fundos
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;

  // Texto
  final Color text;
  final Color dim;
  final Color faint;

  // Destaque
  final Color accent;
  final Color ok;
  final Color danger;

  // Tabuleiro
  final Color lightSquare;
  final Color darkSquare;
  final Color select;
  final Color hint;
  final Color lastMove;
  final Color check;

  const AppPalette({
    required this.id,
    required this.nome,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.dim,
    required this.faint,
    required this.accent,
    required this.ok,
    required this.danger,
    required this.lightSquare,
    required this.darkSquare,
    required this.select,
    required this.hint,
    required this.lastMove,
    required this.check,
  });

  /// Tema padrão: escuro âmbar ("painel de xadrez").
  static const amber = AppPalette(
    id: 'amber',
    nome: 'Âmbar Clássico',
    background: Color(0xFF121417),
    surface: Color(0xFF1B1E23),
    surfaceAlt: Color(0xFF23272E),
    border: Color(0xFF2E333B),
    text: Color(0xFFEDEFF2),
    dim: Color(0xFF9AA3AE),
    faint: Color(0xFF6B737C),
    accent: Color(0xFFE8A33D),
    ok: Color(0xFF4CAF7D),
    danger: Color(0xFFE05A4E),
    lightSquare: Color(0xFFEAE3C8),
    darkSquare: Color(0xFF9C7A54),
    select: Color(0xFFFFE08A),
    hint: Color(0x99FFFFFF),
    lastMove: Color(0x33E8A33D),
    check: Color(0xFFE05A4E),
  );

  /// Tema alternativo: dourado dramático sobre marrom escuro.
  static const crimson = AppPalette(
    id: 'crimson',
    nome: 'Carmesim & Ouro',
    background: Color(0xFF14100F),
    surface: Color(0xFF1F1817),
    surfaceAlt: Color(0xFF2B201E),
    border: Color(0xFF402C28),
    text: Color(0xFFF4EAE4),
    dim: Color(0xFFBBA097),
    faint: Color(0xFF8A5C4E),
    accent: Color(0xFFE0B24B),
    ok: Color(0xFF4CAF7D),
    danger: Color(0xFFE05A4E),
    lightSquare: Color(0xFFEAE3C8),
    darkSquare: Color(0xFF9C7A54),
    select: Color(0xFFF0CE7A),
    hint: Color(0x99FFFFFF),
    lastMove: Color(0x33E0B24B),
    check: Color(0xFFE05A4E),
  );

  /// Todos os temas disponíveis (a ordem é a ordem do seletor).
  static const all = <AppPalette>[amber, crimson];

  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => amber);
}

/// Fachada de cores do app. Os widgets usam sempre `AppColors.x`; a paleta
/// ativa é trocada em runtime por `AppColors.apply` (chamado pelo
/// `ThemeService`) seguido de um rebuild da raiz.
abstract final class AppColors {
  static AppPalette _active = AppPalette.amber;

  static AppPalette get active => _active;
  static void apply(AppPalette palette) => _active = palette;

  // Fundos
  static Color get background => _active.background;
  static Color get surface => _active.surface;
  static Color get surfaceAlt => _active.surfaceAlt;
  static Color get border => _active.border;

  // Texto
  static Color get text => _active.text;
  static Color get dim => _active.dim;
  static Color get faint => _active.faint;

  // Destaque
  static Color get accent => _active.accent; // âmbar (tabuleiro)
  static Color get ok => _active.ok;
  static Color get danger => _active.danger;

  // Tabuleiro
  static Color get lightSquare => _active.lightSquare;
  static Color get darkSquare => _active.darkSquare;
  static Color get select => _active.select;
  static Color get hint => _active.hint; // pontinhos de casas disponíveis
  static Color get lastMove => _active.lastMove;
  static Color get check => _active.check;
}
