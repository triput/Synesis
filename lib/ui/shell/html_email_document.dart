// ==============================================================================
// File: lib/ui/shell/html_email_document.dart
// Description: Wrap message HTML fragments into a full document for WebView
// Component: UI / Util
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

/// Builds a self-contained HTML document for the reading-pane WebView.
String wrapHtmlEmailDocument(String body) {
  final String trimmed = body.trim();
  final String lower = trimmed.toLowerCase();
  final bool hasDocument =
      lower.contains('<html') || lower.contains('<!doctype');
  final String content = hasDocument
      ? trimmed
      : '''
<body>$trimmed</body>
''';

  if (hasDocument && lower.contains('<head')) {
    // Inject viewport + link interceptor before </head> when possible.
    final int headEnd = lower.indexOf('</head>');
    if (headEnd != -1) {
      return '${trimmed.substring(0, headEnd)}'
          '$_headExtras'
          '${trimmed.substring(headEnd)}';
    }
    return trimmed;
  }

  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
$_headExtras
</head>
$content
</html>
''';
}

const String _headExtras = '''
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body {
    margin: 0;
    padding: 12px;
    background: #ffffff;
    color: #1a1a1a;
    font-family: Segoe UI, Roboto, Helvetica, Arial, sans-serif;
    font-size: 14px;
    line-height: 1.45;
    overflow-wrap: anywhere;
  }
  img, table { max-width: 100%; }
  img { height: auto; }
</style>
<script>
(function () {
  function openExternal(url) {
    try {
      if (window.chrome && window.chrome.webview && window.chrome.webview.postMessage) {
        window.chrome.webview.postMessage({ type: 'open', url: url });
        return;
      }
    } catch (e) {}
    try {
      OpenLink.postMessage(url);
    } catch (e2) {}
  }
  document.addEventListener('click', function (event) {
    var node = event.target;
    while (node && node.tagName !== 'A') {
      node = node.parentElement;
    }
    if (!node || !node.href) {
      return;
    }
    var href = node.href;
    if (href.indexOf('http://') === 0 || href.indexOf('https://') === 0 ||
        href.indexOf('mailto:') === 0) {
      event.preventDefault();
      event.stopPropagation();
      openExternal(href);
    }
  }, true);
})();
</script>
''';
