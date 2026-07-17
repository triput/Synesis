// ==============================================================================
// File: lib/ui/shell/address_scope_action.dart
// Description: Sender/domain scope pickers for junk, Focus, and adaptive toolbars
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:bytemail/domain/address_match_scope.dart';
import 'package:bytemail/focus/focus_sender.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';

/// Shared sender/domain menu entries for all address-scope controls.
List<PopupMenuEntry<AddressMatchScope>> buildAddressScopeMenuItems(
  String senderAddress,
) {
  final String sender = normalizeFocusSender(senderAddress);
  final String? domain = domainFromFocusSender(senderAddress);
  return <PopupMenuEntry<AddressMatchScope>>[
    PopupMenuItem<AddressMatchScope>(
      value: AddressMatchScope.sender,
      child: Text(
        sender.isEmpty ? 'This sender' : 'This sender ($sender)',
      ),
    ),
    PopupMenuItem<AddressMatchScope>(
      value: AddressMatchScope.domain,
      enabled: domain != null && domain.isNotEmpty,
      child: Text(
        domain == null || domain.isEmpty
            ? 'Entire domain (unavailable)'
            : 'Entire domain ($domain)',
      ),
    ),
  ];
}

/// Shows a positioned sender/domain menu (used by overflow items).
Future<AddressMatchScope?> showAddressScopePicker({
  required BuildContext context,
  required String senderAddress,
  RelativeRect? position,
}) {
  final RelativeRect menuPosition;
  if (position != null) {
    menuPosition = position;
  } else {
    final OverlayState overlay = Overlay.of(context);
    final RenderBox overlayBox =
        overlay.context.findRenderObject()! as RenderBox;
    final Size size = overlayBox.size;
    menuPosition = RelativeRect.fromLTRB(
      size.width / 2 - 80,
      size.height / 2 - 40,
      size.width / 2 - 80,
      size.height / 2 - 40,
    );
  }
  return showMenu<AddressMatchScope>(
    context: context,
    position: menuPosition,
    items: buildAddressScopeMenuItems(senderAddress),
  );
}

/// Compact outlined control: tap opens Sender (default) vs Domain choices.
class AddressScopeAction extends StatelessWidget {
  const AddressScopeAction({
    super.key,
    required this.label,
    required this.senderAddress,
    required this.onSelected,
    this.danger = false,
    this.emphasized = false,
    this.enabled = true,
  });

  final String label;
  final String senderAddress;
  final ValueChanged<AddressMatchScope> onSelected;
  final bool danger;
  final bool emphasized;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Color foreground = danger
        ? t.coral
        : emphasized
        ? t.amber
        : t.text;
    final Color border = danger
        ? t.coral.withValues(alpha: 0.35)
        : emphasized
        ? t.amber.withValues(alpha: 0.45)
        : t.line;
    return PopupMenuButton<AddressMatchScope>(
      enabled: enabled,
      tooltip: '$label — choose sender or domain',
      onSelected: onSelected,
      itemBuilder: (BuildContext context) =>
          buildAddressScopeMenuItems(senderAddress),
      child: Semantics(
        button: true,
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label, style: TextStyle(color: foreground)),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 16, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-only address-scope control with tooltip + semantics (narrow toolbars).
class AddressScopeIconAction extends StatelessWidget {
  const AddressScopeIconAction({
    super.key,
    required this.label,
    required this.icon,
    required this.senderAddress,
    required this.onSelected,
    this.danger = false,
    this.emphasized = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final String senderAddress;
  final ValueChanged<AddressMatchScope> onSelected;
  final bool danger;
  final bool emphasized;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Color foreground = danger
        ? t.coral
        : emphasized
        ? t.amber
        : t.text;
    return PopupMenuButton<AddressMatchScope>(
      enabled: enabled,
      tooltip: '$label — choose sender or domain',
      onSelected: onSelected,
      itemBuilder: (BuildContext context) =>
          buildAddressScopeMenuItems(senderAddress),
      child: Semantics(
        button: true,
        label: label,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: foreground),
        ),
      ),
    );
  }
}

/// Outlined icon+label address-scope control (wide adaptive toolbars).
class AddressScopeOutlinedIconAction extends StatelessWidget {
  const AddressScopeOutlinedIconAction({
    super.key,
    required this.label,
    required this.icon,
    required this.senderAddress,
    required this.onSelected,
    this.danger = false,
    this.emphasized = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final String senderAddress;
  final ValueChanged<AddressMatchScope> onSelected;
  final bool danger;
  final bool emphasized;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Color foreground = danger
        ? t.coral
        : emphasized
        ? t.amber
        : t.text;
    final Color border = danger
        ? t.coral.withValues(alpha: 0.35)
        : emphasized
        ? t.amber.withValues(alpha: 0.45)
        : t.line;
    return PopupMenuButton<AddressMatchScope>(
      enabled: enabled,
      tooltip: '$label — choose sender or domain',
      onSelected: onSelected,
      itemBuilder: (BuildContext context) =>
          buildAddressScopeMenuItems(senderAddress),
      child: Semantics(
        button: true,
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: foreground)),
              Icon(Icons.arrow_drop_down, size: 16, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

/// Builds an overflow [PopupMenuItem] that opens the shared scope picker.
///
/// [value] is ignored by [onSelected] handlers — [onTap] runs the picker.
PopupMenuItem<String> addressScopeOverflowItem({
  required BuildContext context,
  required String label,
  required String senderAddress,
  required ValueChanged<AddressMatchScope> onSelected,
  bool danger = false,
}) {
  final ThemeTokens t = tokensOf(context);
  return PopupMenuItem<String>(
    value: 'address_scope:$label',
    onTap: () {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) {
          return;
        }
        final AddressMatchScope? scope = await showAddressScopePicker(
          context: context,
          senderAddress: senderAddress,
        );
        if (scope != null) {
          onSelected(scope);
        }
      });
    },
    child: Text(
      label,
      style: TextStyle(color: danger ? t.coral : t.text),
    ),
  );
}

/// Text-button style scope picker for the bulk toolbar.
class AddressScopeBulkAction extends StatelessWidget {
  const AddressScopeBulkAction({
    super.key,
    required this.label,
    required this.color,
    required this.sampleAddress,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final String sampleAddress;
  final ValueChanged<AddressMatchScope> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AddressMatchScope>(
      tooltip: '$label — choose sender or domain',
      onSelected: onSelected,
      itemBuilder: (BuildContext context) =>
          buildAddressScopeMenuItems(sampleAddress),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, style: TextStyle(color: color, fontSize: 12)),
            Icon(Icons.arrow_drop_down, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
