// ==============================================================================
// File: lib/theme/app_theme.dart
// Description: Material theme factory from ThemeTokens packs
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-18
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';

/// Known [AppTheme.materialThemeFor] `uiFontFamily` values (UI-P18). Null
/// keeps the app default IBM Plex Sans body / Fraunces display pairing.
const List<String> kUiFontFamilyOptions = <String>[
  'ibmPlexSans',
  'openSans',
  'roboto',
  'georgia',
];

/// User-facing labels for [kUiFontFamilyOptions], plus the null default.
String uiFontFamilyLabel(String? family) {
  switch (family) {
    case 'ibmPlexSans':
      return 'IBM Plex Sans';
    case 'openSans':
      return 'Open Sans';
    case 'roboto':
      return 'Roboto';
    case 'georgia':
      return 'Georgia';
    default:
      return 'System default';
  }
}

abstract final class AppTheme {
  static ThemeData materialThemeFor(
    ThemeId themeId, {
    ThemeTokens? tokensOverride,
    String? uiFontFamily,
    double uiFontSizeScale = 1.0,
    Color? uiTextColorOverride,
  }) {
    final ThemeTokens tokens = tokensOverride ?? ThemeTokens.forId(themeId);
    final Color bodyColor = uiTextColorOverride ?? tokens.text;
    final TextTheme baseText = _bodyTextThemeFor(uiFontFamily);
    final TextStyle display = _displayStyleFor(uiFontFamily);

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
            bodyColor: bodyColor,
            displayColor: bodyColor,
            fontSizeFactor: uiFontSizeScale,
          )
          .copyWith(
            headlineMedium: display.copyWith(
              color: bodyColor,
              fontWeight: FontWeight.w600,
              fontSize: 22 * uiFontSizeScale,
              letterSpacing: -0.4,
            ),
            titleLarge: display.copyWith(
              color: bodyColor,
              fontWeight: FontWeight.w600,
              fontSize: 20 * uiFontSizeScale,
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

  static TextTheme _bodyTextThemeFor(String? family) {
    switch (family) {
      case 'ibmPlexSans':
        return GoogleFonts.ibmPlexSansTextTheme();
      case 'openSans':
        return GoogleFonts.openSansTextTheme();
      case 'roboto':
        return GoogleFonts.robotoTextTheme();
      case 'georgia':
        return const TextTheme().apply(fontFamily: 'Georgia');
      default:
        return GoogleFonts.ibmPlexSansTextTheme();
    }
  }

  static TextStyle _displayStyleFor(String? family) {
    switch (family) {
      case 'ibmPlexSans':
        return GoogleFonts.ibmPlexSans();
      case 'openSans':
        return GoogleFonts.openSans();
      case 'roboto':
        return GoogleFonts.roboto();
      case 'georgia':
        return const TextStyle(fontFamily: 'Georgia');
      default:
        return GoogleFonts.fraunces();
    }
  }
}

ThemeTokens tokensOf(BuildContext context) =>
    Theme.of(context).extension<ThemeTokens>() ??
    ThemeTokens.forId(ThemeId.dark);
