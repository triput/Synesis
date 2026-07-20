// ==============================================================================
// File: lib/ui/branding/bytemail_wordmark.dart
// Description: Locked Option B stealth lowercase bytemail wordmark widget.
// Component: UI / Branding
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:flutter/material.dart';

/// Brand gradient for Option B wordmark glyphs (locked tokens).
const List<Color> kBytemailWordmarkGradient = <Color>[
  Color(0xFF7B2CBF), // Electric Amethyst
  Color(0xFF3A7BD5), // Transition blue
  Color(0xFF00B4D8), // Teal Cyan
];

/// Continuous lowercase `bytemail` wordmark with the locked brand gradient.
///
/// Used in the desktop title bar; Windows has no separate splash — this plus
/// the Data Envelope v2 `.ico` carry brand presence.
class BytemailWordmark extends StatelessWidget {
  const BytemailWordmark({
    super.key,
    this.fontSize = 16,
    this.semanticsLabel = 'bytemail',
  });

  final double fontSize;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: kBytemailWordmarkGradient,
          ).createShader(bounds);
        },
        child: Text(
          'bytemail',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
