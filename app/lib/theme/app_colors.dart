import 'package:flutter/material.dart';

/// Cores do app (tema escuro "painel de xadrez").
abstract final class AppColors {
  // Fundos
  static const background = Color(0xFF121417);
  static const surface = Color(0xFF1B1E23);
  static const surfaceAlt = Color(0xFF23272E);
  static const border = Color(0xFF2E333B);

  // Texto
  static const text = Color(0xFFEDEFF2);
  static const dim = Color(0xFF9AA3AE);
  static const faint = Color(0xFF6B737C);

  // Destaque
  static const accent = Color(0xFFE8A33D); // âmbar (tabuleiro)
  static const ok = Color(0xFF4CAF7D);
  static const danger = Color(0xFFE05A4E);

  // Tabuleiro
  static const lightSquare = Color(0xFFEAE3C8);
  static const darkSquare = Color(0xFF9C7A54);
  static const select = Color(0xFFFFE08A);
  static const hint = Color(0x99FFFFFF); // pontinhos de casas disponíveis
  static const lastMove = Color(0x33E8A33D);
  static const check = Color(0xFFE05A4E);
}
