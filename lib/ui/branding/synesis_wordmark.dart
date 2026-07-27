// ==============================================================================
// File: lib/ui/branding/synesis_wordmark.dart
// Description: Locked Option B stealth lowercase synesis wordmark widget.
// Component: UI / Branding
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-23
// ==============================================================================

import 'package:flutter/material.dart';

/// Brand gradient for Option B wordmark glyphs (locked tokens).
const List<Color> kSynesisWordmarkGradient = <Color>[
  Color(0xFF7B2CBF), // Electric Amethyst
  Color(0xFF3A7BD5), // Transition blue
  Color(0xFF00B4D8), // Teal Cyan
];

/// Continuous lowercase `synesis` wordmark with the locked brand gradient.
///
/// Used in the desktop title bar and phone navigation drawer. Optional
/// [showIcon] pairs the Data Envelope v2 mark with the wordmark (drawer
/// header). Line height is kept above 1.0 so the `y` descender is not clipped
/// by [ShaderMask] (which otherwise paints a white speck under the glyph).
class SynesisWordmark extends StatelessWidget {
  const SynesisWordmark({
    super.key,
    this.fontSize = 16,
    this.semanticsLabel = 'synesis',
    this.showIcon = false,
    this.iconSize,
  });

  final double fontSize;
  final String semanticsLabel;

  /// When true, shows the Data Envelope icon to the left of the wordmark.
  final bool showIcon;

  /// Icon square size; defaults to slightly larger than [fontSize].
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final double resolvedIconSize = iconSize ?? (fontSize + 6);
    final Widget wordmark = Padding(
      // Extra bottom pad so ShaderMask bounds include the `y` descender.
      padding: const EdgeInsets.only(bottom: 3, top: 1),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: kSynesisWordmarkGradient,
          ).createShader(bounds);
        },
        child: Text(
          'synesis',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.3,
            leadingDistribution: TextLeadingDistribution.even,
            color: Colors.white,
          ),
        ),
      ),
    );

    final Widget content = showIcon
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/branding/synesis_icon.png',
                width: resolvedIconSize,
                height: resolvedIconSize,
                filterQuality: FilterQuality.medium,
                semanticLabel: 'synesis icon',
              ),
              const SizedBox(width: 8),
              wordmark,
            ],
          )
        : wordmark;

    return Semantics(
      label: semanticsLabel,
      child: content,
    );
  }
}
