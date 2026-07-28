// ==============================================================================
// File: lib/ui/compose/contact_picker.dart
// Description: Compose To/Cc/Bcc contact picker — local FTS typeahead field.
// Component: UI / Compose
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';

/// Formats [hit] into a recipient token compatible with
/// `splitOutboxRecipients`/`parseAddressList` (`outbox/outbox_recipients.dart`).
///
/// Returns `null` when the contact has no known email — such a hit cannot
/// be inserted into a To/Cc/Bcc field.
String? formatContactRecipient(ContactSearchHit hit) {
  final String? email = hit.email?.trim();
  if (email == null || email.isEmpty) {
    return null;
  }
  final String name = hit.displayName.trim();
  if (name.isEmpty) {
    return email;
  }
  // The field delimiter is a bare comma outside `<...>` — quote names that
  // contain one (or a literal quote) so `_splitAddressList` keeps them intact.
  final bool needsQuoting = name.contains(',') || name.contains('"');
  final String safeName = needsQuoting
      ? '"${name.replaceAll('"', '\\"')}"'
      : name;
  return '$safeName <$email>';
}

/// Extracts the in-progress token (text after the last comma) that the user
/// is currently typing in a recipient field, for querying
/// [DriftPimStore.searchContacts].
String currentRecipientToken(String fieldText) {
  final int lastComma = fieldText.lastIndexOf(',');
  final String token = lastComma < 0
      ? fieldText
      : fieldText.substring(lastComma + 1);
  return token.trim();
}

/// Replaces the in-progress token in [fieldText] with [hit] formatted as a
/// recipient, leaving a trailing `, ` so the user can keep typing the next
/// recipient. Returns `null` when [hit] has no usable email (field
/// unchanged in that case).
String? insertContactIntoField(String fieldText, ContactSearchHit hit) {
  final String? formatted = formatContactRecipient(hit);
  if (formatted == null) {
    return null;
  }
  final int lastComma = fieldText.lastIndexOf(',');
  final String before = lastComma < 0
      ? ''
      : fieldText.substring(0, lastComma + 1).trimRight();
  final String prefix = before.isEmpty ? '' : '$before ';
  return '$prefix$formatted, ';
}

/// A `To`/`Cc`/`Bcc` [TextField] with a local-FTS contact typeahead.
///
/// Reads [DriftPimStore] from context — never issues HTTP/Graph/CardDAV
/// calls itself (Wave 5 W5-1: compose picker is local-only). Suggestions are
/// scoped to `isSelectedForDisplay` contact lists via
/// `searchContacts(selectedListsOnly: true)`.
class ContactRecipientField extends StatefulWidget {
  const ContactRecipientField({
    super.key,
    required this.controller,
    required this.decoration,
    this.onChanged,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final VoidCallback? onChanged;

  @override
  State<ContactRecipientField> createState() => _ContactRecipientFieldState();
}

class _ContactRecipientFieldState extends State<ContactRecipientField> {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<ContactSearchHit> _suggestions = const <ContactSearchHit>[];
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && mounted && _suggestions.isNotEmpty) {
      setState(() => _suggestions = const <ContactSearchHit>[]);
    }
  }

  void _onTextChanged() {
    widget.onChanged?.call();
    final String token = currentRecipientToken(widget.controller.text);
    _debounce?.cancel();
    if (token.isEmpty) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = const <ContactSearchHit>[]);
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_search(token));
    });
  }

  Future<void> _search(String token) async {
    final int requestId = ++_requestId;
    final DriftPimStore pimStore = context.read<DriftPimStore>();
    final List<ContactSearchHit> hits = await pimStore.searchContacts(
      token,
      selectedListsOnly: true,
    );
    if (!mounted || requestId != _requestId || !_focusNode.hasFocus) {
      return;
    }
    setState(() => _suggestions = hits);
  }

  void _selectHit(ContactSearchHit hit) {
    final String? next = insertContactIntoField(
      widget.controller.text,
      hit,
    );
    if (next == null) {
      return;
    }
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() => _suggestions = const <ContactSearchHit>[]);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          style: TextStyle(color: t.text),
          decoration: widget.decoration,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            key: const Key('contact_picker_suggestions'),
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: t.panel2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.line),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (BuildContext context, int index) {
                final ContactSearchHit hit = _suggestions[index];
                return ListTile(
                  key: ValueKey<String>(
                    'contact_picker_suggestion_${hit.contact.id}',
                  ),
                  dense: true,
                  leading: Icon(Icons.person_outline, color: t.muted, size: 18),
                  title: Text(
                    hit.displayName,
                    style: TextStyle(color: t.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: hit.email == null
                      ? null
                      : Text(
                          hit.email!,
                          style: TextStyle(color: t.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () => _selectHit(hit),
                );
              },
            ),
          ),
      ],
    );
  }
}
