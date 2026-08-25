// ==============================================================================
// File: lib/widgets/widget_launch_request.dart
// Description: Parsed Android home-screen widget tap / action launch payloads.
// Component: Platform Integration
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

/// Actions delivered from native Android widgets into Flutter on cold or warm
/// start via [WidgetLaunchBridge].
enum WidgetLaunchAction {
  openInbox,
  compose,
  openMessage,
}

/// One pending widget interaction consumed once per app launch/resume cycle.
class WidgetLaunchRequest {
  const WidgetLaunchRequest({
    required this.action,
    this.accountId,
    this.folderId,
    this.messageId,
  });

  final WidgetLaunchAction action;
  final String? accountId;
  final String? folderId;
  final String? messageId;

  factory WidgetLaunchRequest.fromPlatformMap(Map<Object?, Object?> map) {
    final String actionName = map['action'] as String? ?? '';
    final WidgetLaunchAction action = switch (actionName) {
      'open_inbox' => WidgetLaunchAction.openInbox,
      'compose' => WidgetLaunchAction.compose,
      'open_message' => WidgetLaunchAction.openMessage,
      _ => WidgetLaunchAction.openInbox,
    };
    return WidgetLaunchRequest(
      action: action,
      accountId: map['accountId'] as String?,
      folderId: map['folderId'] as String?,
      messageId: map['messageId'] as String?,
    );
  }
}
