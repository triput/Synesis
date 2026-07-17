// ==============================================================================
// File: lib/ui/shell/mail_split_layout.dart
// Description: Shared list/reading split driven by ReadingPanePosition + Visual Focus
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:bytemail/settings/app_settings_state.dart';

/// Keys used by widget tests to assert pane visibility and axis.
abstract final class MailSplitLayoutKeys {
  static const Key sidebar = Key('mail_split_sidebar');
  static const Key list = Key('mail_split_list');
  static const Key reading = Key('mail_split_reading');
  static const Key horizontalSplit = Key('mail_split_horizontal');
  static const Key verticalSplit = Key('mail_split_vertical');
  static const Key visualFocus = Key('mail_split_visual_focus');
}

/// True for phone-class portrait: keep the legacy horizontal list|reading split
/// and ignore [ReadingPanePosition] top/bottom preferences.
bool isPortraitMobileLayout(BuildContext context) {
  final Size size = MediaQuery.sizeOf(context);
  final Orientation orientation = MediaQuery.orientationOf(context);
  return orientation == Orientation.portrait && size.shortestSide < 600;
}

/// Single layout builder for mailbox list + reading panes.
///
/// Account rail stays outside this widget. Visual Focus hides sidebar and list
/// when [visualFocusActive] is true; reading stays maximized.
class MailSplitLayout extends StatelessWidget {
  const MailSplitLayout({
    super.key,
    required this.position,
    required this.visualFocusActive,
    required this.showSidebar,
    required this.sidebarWidth,
    required this.listWidth,
    required this.forceHorizontalSplit,
    this.sidebar,
    required this.listPane,
    required this.readingPane,
  });

  final ReadingPanePosition position;
  final bool visualFocusActive;
  final bool showSidebar;
  final double sidebarWidth;
  final double listWidth;

  /// When true (portrait mobile), always use the horizontal list|reading split.
  final bool forceHorizontalSplit;

  final Widget? sidebar;
  final Widget listPane;
  final Widget readingPane;

  @override
  Widget build(BuildContext context) {
    final Widget readingSlot = KeyedSubtree(
      key: MailSplitLayoutKeys.reading,
      child: readingPane,
    );

    if (visualFocusActive) {
      return Row(
        key: MailSplitLayoutKeys.visualFocus,
        children: <Widget>[
          Expanded(child: readingSlot),
        ],
      );
    }

    final Widget? sidebarSlot = showSidebar && sidebar != null
        ? SizedBox(
            key: MailSplitLayoutKeys.sidebar,
            width: sidebarWidth,
            child: sidebar,
          )
        : null;

    final Widget listSlot = KeyedSubtree(
      key: MailSplitLayoutKeys.list,
      child: listPane,
    );

    final ReadingPanePosition effective =
        forceHorizontalSplit ? ReadingPanePosition.right : position;

    switch (effective) {
      case ReadingPanePosition.right:
        return Row(
          key: MailSplitLayoutKeys.horizontalSplit,
          children: <Widget>[
            if (sidebarSlot != null) sidebarSlot,
            SizedBox(width: listWidth, child: listSlot),
            Expanded(child: readingSlot),
          ],
        );
      case ReadingPanePosition.bottom:
        return Row(
          children: <Widget>[
            if (sidebarSlot != null) sidebarSlot,
            Expanded(
              child: Column(
                key: MailSplitLayoutKeys.verticalSplit,
                children: <Widget>[
                  Expanded(child: listSlot),
                  Expanded(child: readingSlot),
                ],
              ),
            ),
          ],
        );
      case ReadingPanePosition.top:
        return Row(
          children: <Widget>[
            if (sidebarSlot != null) sidebarSlot,
            Expanded(
              child: Column(
                key: MailSplitLayoutKeys.verticalSplit,
                children: <Widget>[
                  Expanded(child: readingSlot),
                  Expanded(child: listSlot),
                ],
              ),
            ),
          ],
        );
    }
  }
}
