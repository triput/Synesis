// ==============================================================================
// File: lib/theme/app_theme.dart
// Description: Material theme factory from ThemeTokens packs
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';

abstract final class AppTheme {
  static ThemeData materialThemeFor(ThemeId themeId) {
    final tokens = ThemeTokens.forId(themeId);
    final baseText = GoogleFonts.ibmPlexSansTextTheme();
    final display = GoogleFonts.fraunces();

    final scheme = ColorScheme(
      brightness: tokens.brightness,
      primary: tokens.teal,
      onPrimary: tokens.onAccent,
      secondary: tokens.amethyst,
      onSecondary: tokens.onAccent,
      error: tokens.coral,
      onError: tokens.onAccent,
      surface: tokens.panel,
      onSurface: tokens.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.ink,
      textTheme: baseText
          .apply(
            bodyColor: tokens.text,
            displayColor: tokens.text,
          )
          .copyWith(
            headlineMedium: display.copyWith(
              color: tokens.text,
              fontWeight: FontWeight.w600,
              fontSize: 22,
              letterSpacing: -0.4,
            ),
            titleLarge: display.copyWith(
              color: tokens.text,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
      extensions: <ThemeExtension<dynamic>>[tokens],
      dividerColor: tokens.line,
      cardColor: tokens.panel,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.panel2,
        contentTextStyle: TextStyle(color: tokens.text),
      ),
    );
  }
}

ThemeTokens tokensOf(BuildContext context) =>
    Theme.of(context).extension<ThemeTokens>() ??
    ThemeTokens.forId(ThemeId.dark);
