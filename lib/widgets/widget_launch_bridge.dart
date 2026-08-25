// ==============================================================================
// File: lib/widgets/widget_launch_bridge.dart
// Description: MethodChannel bridge for Android widget tap intents into Flutter.
// Component: Platform Integration
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:synesis/widgets/widget_launch_request.dart';

/// Reads one-shot widget launch payloads from [MainActivity] on Android.
class WidgetLaunchBridge {
  WidgetLaunchBridge({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('net.livebytes.synesis/widget_launch');

  final MethodChannel _channel;

  /// Returns and clears the pending widget launch, if any.
  Future<WidgetLaunchRequest?> consumePending() async {
    if (!Platform.isAndroid) {
      return null;
    }
    final Object? raw =
        await _channel.invokeMethod<Object?>('consumePendingLaunch');
    if (raw is! Map) {
      return null;
    }
    return WidgetLaunchRequest.fromPlatformMap(raw);
  }
}
