// ==============================================================================
// File: lib/ui/common/empty_state.dart
// Description: Shared illustrated empty-state pattern with optional CTA (UI-P8)
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-08-03
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/density.dart';
import 'package:synesis/theme/theme_tokens.dart';

/// Calm empty surface for list/reading/search/account zero-data states.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.density = ViewDensity.calm,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final ViewDensity density;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final double titleSize = density.emptyStateTitleSize;
    final double bodySize = density.emptyStateBodySize;
    final Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: density.listRowPaddingH * 2,
        vertical: density.listRowPaddingV * 2,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: density.emptyStateIconSize, color: t.muted),
            SizedBox(height: density.listGap + 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.text,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.muted, fontSize: bodySize),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              SizedBox(height: density.listGap + 10),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );

    // When parent is a tight Expanded (Settings Accounts empty), Center+tall
    // content overflows by a few pixels (DEF-063 empty path, ~15px). Scroll
    // and min-height center when height-bounded.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedHeight) {
          return Center(child: content);
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
