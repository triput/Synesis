// ==============================================================================
// File: lib/ui/compose/compose_prefill.dart
// Description: Thin reply / reply-all / forward compose prefill (no HTML quote)
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/outbox/outbox_recipients.dart';

export 'package:bytemail/outbox/outbox_recipients.dart'
    show parseAddressList, splitOutboxRecipients;

enum ComposeMode { newMessage, reply, replyAll, forward }

/// Minimal envelope used to open [showComposeSheet] for reply / forward.
///
/// Full quoted HTML bodies are deferred to W4 — this only sets To/Cc/Subject
/// and a plain forward snippet.
class ComposePrefill {
  const ComposePrefill({
    required this.mode,
    required this.accountId,
    this.to = const <String>[],
    this.cc = const <String>[],
    this.subject = '',
    this.body = '',
    this.inReplyTo,
    this.referencesJson,
  });

  final ComposeMode mode;
  final String accountId;
  final List<String> to;
  final List<String> cc;
  final String subject;
  final String body;
  final String? inReplyTo;
  final String? referencesJson;

  /// Outbox / sync `compose_mode` column value.
  String get composeModeValue {
    switch (mode) {
      case ComposeMode.newMessage:
        return 'new';
      case ComposeMode.reply:
        return 'reply';
      case ComposeMode.replyAll:
        return 'replyAll';
      case ComposeMode.forward:
        return 'forward';
    }
  }

  /// Reply or reply-all prefill from [message].
  ///
  /// When [replyAll] is true and [message.rawHeaders] is present, To/Cc are
  /// parsed from headers (excluding [ownAddress]). Otherwise To is only the
  /// original from address.
  factory ComposePrefill.reply(
    MailMessage message, {
    bool replyAll = false,
    String? ownAddress,
  }) {
    final String subject = ensureReplySubject(message.subject);
    final String? inReplyTo = _nullIfBlank(message.messageIdHeader);

    if (!replyAll) {
      return ComposePrefill(
        mode: ComposeMode.reply,
        accountId: message.accountId,
        to: _nonEmptyAddresses(<String>[message.fromAddress]),
        subject: subject,
        inReplyTo: inReplyTo,
      );
    }

    final String? own = _nullIfBlank(ownAddress);
    final List<String> to = <String>[message.fromAddress];
    List<String> cc = const <String>[];

    final String? raw = message.rawHeaders?.trim();
    if (raw != null && raw.isNotEmpty) {
      final List<String> headerTo = extractAddressesFromRawHeaders(raw, 'To');
      final List<String> headerCc = extractAddressesFromRawHeaders(raw, 'Cc');
      final Set<String> seen = <String>{message.fromAddress.toLowerCase()};
      if (own != null) {
        seen.add(own.toLowerCase());
      }

      for (final String address in headerTo) {
        final String key = address.toLowerCase();
        if (seen.contains(key)) {
          continue;
        }
        seen.add(key);
        to.add(address);
      }

      final List<String> nextCc = <String>[];
      for (final String address in headerCc) {
        final String key = address.toLowerCase();
        if (seen.contains(key)) {
          continue;
        }
        seen.add(key);
        nextCc.add(address);
      }
      cc = nextCc;
    }

    return ComposePrefill(
      mode: ComposeMode.replyAll,
      accountId: message.accountId,
      to: _nonEmptyAddresses(to),
      cc: _nonEmptyAddresses(cc),
      subject: subject,
      inReplyTo: inReplyTo,
    );
  }

  /// Forward prefill with plain forwarded-message snippet (no HTML quote).
  factory ComposePrefill.forward(MailMessage message) {
    return ComposePrefill(
      mode: ComposeMode.forward,
      accountId: message.accountId,
      subject: ensureForwardSubject(message.subject),
      body: buildForwardBody(message),
    );
  }

  /// Ensures a single `Re:` prefix (case-insensitive).
  static String ensureReplySubject(String subject) {
    final String trimmed = subject.trim();
    if (trimmed.isEmpty) {
      return 'Re:';
    }
    if (RegExp(r'^re\s*:', caseSensitive: false).hasMatch(trimmed)) {
      return trimmed;
    }
    return 'Re: $trimmed';
  }

  /// Ensures a single `Fw:` / `Fwd:` prefix (case-insensitive).
  static String ensureForwardSubject(String subject) {
    final String trimmed = subject.trim();
    if (trimmed.isEmpty) {
      return 'Fw:';
    }
    if (RegExp(r'^fwd?\s*:', caseSensitive: false).hasMatch(trimmed)) {
      return trimmed;
    }
    return 'Fw: $trimmed';
  }

  /// Plain forward body block using snippet, else tag-stripped body.
  static String buildForwardBody(MailMessage message) {
    final String fromLabel = message.fromName.trim().isEmpty
        ? message.fromAddress
        : '${message.fromName} <${message.fromAddress}>';
    final String content = _forwardContent(message);
    return '---------- Forwarded message ----------\n'
        'From: $fromLabel\n'
        '\n'
        '$content';
  }
}

/// Extracts email addresses from a named header in [rawHeaders].
///
/// Handles simple folded header lines (continuation lines starting with
/// whitespace) and common `Name <email>` / bare-address forms.
List<String> extractAddressesFromRawHeaders(
  String rawHeaders,
  String headerName,
) {
  final String? value = _headerValue(rawHeaders, headerName);
  if (value == null || value.trim().isEmpty) {
    return const <String>[];
  }
  return parseAddressList(value);
}

String? _headerValue(String rawHeaders, String headerName) {
  final String target = headerName.toLowerCase();
  final List<String> lines = rawHeaders.replaceAll('\r\n', '\n').split('\n');
  StringBuffer? current;
  for (final String line in lines) {
    if (line.isEmpty) {
      break;
    }
    final bool continuation = line.startsWith(' ') || line.startsWith('\t');
    if (continuation) {
      if (current != null) {
        current.write(' ');
        current.write(line.trim());
      }
      continue;
    }
    if (current != null) {
      break;
    }
    final int colon = line.indexOf(':');
    if (colon <= 0) {
      continue;
    }
    final String name = line.substring(0, colon).trim().toLowerCase();
    if (name != target) {
      continue;
    }
    current = StringBuffer(line.substring(colon + 1).trim());
  }
  return current?.toString();
}

List<String> _nonEmptyAddresses(List<String> addresses) {
  return addresses
      .map((String a) => a.trim())
      .where((String a) => a.isNotEmpty)
      .toList(growable: false);
}

String? _nullIfBlank(String? value) {
  if (value == null) {
    return null;
  }
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _forwardContent(MailMessage message) {
  final String snippet = message.snippet.trim();
  if (snippet.isNotEmpty) {
    return snippet;
  }
  return _stripSimpleMarkup(message.body).trim();
}

/// Minimal tag strip for forward body — not a full HTML sanitizer.
String _stripSimpleMarkup(String raw) {
  final String withoutTags = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return withoutTags
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ');
}
