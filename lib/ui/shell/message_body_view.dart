// ==============================================================================
// File: lib/ui/shell/message_body_view.dart
// Description: Renders cached message bodies as HTML (WebView) or plain text
// Component: UI
// Version: 1.4 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-08-03
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/mailbox/message_body_normalizer.dart';
import 'package:synesis/ui/shell/html_email_body.dart';
import 'package:synesis/ui/shell/message_body_find.dart';
import 'package:synesis/ui/shell/remote_image_policy.dart';
import 'package:synesis/ui/shell/tracker_blocking_policy.dart';

class MessageBodyView extends StatefulWidget {
  const MessageBodyView({
    super.key,
    required this.body,
    required this.bodySize,
    required this.muted,
    this.isLoadingBody = false,
    this.bodyErrorMessage,
    this.blockRemoteImages = true,
    this.allowRemoteImages = false,
    this.onLoadRemoteImages,
    this.imageAllowlistDomains = const <String>[],
    this.blockTrackers = true,
    this.findQuery = '',
    this.findActiveIndex = 0,
    this.findNavigateEpoch = 0,
    this.findNavigateReverse = false,
    this.onFindMatchCountChanged,
  });

  final String body;
  final double bodySize;
  final Color muted;
  final bool isLoadingBody;
  final String? bodyErrorMessage;

  /// Effective (already account-resolved) remote-image-blocking policy.
  final bool blockRemoteImages;

  /// Session override: load remote images for this message.
  final bool allowRemoteImages;

  /// Invoked when the user chooses to load remote images for this message.
  final VoidCallback? onLoadRemoteImages;

  /// D6-2: image-host domains always loaded even when [blockRemoteImages] is
  /// true (case-insensitive suffix match).
  final List<String> imageAllowlistDomains;

  /// D6-7: strip known ESP/analytics tracking pixels, independent of
  /// [blockRemoteImages].
  final bool blockTrackers;

  /// Case-insensitive find query; empty disables highlighting.
  final String findQuery;

  /// Active match index among [findQuery] hits (plain-text path).
  final int findActiveIndex;

  /// Bumped by the parent to request HTML `window.find` navigation.
  final int findNavigateEpoch;

  /// When true, HTML find navigates to the previous match.
  final bool findNavigateReverse;

  /// Reports the current match count whenever query/body changes.
  final ValueChanged<int>? onFindMatchCountChanged;

  @override
  State<MessageBodyView> createState() => _MessageBodyViewState();
}

class _MessageBodyViewState extends State<MessageBodyView> {
  final ScrollController _plainScrollController = ScrollController();
  final List<GlobalKey> _matchKeys = <GlobalKey>[];
  int _lastReportedCount = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportMatchCount());
  }

  @override
  void didUpdateWidget(covariant MessageBodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body ||
        oldWidget.findQuery != widget.findQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reportMatchCount());
    }
    if (oldWidget.findActiveIndex != widget.findActiveIndex ||
        oldWidget.findQuery != widget.findQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveMatch());
    }
  }

  @override
  void dispose() {
    _plainScrollController.dispose();
    super.dispose();
  }

  void _reportMatchCount() {
    if (!mounted) {
      return;
    }
    final int count = _computeMatchCount();
    if (count == _lastReportedCount) {
      return;
    }
    _lastReportedCount = count;
    widget.onFindMatchCountChanged?.call(count);
  }

  int _computeMatchCount() {
    final String query = widget.findQuery.trim();
    if (query.isEmpty || widget.body.trim().isEmpty) {
      return 0;
    }
    final String searchable = isHtmlMessageBody(widget.body)
        ? stripHtmlToPlainText(widget.body)
        : widget.body;
    return findTextMatches(searchable, query).length;
  }

  void _scrollToActiveMatch() {
    if (!mounted || _matchKeys.isEmpty) {
      return;
    }
    final int index = wrapFindIndex(widget.findActiveIndex, _matchKeys.length);
    final BuildContext? target = _matchKeys[index].currentContext;
    if (target == null) {
      return;
    }
    Scrollable.ensureVisible(
      target,
      alignment: 0.35,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingBody && widget.body.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int index = 0; index < 8; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 14,
                  width: index % 3 == 2 ? 180 : double.infinity,
                  decoration: BoxDecoration(
                    color: widget.muted.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    if (widget.bodyErrorMessage != null && widget.body.trim().isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          widget.bodyErrorMessage!,
          style: TextStyle(
            color: widget.muted,
            fontSize: widget.bodySize,
            height: 1.5,
          ),
        ),
      );
    }
    if (widget.body.trim().isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          'No message content.',
          style: TextStyle(color: widget.muted, fontSize: widget.bodySize),
        ),
      );
    }

    if (isHtmlMessageBody(widget.body)) {
      final bool shouldBlock =
          widget.blockRemoteImages && !widget.allowRemoteImages;
      final RemoteImagePolicyResult imagePolicy = applyRemoteImagePolicy(
        widget.body,
        blockRemoteImages: shouldBlock,
        allowlistDomains: widget.imageAllowlistDomains,
      );
      final TrackerBlockingPolicyResult trackerPolicy =
          applyTrackerBlockingPolicy(
        imagePolicy.html,
        blockTrackers: widget.blockTrackers,
        allowlistDomains: widget.imageAllowlistDomains,
      );
      final bool showImagesBlockedBanner = imagePolicy.blockedRemoteImages;
      final bool showTrackersBlockedBanner =
          !showImagesBlockedBanner && trackerPolicy.blockedTrackers;

      // Banner can be ~90px when the load-images action wraps; budget must
      // leave room for HtmlEmailBody or the Column overflows (~33px dogfood).
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const double bannerBudget = 96;
          const double minHtmlHeight = 48;
          final bool hasBannerRoom = constraints.hasBoundedHeight &&
              constraints.maxHeight >= bannerBudget + minHtmlHeight;
          final bool canShowImagesBanner =
              showImagesBlockedBanner && hasBannerRoom;
          final bool canShowTrackersBanner =
              showTrackersBlockedBanner && hasBannerRoom;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (canShowImagesBanner)
                _RemoteImagesBlockedBanner(
                  muted: widget.muted,
                  onLoadImages: widget.onLoadRemoteImages,
                ),
              if (canShowTrackersBanner)
                _TrackersBlockedBanner(muted: widget.muted),
              Expanded(
                child: HtmlEmailBody(
                  html: trackerPolicy.html,
                  muted: widget.muted,
                  findQuery: widget.findQuery,
                  findNavigateEpoch: widget.findNavigateEpoch,
                  findNavigateReverse: widget.findNavigateReverse,
                ),
              ),
            ],
          );
        },
      );
    }

    return SingleChildScrollView(
      controller: _plainScrollController,
      child: _PlainBodyWithFind(
        body: widget.body,
        bodySize: widget.bodySize,
        findQuery: widget.findQuery,
        findActiveIndex: widget.findActiveIndex,
        matchKeys: _matchKeys,
      ),
    );
  }
}

class _PlainBodyWithFind extends StatelessWidget {
  const _PlainBodyWithFind({
    required this.body,
    required this.bodySize,
    required this.findQuery,
    required this.findActiveIndex,
    required this.matchKeys,
  });

  final String body;
  final double bodySize;
  final String findQuery;
  final int findActiveIndex;
  final List<GlobalKey> matchKeys;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final TextStyle baseStyle = TextStyle(
      color: const Color(0xFFD7DDF5),
      fontSize: bodySize,
      height: 1.65,
    );
    final List<TextMatchRange> matches = findTextMatches(body, findQuery);
    matchKeys
      ..clear()
      ..addAll(
        List<GlobalKey>.generate(matches.length, (_) => GlobalKey()),
      );

    if (matches.isEmpty) {
      return Text(body, style: baseStyle);
    }

    final int active = wrapFindIndex(findActiveIndex, matches.length);
    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;
    for (int i = 0; i < matches.length; i++) {
      final TextMatchRange match = matches[i];
      if (match.start > cursor) {
        spans.add(TextSpan(text: body.substring(cursor, match.start)));
      }
      final bool isActive = i == active;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            key: matchKeys[i],
            color: isActive
                ? t.amber.withValues(alpha: 0.55)
                : t.amber.withValues(alpha: 0.28),
            child: Text(
              body.substring(match.start, match.end),
              style: baseStyle.copyWith(
                color: t.ink,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < body.length) {
      spans.add(TextSpan(text: body.substring(cursor)));
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}

/// D6-7: lightweight, dismissible-by-nature informational banner shown when
/// tracking pixels were stripped but general remote images still loaded
/// (i.e. [MessageBodyView.blockRemoteImages] is off/allowed for this
/// message but [MessageBodyView.blockTrackers] caught known ESP trackers).
class _TrackersBlockedBanner extends StatelessWidget {
  const _TrackersBlockedBanner({required this.muted});

  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: muted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: <Widget>[
              Icon(Icons.shield_outlined, size: 18, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tracking pixels blocked',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteImagesBlockedBanner extends StatelessWidget {
  const _RemoteImagesBlockedBanner({
    required this.muted,
    this.onLoadImages,
  });

  final Color muted;
  final VoidCallback? onLoadImages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: muted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool stack = constraints.maxWidth < 420;
              final Widget label = Text(
                'Remote images blocked',
                style: TextStyle(color: muted, fontSize: 13),
              );
              final Widget action = TextButton(
                onPressed: onLoadImages,
                child: const Text('Load images for this message'),
              );
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.hide_image_outlined, size: 18, color: muted),
                        const SizedBox(width: 8),
                        Expanded(child: label),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: action,
                    ),
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  Icon(Icons.hide_image_outlined, size: 18, color: muted),
                  const SizedBox(width: 8),
                  Expanded(child: label),
                  Flexible(child: action),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
