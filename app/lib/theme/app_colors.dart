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

  static const azulRoyal = AppPalette(
    id: 'azulRoyal',
    nome: 'Azul Royal',
    background: Color(0xFF0A0F1C),
    surface: Color(0xFF121A2E),
    surfaceAlt: Color(0xFF1B2540),
    border: Color(0xFF24365E),
    text: Color(0xFFEAF0FB),
    dim: Color(0xFF8A95AB),
    faint: Color(0xFF5A6480),
    accent: Color(0xFF3B82F6),
    ok: Color(0xFF4CAF7D),
    danger: Color(0xFFE05A4E),
    lightSquare: Color(0xFFDDE8F0),
    darkSquare: Color(0xFF4A6FA5),
    select: Color(0xFF6EA8FE),
    hint: Color(0x99FFFFFF),
    lastMove: Color(0x333B82F6),
    check: Color(0xFFE05A4E),
  );

  static const minimalOutline = AppPalette(
    id: 'minimalOutline',
    nome: 'Minimal Outline',
    background: Color(0xFF0C0C0D),
    surface: Color(0xFF161617),
    surfaceAlt: Color(0xFF1E1E20),
    border: Color(0xFF3A3A3A),
    text: Color(0xFFF0EEE9),
    dim: Color(0xFF9A9A9A),
    faint: Color(0xFF6B6B6B),
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

  static const terracota = AppPalette(
    id: 'terracota',
    nome: 'Terracota',
    background: Color(0xFFF2E8D6),
    surface: Color(0xFFE0D1B9),
    surfaceAlt: Color(0xFFCBB897),
    border: Color(0xFFB8A08A),
    text: Color(0xFF382E20),
    dim: Color(0xFF8A7355),
    faint: Color(0xFF6B5A4A),
    accent: Color(0xFFB5652E),
    ok: Color(0xFF4CAF7D),
    danger: Color(0xFFC0392B),
    lightSquare: Color(0xFFEAE3C8),
    darkSquare: Color(0xFF9C7A54),
    select: Color(0xFFF0CE7A),
    hint: Color(0x66000000),
    lastMove: Color(0x33B5652E),
    check: Color(0xFFC0392B),
  );

  static const terracotaBloco = AppPalette(
    id: 'terracotaBloco',
    nome: 'Terracota Bloco',
    background: Color(0xFFFFF5E6),
    surface: Color(0xFFF2E8D6),
    surfaceAlt: Color(0xFFEADFC8),
    border: Color(0xFFD2B89A),
    text: Color(0xFF382E20),
    dim: Color(0xFF8A7355),
    faint: Color(0xFF6B5A4A),
    accent: Color(0xFFB5652E),
    ok: Color(0xFF4CAF7D),
    danger: Color(0xFFC0392B),
    lightSquare: Color(0xFFFFF5E6),
    darkSquare: Color(0xFFB5652E),
    select: Color(0xFFF0CE7A),
    hint: Color(0x66000000),
    lastMove: Color(0x33B5652E),
    check: Color(0xFFC0392B),
  );

  static const noiteEstrelada = AppPalette(
    id: 'noiteEstrelada',
    nome: 'Noite Estrelada',
    background: Color(0xFF0B1026),
    surface: Color(0xFF121A33),
    surfaceAlt: Color(0xFF1A2347),
    border: Color(0xFF2A3A5E),
    text: Color(0xFFE8EAF6),
    dim: Color(0xFF8A95C2),
    faint: Color(0xFF5A648A),
    accent: Color(0xFFFFD54F),
    ok: Color(0xFF4CAF7D),
    danger: Color(0xFFE05A4E),
    lightSquare: Color(0xFFE8EAF6),
    darkSquare: Color(0xFF2A3A6B),
    select: Color(0xFFFFE082),
    hint: Color(0x99FFFFFF),
    lastMove: Color(0x33FFD54F),
    check: Color(0xFFE05A4E),
  );

  static const escuroPremium = AppPalette(
    id: 'escuroPremium',
    nome: 'Escuro Premium',
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF121212),
    surfaceAlt: Color(0xFF1E1E1E),
    border: Color(0xFF2E2E2E),
    text: Color(0xFFEAEAEA),
    dim: Color(0xFF9A9A9A),
    faint: Color(0xFF6B6B6B),
    accent: Color(0xFFFFC857),
    ok: Color(0xFF4CAF7D),
    danger: Color(0xFFE05A4E),
    lightSquare: Color(0xFFEAEAEA),
    darkSquare: Color(0xFF4A4A4A),
    select: Color(0xFFFFE082),
    hint: Color(0x99FFFFFF),
    lastMove: Color(0x33FFC857),
    check: Color(0xFFE05A4E),
  );

  /// Todos os temas disponíveis (a ordem é a ordem do seletor).
  static const all = <AppPalette>[
    azulRoyal,
    minimalOutline,
    terracota,
    terracotaBloco,
    noiteEstrelada,
    escuroPremium,
  ];

  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => azulRoyal);
}

/// Fachada de cores do app. Os widgets usam sempre `AppColors.x`; a paleta
/// ativa é trocada em runtime por `AppColors.apply` (chamado pelo
/// `ThemeService`) seguido de um rebuild da raiz.
abstract final class AppColors {
  static AppPalette _active = AppPalette.azulRoyal;

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
