// ==============================================================================
// File: lib/ui/shell/html_email_body.dart
// Description: Platform WebView renderers for HTML message bodies
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_windows/webview_flutter_windows.dart' as win;
import 'package:bytemail/ui/shell/html_email_document.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// True when platform WebView init failed and we should render via HtmlWidget.
///
/// Covers secondary-engine limits (`unsupported_platform`) and main-window
/// composition failures (`webview_creation_failed` / CoreWebView2 HRESULT).
bool htmlEmailShouldUseWidgetFallback(Object error) {
  if (error is PlatformException) {
    final String code = error.code.toLowerCase();
    if (code == 'unsupported_platform' ||
        code == 'environment_creation_failed' ||
        code == 'webview_creation_failed') {
      return true;
    }
    final String message = (error.message ?? '').toLowerCase();
    if (message.contains('createcorewebview') ||
        message.contains('compositioncontroller') ||
        message.contains('creating the webview failed')) {
      return true;
    }
  }
  final String lower = error.toString().toLowerCase();
  return lower.contains('unsupported_platform') ||
      lower.contains('environment_creation_failed') ||
      lower.contains('webview_creation_failed') ||
      lower.contains('createcorewebview2compositioncontroller') ||
      lower.contains('creating the webview failed');
}

/// Legacy name kept for call sites / tests; prefer [htmlEmailShouldUseWidgetFallback].
bool htmlEmailShouldFallbackToPlain(Object error) =>
    htmlEmailShouldUseWidgetFallback(error);

/// Best-effort in-page find via `window.find` (returns JS source).
String htmlEmailFindScript({
  required String query,
  required bool reverse,
  required bool resetSelection,
}) {
  final String encodedQuery = jsonEncode(query);
  return '''
(function() {
  var q = $encodedQuery;
  if (!q) { return false; }
  try {
    var sel = window.getSelection && window.getSelection();
    if ($resetSelection && sel) {
      sel.removeAllRanges();
      if (document.body) {
        var range = document.createRange();
        range.selectNodeContents(document.body);
        range.collapse(true);
        sel.addRange(range);
      }
    }
    return window.find(q, false, $reverse, true, false, false, false);
  } catch (e) {
    return false;
  }
})();
''';
}

/// When true under this scope, skip platform WebView and use widget HTML.
class PreferWidgetHtmlScope extends InheritedWidget {
  const PreferWidgetHtmlScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<PreferWidgetHtmlScope>()
            ?.enabled ??
        false;
  }

  @override
  bool updateShouldNotify(covariant PreferWidgetHtmlScope oldWidget) {
    return enabled != oldWidget.enabled;
  }
}

/// Renders an HTML email body in a platform WebView (Windows texture / Android).
class HtmlEmailBody extends StatefulWidget {
  const HtmlEmailBody({
    super.key,
    required this.html,
    required this.muted,
    this.findQuery = '',
    this.findNavigateEpoch = 0,
    this.findNavigateReverse = false,
  });

  final String html;
  final Color muted;

  /// Query used for best-effort `window.find` highlighting.
  final String findQuery;

  /// Bumped by the parent to request next/previous navigation.
  final int findNavigateEpoch;

  /// When true, navigate to the previous match.
  final bool findNavigateReverse;

  @override
  State<HtmlEmailBody> createState() => _HtmlEmailBodyState();
}

class _HtmlEmailBodyState extends State<HtmlEmailBody> {
  Object? _error;
  bool _useWidgetHtmlFallback = false;

  String _errorText(Object error) {
    if (error is MissingPluginException) {
      // Hot restart cannot register newly added native plugins.
      return 'HTML viewer needs a full app restart '
          '(stop the app, then Run again — not hot reload/restart).';
    }
    return 'Unable to render HTML message.\n$error';
  }

  @override
  Widget build(BuildContext context) {
    final bool preferWidgetHtml = PreferWidgetHtmlScope.of(context);
    if (preferWidgetHtml || _useWidgetHtmlFallback) {
      return _WidgetHtmlEmailBody(
        html: widget.html,
        muted: widget.muted,
        showFallbackNotice: !preferWidgetHtml,
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _errorText(_error!),
          style: TextStyle(color: widget.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (kIsWeb) {
      return Center(
        child: Text(
          'HTML rendering is not available on this platform.',
          style: TextStyle(color: widget.muted),
        ),
      );
    }

    if (Platform.isWindows) {
      return _WindowsHtmlEmailBody(
        html: widget.html,
        muted: widget.muted,
        findQuery: widget.findQuery,
        findNavigateEpoch: widget.findNavigateEpoch,
        findNavigateReverse: widget.findNavigateReverse,
        onError: (Object error) {
          if (!mounted) {
            return;
          }
          if (htmlEmailShouldUseWidgetFallback(error)) {
            // WebView2 texture/composition can fail on main or secondary engines —
            // keep mail readable via the in-app HTML widget renderer.
            setState(() {
              _useWidgetHtmlFallback = true;
              _error = null;
            });
            return;
          }
          setState(() => _error = error);
        },
      );
    }

    return _MobileHtmlEmailBody(
      html: widget.html,
      muted: widget.muted,
      findQuery: widget.findQuery,
      findNavigateEpoch: widget.findNavigateEpoch,
      findNavigateReverse: widget.findNavigateReverse,
      onError: (Object error) {
        if (mounted) {
          setState(() => _error = error);
        }
      },
    );
  }
}

/// Layout-preserving HTML fallback when the platform WebView cannot start.
class _WidgetHtmlEmailBody extends StatelessWidget {
  const _WidgetHtmlEmailBody({
    required this.html,
    required this.muted,
    this.showFallbackNotice = true,
  });

  final String html;
  final Color muted;
  final bool showFallbackNotice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showFallbackNotice)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Using in-app HTML viewer (platform WebView failed to start).',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: HtmlWidget(
              html,
              textStyle: const TextStyle(
                color: Color(0xFFD7DDF5),
                fontSize: 14,
                height: 1.5,
              ),
              onTapUrl: (String url) async {
                await _openExternalUrl(url);
                return true;
              },
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _openExternalUrl(String url) async {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _WindowsHtmlEmailBody extends StatefulWidget {
  const _WindowsHtmlEmailBody({
    required this.html,
    required this.muted,
    required this.onError,
    this.findQuery = '',
    this.findNavigateEpoch = 0,
    this.findNavigateReverse = false,
  });

  final String html;
  final Color muted;
  final ValueChanged<Object> onError;
  final String findQuery;
  final int findNavigateEpoch;
  final bool findNavigateReverse;

  @override
  State<_WindowsHtmlEmailBody> createState() => _WindowsHtmlEmailBodyState();
}

class _WindowsHtmlEmailBodyState extends State<_WindowsHtmlEmailBody> {
  final win.WebviewController _controller = win.WebviewController();
  StreamSubscription<dynamic>? _messageSub;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.white);
      await _controller.setPopupWindowPolicy(win.WebviewPopupWindowPolicy.deny);
      _messageSub = _controller.webMessage.listen((dynamic message) {
        if (message is Map && message['type'] == 'open') {
          final Object? url = message['url'];
          if (url is String) {
            unawaited(_openExternalUrl(url));
          }
        }
      });
      await _controller.loadStringContent(wrapHtmlEmailDocument(widget.html));
      if (mounted) {
        setState(() => _ready = true);
      }
      unawaited(_runFind(resetSelection: true));
    } catch (error) {
      widget.onError(error);
    }
  }

  Future<void> _runFind({required bool resetSelection}) async {
    if (!_ready) {
      return;
    }
    final String query = widget.findQuery.trim();
    if (query.isEmpty) {
      return;
    }
    try {
      await _controller.executeScript(
        htmlEmailFindScript(
          query: query,
          reverse: widget.findNavigateReverse,
          resetSelection: resetSelection,
        ),
      );
    } catch (_) {
      // Best-effort highlight; match count still comes from stripped text.
    }
  }

  @override
  void didUpdateWidget(covariant _WindowsHtmlEmailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html && _ready) {
      unawaited(
        _controller.loadStringContent(wrapHtmlEmailDocument(widget.html)).then(
          (_) => _runFind(resetSelection: true),
        ),
      );
      return;
    }
    if (oldWidget.findQuery != widget.findQuery) {
      unawaited(_runFind(resetSelection: true));
      return;
    }
    if (oldWidget.findNavigateEpoch != widget.findNavigateEpoch) {
      unawaited(_runFind(resetSelection: false));
    }
  }

  @override
  void dispose() {
    unawaited(_messageSub?.cancel());
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: widget.muted),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: win.Webview(_controller),
    );
  }
}

class _MobileHtmlEmailBody extends StatefulWidget {
  const _MobileHtmlEmailBody({
    required this.html,
    required this.muted,
    required this.onError,
    this.findQuery = '',
    this.findNavigateEpoch = 0,
    this.findNavigateReverse = false,
  });

  final String html;
  final Color muted;
  final ValueChanged<Object> onError;
  final String findQuery;
  final int findNavigateEpoch;
  final bool findNavigateReverse;

  @override
  State<_MobileHtmlEmailBody> createState() => _MobileHtmlEmailBodyState();
}

class _MobileHtmlEmailBodyState extends State<_MobileHtmlEmailBody> {
  WebViewController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final WebViewController controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..addJavaScriptChannel(
          'OpenLink',
          onMessageReceived: (JavaScriptMessage message) {
            unawaited(_openExternalUrl(message.message));
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              final String url = request.url;
              if (url.startsWith('data:') ||
                  url == 'about:blank' ||
                  url.startsWith('file:')) {
                return NavigationDecision.navigate;
              }
              unawaited(_openExternalUrl(url));
              return NavigationDecision.prevent;
            },
          ),
        );
      await controller.loadHtmlString(wrapHtmlEmailDocument(widget.html));
      if (!mounted) {
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
      unawaited(_runFind(resetSelection: true));
    } catch (error) {
      widget.onError(error);
    }
  }

  Future<void> _runFind({required bool resetSelection}) async {
    final WebViewController? controller = _controller;
    if (!_ready || controller == null) {
      return;
    }
    final String query = widget.findQuery.trim();
    if (query.isEmpty) {
      return;
    }
    try {
      await controller.runJavaScript(
        htmlEmailFindScript(
          query: query,
          reverse: widget.findNavigateReverse,
          resetSelection: resetSelection,
        ),
      );
    } catch (_) {
      // Best-effort highlight; match count still comes from stripped text.
    }
  }

  @override
  void didUpdateWidget(covariant _MobileHtmlEmailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html && _controller != null) {
      unawaited(
        _controller!.loadHtmlString(wrapHtmlEmailDocument(widget.html)).then(
          (_) => _runFind(resetSelection: true),
        ),
      );
      return;
    }
    if (oldWidget.findQuery != widget.findQuery) {
      unawaited(_runFind(resetSelection: true));
      return;
    }
    if (oldWidget.findNavigateEpoch != widget.findNavigateEpoch) {
      unawaited(_runFind(resetSelection: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: widget.muted),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: WebViewWidget(controller: _controller!),
    );
  }
}
