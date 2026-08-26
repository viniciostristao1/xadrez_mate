import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// ThemeData reconstruído a cada acesso a partir da paleta ativa em
  /// `AppColors`. Trocar de tema (`AppColors.apply`) + rebuild da raiz já
  /// aplica as cores novas — por isso os construtores abaixo NÃO são `const`.
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.danger,
          onSurface: AppColors.text,
          onPrimary: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: AppColors.border),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceAlt,
          contentTextStyle: TextStyle(color: AppColors.text, fontSize: 15),
          behavior: SnackBarBehavior.floating,
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          titleMedium: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(color: AppColors.text, height: 1.4),
          bodySmall: TextStyle(color: AppColors.dim, height: 1.4),
          labelLarge: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.4,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text,
            side: BorderSide(color: AppColors.border),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}
