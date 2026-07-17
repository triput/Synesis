// ==============================================================================
// File: lib/ui/shell/reading_pane.dart
// Description: Reading pane with adaptive actions and portrait message paging
// Component: UI
// Version: 1.3 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/desktop/detached_message_window_controller.dart';
import 'package:bytemail/desktop/message_file_service.dart';
import 'package:bytemail/desktop/message_print_service.dart';
import 'package:bytemail/domain/address_match_scope.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/shell/address_scope_action.dart';
import 'package:bytemail/ui/shell/message_body_find.dart';
import 'package:bytemail/ui/shell/message_body_view.dart';
import 'package:printing/printing.dart';

/// Width at or above which reading-pane actions show icon+label buttons.
const double kReadingPaneWideBreakpoint = 520;

class ReadingPane extends StatefulWidget {
  const ReadingPane({
    super.key,
    required this.message,
    required this.accounts,
    required this.density,
    this.folderRole,
    this.isLoadingBody = false,
    this.bodyErrorMessage,
    this.blockRemoteImages = true,
    this.findInMessageRequested = false,
    this.onFindRequestHandled,
    this.allowOpenInNewWindow = true,
    this.onMarkRead,
    this.onMarkUnread,
    this.onShowHeaders,
    this.onReply,
    this.onReplyAll,
    this.onForward,
    this.onArchive,
    this.onDelete,
    this.onPermanentDelete,
    this.onToggleStar,
    this.onPin,
    this.onSnooze,
    this.onMove,
    this.onReportJunk,
    this.onRecover,
    this.onNotJunk,
    this.onMarkFocused,
    this.onMarkOther,
    this.navigationIds = const <String>[],
    this.navigationMessages = const <MailMessage>[],
    this.onNavigateToMessage,
  });

  final MailMessage? message;
  final List<MailAccount> accounts;
  final ViewDensity density;
  final String? folderRole;
  final bool isLoadingBody;
  final String? bodyErrorMessage;

  /// Global preference: block remote images in HTML bodies (privacy-first).
  final bool blockRemoteImages;

  /// When true, open the in-message find bar (Ctrl+F from workspace).
  final bool findInMessageRequested;

  /// Cleared by the parent after find opens or closes.
  final VoidCallback? onFindRequestHandled;

  /// When false, hides overflow "Open in new window" (detached reader).
  final bool allowOpenInNewWindow;

  final VoidCallback? onMarkRead;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onShowHeaders;
  final VoidCallback? onReply;
  final VoidCallback? onReplyAll;
  final VoidCallback? onForward;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onPermanentDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onPin;
  final VoidCallback? onSnooze;
  final VoidCallback? onMove;
  final ValueChanged<AddressMatchScope>? onReportJunk;
  final VoidCallback? onRecover;
  final ValueChanged<AddressMatchScope>? onNotJunk;
  final ValueChanged<AddressMatchScope>? onMarkFocused;
  final ValueChanged<AddressMatchScope>? onMarkOther;

  /// Projected list order for portrait prev/next (deduped ids).
  final List<String> navigationIds;

  /// Source messages used to resolve [navigationIds] into page content.
  final List<MailMessage> navigationMessages;

  /// Called when the user pages to an adjacent projected message.
  final ValueChanged<String>? onNavigateToMessage;

  static bool isTrashRole(String? role) {
    final String normalized = (role ?? '').trim().toLowerCase();
    return normalized == 'trash' ||
        normalized == 'deleteditems' ||
        normalized == 'deleted';
  }

  static bool isJunkRole(String? role) {
    final String normalized = (role ?? '').trim().toLowerCase();
    return normalized == 'junk' ||
        normalized == 'junkemail' ||
        normalized == 'spam';
  }

  @override
  State<ReadingPane> createState() => _ReadingPaneState();
}

class _ReadingPaneState extends State<ReadingPane> {
  /// Message ids allowed to load remote images for this app session only.
  final Set<String> _sessionAllowedRemoteImages = <String>{};

  bool _findOpen = false;
  String _findQuery = '';
  int _findActiveIndex = 0;
  int _findMatchCount = 0;
  int _findNavigateEpoch = 0;
  bool _findNavigateReverse = false;

  @override
  void initState() {
    super.initState();
    if (widget.findInMessageRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _openFind(notifyParent: true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReadingPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.findInMessageRequested && !oldWidget.findInMessageRequested) {
      // Parent clears the request flag via setState — must not run mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.findInMessageRequested) {
          return;
        }
        _openFind(notifyParent: true);
      });
    }
    final String? oldId = oldWidget.message?.id;
    final String? newId = widget.message?.id;
    if (oldId != newId) {
      _resetFindForMessageChange();
    }
  }

  void _allowRemoteImagesForMessage(String messageId) {
    if (_sessionAllowedRemoteImages.contains(messageId)) {
      return;
    }
    setState(() {
      _sessionAllowedRemoteImages.add(messageId);
    });
  }

  void _notifyFindRequestHandled() {
    final VoidCallback? handled = widget.onFindRequestHandled;
    if (handled == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      handled();
    });
  }

  void _openFind({required bool notifyParent}) {
    if (!_findOpen) {
      setState(() {
        _findOpen = true;
      });
    }
    if (notifyParent) {
      _notifyFindRequestHandled();
    }
  }

  void _closeFind() {
    if (!_findOpen && _findQuery.isEmpty) {
      _notifyFindRequestHandled();
      return;
    }
    setState(() {
      _findOpen = false;
      _findQuery = '';
      _findActiveIndex = 0;
      _findMatchCount = 0;
      _findNavigateEpoch = 0;
      _findNavigateReverse = false;
    });
    _notifyFindRequestHandled();
  }

  void _resetFindForMessageChange() {
    if (!_findOpen && _findQuery.isEmpty) {
      return;
    }
    setState(() {
      _findQuery = '';
      _findActiveIndex = 0;
      _findMatchCount = 0;
      _findNavigateEpoch = 0;
      _findNavigateReverse = false;
    });
  }

  void _onFindQueryChanged(String value) {
    setState(() {
      _findQuery = value;
      _findActiveIndex = 0;
      _findNavigateEpoch = 0;
      _findNavigateReverse = false;
    });
  }

  void _onFindMatchCountChanged(int count) {
    if (count == _findMatchCount) {
      return;
    }
    setState(() {
      _findMatchCount = count;
      if (count <= 0) {
        _findActiveIndex = 0;
      } else {
        _findActiveIndex = wrapFindIndex(_findActiveIndex, count);
      }
    });
  }

  void _findNext() {
    if (_findMatchCount <= 0 || _findQuery.trim().isEmpty) {
      return;
    }
    setState(() {
      _findActiveIndex = wrapFindIndex(_findActiveIndex + 1, _findMatchCount);
      _findNavigateReverse = false;
      _findNavigateEpoch++;
    });
  }

  void _findPrevious() {
    if (_findMatchCount <= 0 || _findQuery.trim().isEmpty) {
      return;
    }
    setState(() {
      _findActiveIndex = wrapFindIndex(_findActiveIndex - 1, _findMatchCount);
      _findNavigateReverse = true;
      _findNavigateEpoch++;
    });
  }

  bool _usePortraitPaging(BuildContext context) {
    if (widget.onNavigateToMessage == null || widget.message == null) {
      return false;
    }
    if (widget.navigationIds.length < 2) {
      return false;
    }
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  @override
  Widget build(BuildContext context) {
    return _ReadingPaneOptions(
      allowOpenInNewWindow: widget.allowOpenInNewWindow,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Color secondaryText = Color.lerp(t.muted, t.text, 0.28)!;
    if (widget.message == null) {
      if (widget.findInMessageRequested) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onFindRequestHandled?.call();
          }
        });
      }
      return Container(
        color: t.content,
        alignment: Alignment.center,
        child: Text('Select a message', style: TextStyle(color: secondaryText)),
      );
    }

    if (_usePortraitPaging(context)) {
      return _PortraitReadingPager(
        selectedId: widget.message!.id,
        navigationIds: widget.navigationIds,
        navigationMessages: widget.navigationMessages,
        accounts: widget.accounts,
        density: widget.density,
        folderRole: widget.folderRole,
        isLoadingBody: widget.isLoadingBody,
        bodyErrorMessage: widget.bodyErrorMessage,
        blockRemoteImages: widget.blockRemoteImages,
        sessionAllowedRemoteImages: _sessionAllowedRemoteImages,
        onAllowRemoteImages: _allowRemoteImagesForMessage,
        onNavigateToMessage: widget.onNavigateToMessage!,
        findOpen: _findOpen,
        findQuery: _findQuery,
        findActiveIndex: _findActiveIndex,
        findMatchCount: _findMatchCount,
        findNavigateEpoch: _findNavigateEpoch,
        findNavigateReverse: _findNavigateReverse,
        onOpenFind: () => _openFind(notifyParent: true),
        onCloseFind: _closeFind,
        onFindQueryChanged: _onFindQueryChanged,
        onFindNext: _findNext,
        onFindPrevious: _findPrevious,
        onFindMatchCountChanged: _onFindMatchCountChanged,
        onMarkRead: widget.onMarkRead,
        onMarkUnread: widget.onMarkUnread,
        onShowHeaders: widget.onShowHeaders,
        onReply: widget.onReply,
        onReplyAll: widget.onReplyAll,
        onForward: widget.onForward,
        onArchive: widget.onArchive,
        onDelete: widget.onDelete,
        onPermanentDelete: widget.onPermanentDelete,
        onToggleStar: widget.onToggleStar,
        onPin: widget.onPin,
        onSnooze: widget.onSnooze,
        onMove: widget.onMove,
        onReportJunk: widget.onReportJunk,
        onRecover: widget.onRecover,
        onNotJunk: widget.onNotJunk,
        onMarkFocused: widget.onMarkFocused,
        onMarkOther: widget.onMarkOther,
      );
    }

    final MailMessage selected = widget.message!;
    return _ReadingPaneContent(
      message: selected,
      accounts: widget.accounts,
      density: widget.density,
      folderRole: widget.folderRole,
      isLoadingBody: widget.isLoadingBody,
      bodyErrorMessage: widget.bodyErrorMessage,
      blockRemoteImages: widget.blockRemoteImages,
      allowRemoteImages: _sessionAllowedRemoteImages.contains(selected.id),
      onLoadRemoteImages: () => _allowRemoteImagesForMessage(selected.id),
      findOpen: _findOpen,
      findQuery: _findQuery,
      findActiveIndex: _findActiveIndex,
      findMatchCount: _findMatchCount,
      findNavigateEpoch: _findNavigateEpoch,
      findNavigateReverse: _findNavigateReverse,
      onOpenFind: () => _openFind(notifyParent: true),
      onCloseFind: _closeFind,
      onFindQueryChanged: _onFindQueryChanged,
      onFindNext: _findNext,
      onFindPrevious: _findPrevious,
      onFindMatchCountChanged: _onFindMatchCountChanged,
      onMarkRead: widget.onMarkRead,
      onMarkUnread: widget.onMarkUnread,
      onShowHeaders: widget.onShowHeaders,
      onReply: widget.onReply,
      onReplyAll: widget.onReplyAll,
      onForward: widget.onForward,
      onArchive: widget.onArchive,
      onDelete: widget.onDelete,
      onPermanentDelete: widget.onPermanentDelete,
      onToggleStar: widget.onToggleStar,
      onPin: widget.onPin,
      onSnooze: widget.onSnooze,
      onMove: widget.onMove,
      onReportJunk: widget.onReportJunk,
      onRecover: widget.onRecover,
      onNotJunk: widget.onNotJunk,
      onMarkFocused: widget.onMarkFocused,
      onMarkOther: widget.onMarkOther,
    );
  }
}

/// Options inherited by overflow menus under [ReadingPane].
class _ReadingPaneOptions extends InheritedWidget {
  const _ReadingPaneOptions({
    required this.allowOpenInNewWindow,
    required super.child,
  });

  final bool allowOpenInNewWindow;

  static bool allowOpenInNewWindowOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_ReadingPaneOptions>()
            ?.allowOpenInNewWindow ??
        true;
  }

  @override
  bool updateShouldNotify(covariant _ReadingPaneOptions oldWidget) {
    return allowOpenInNewWindow != oldWidget.allowOpenInNewWindow;
  }
}

class _PortraitReadingPager extends StatefulWidget {
  const _PortraitReadingPager({
    required this.selectedId,
    required this.navigationIds,
    required this.navigationMessages,
    required this.accounts,
    required this.density,
    required this.onNavigateToMessage,
    required this.sessionAllowedRemoteImages,
    required this.onAllowRemoteImages,
    required this.findOpen,
    required this.findQuery,
    required this.findActiveIndex,
    required this.findMatchCount,
    required this.findNavigateEpoch,
    required this.findNavigateReverse,
    required this.onOpenFind,
    required this.onCloseFind,
    required this.onFindQueryChanged,
    required this.onFindNext,
    required this.onFindPrevious,
    required this.onFindMatchCountChanged,
    this.folderRole,
    this.isLoadingBody = false,
    this.bodyErrorMessage,
    this.blockRemoteImages = true,
    this.onMarkRead,
    this.onMarkUnread,
    this.onShowHeaders,
    this.onReply,
    this.onReplyAll,
    this.onForward,
    this.onArchive,
    this.onDelete,
    this.onPermanentDelete,
    this.onToggleStar,
    this.onPin,
    this.onSnooze,
    this.onMove,
    this.onReportJunk,
    this.onRecover,
    this.onNotJunk,
    this.onMarkFocused,
    this.onMarkOther,
  });

  final String selectedId;
  final List<String> navigationIds;
  final List<MailMessage> navigationMessages;
  final List<MailAccount> accounts;
  final ViewDensity density;
  final String? folderRole;
  final bool isLoadingBody;
  final String? bodyErrorMessage;
  final bool blockRemoteImages;
  final Set<String> sessionAllowedRemoteImages;
  final ValueChanged<String> onAllowRemoteImages;
  final ValueChanged<String> onNavigateToMessage;
  final bool findOpen;
  final String findQuery;
  final int findActiveIndex;
  final int findMatchCount;
  final int findNavigateEpoch;
  final bool findNavigateReverse;
  final VoidCallback onOpenFind;
  final VoidCallback onCloseFind;
  final ValueChanged<String> onFindQueryChanged;
  final VoidCallback onFindNext;
  final VoidCallback onFindPrevious;
  final ValueChanged<int> onFindMatchCountChanged;
  final VoidCallback? onMarkRead;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onShowHeaders;
  final VoidCallback? onReply;
  final VoidCallback? onReplyAll;
  final VoidCallback? onForward;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onPermanentDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onPin;
  final VoidCallback? onSnooze;
  final VoidCallback? onMove;
  final ValueChanged<AddressMatchScope>? onReportJunk;
  final VoidCallback? onRecover;
  final ValueChanged<AddressMatchScope>? onNotJunk;
  final ValueChanged<AddressMatchScope>? onMarkFocused;
  final ValueChanged<AddressMatchScope>? onMarkOther;

  @override
  State<_PortraitReadingPager> createState() => _PortraitReadingPagerState();
}

class _PortraitReadingPagerState extends State<_PortraitReadingPager> {
  late PageController _controller;
  bool _syncingFromParent = false;

  int _indexOf(String id) {
    final int index = widget.navigationIds.indexOf(id);
    return index < 0 ? 0 : index;
  }

  MailMessage? _messageFor(String id) {
    for (final MailMessage message in widget.navigationMessages) {
      if (message.id == id) {
        return message;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _indexOf(widget.selectedId));
  }

  @override
  void didUpdateWidget(covariant _PortraitReadingPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId ||
        widget.navigationIds != oldWidget.navigationIds) {
      final int target = _indexOf(widget.selectedId);
      if (_controller.hasClients &&
          (_controller.page?.round() ?? target) != target) {
        _syncingFromParent = true;
        _controller.jumpToPage(target);
        _syncingFromParent = false;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final int current = _indexOf(widget.selectedId);
    final bool canPrev = current > 0;
    final bool canNext = current < widget.navigationIds.length - 1;

    return Column(
      children: <Widget>[
        Material(
          color: t.content,
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Previous message',
                onPressed: canPrev
                    ? () => widget.onNavigateToMessage(
                          widget.navigationIds[current - 1],
                        )
                    : null,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: canPrev ? t.text : t.muted,
                ),
              ),
              Expanded(
                child: Text(
                  '${current + 1} of ${widget.navigationIds.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: 'Next message',
                onPressed: canNext
                    ? () => widget.onNavigateToMessage(
                          widget.navigationIds[current + 1],
                        )
                    : null,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: canNext ? t.text : t.muted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.navigationIds.length,
            onPageChanged: (int index) {
              if (_syncingFromParent) {
                return;
              }
              final String id = widget.navigationIds[index];
              if (id != widget.selectedId) {
                widget.onNavigateToMessage(id);
              }
            },
            itemBuilder: (BuildContext context, int index) {
              final String id = widget.navigationIds[index];
              final MailMessage? pageMessage = _messageFor(id);
              if (pageMessage == null) {
                return const SizedBox.shrink();
              }
              final bool isSelected = id == widget.selectedId;
              return _ReadingPaneContent(
                message: pageMessage,
                accounts: widget.accounts,
                density: widget.density,
                folderRole: widget.folderRole,
                isLoadingBody: isSelected && widget.isLoadingBody,
                bodyErrorMessage: isSelected ? widget.bodyErrorMessage : null,
                blockRemoteImages: widget.blockRemoteImages,
                allowRemoteImages:
                    widget.sessionAllowedRemoteImages.contains(id),
                onLoadRemoteImages: () => widget.onAllowRemoteImages(id),
                findOpen: isSelected && widget.findOpen,
                findQuery: isSelected ? widget.findQuery : '',
                findActiveIndex: isSelected ? widget.findActiveIndex : 0,
                findMatchCount: isSelected ? widget.findMatchCount : 0,
                findNavigateEpoch: isSelected ? widget.findNavigateEpoch : 0,
                findNavigateReverse:
                    isSelected && widget.findNavigateReverse,
                onOpenFind: isSelected ? widget.onOpenFind : null,
                onCloseFind: isSelected ? widget.onCloseFind : null,
                onFindQueryChanged:
                    isSelected ? widget.onFindQueryChanged : null,
                onFindNext: isSelected ? widget.onFindNext : null,
                onFindPrevious: isSelected ? widget.onFindPrevious : null,
                onFindMatchCountChanged:
                    isSelected ? widget.onFindMatchCountChanged : null,
                onMarkRead: isSelected ? widget.onMarkRead : null,
                onMarkUnread: isSelected ? widget.onMarkUnread : null,
                onShowHeaders: isSelected ? widget.onShowHeaders : null,
                onReply: isSelected ? widget.onReply : null,
                onReplyAll: isSelected ? widget.onReplyAll : null,
                onForward: isSelected ? widget.onForward : null,
                onArchive: isSelected ? widget.onArchive : null,
                onDelete: isSelected ? widget.onDelete : null,
                onPermanentDelete:
                    isSelected ? widget.onPermanentDelete : null,
                onToggleStar: isSelected ? widget.onToggleStar : null,
                onPin: isSelected ? widget.onPin : null,
                onSnooze: isSelected ? widget.onSnooze : null,
                onMove: isSelected ? widget.onMove : null,
                onReportJunk: isSelected ? widget.onReportJunk : null,
                onRecover: isSelected ? widget.onRecover : null,
                onNotJunk: isSelected ? widget.onNotJunk : null,
                onMarkFocused: isSelected ? widget.onMarkFocused : null,
                onMarkOther: isSelected ? widget.onMarkOther : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReadingPaneContent extends StatelessWidget {
  const _ReadingPaneContent({
    required this.message,
    required this.accounts,
    required this.density,
    this.folderRole,
    this.isLoadingBody = false,
    this.bodyErrorMessage,
    this.blockRemoteImages = true,
    this.allowRemoteImages = false,
    this.onLoadRemoteImages,
    this.findOpen = false,
    this.findQuery = '',
    this.findActiveIndex = 0,
    this.findMatchCount = 0,
    this.findNavigateEpoch = 0,
    this.findNavigateReverse = false,
    this.onOpenFind,
    this.onCloseFind,
    this.onFindQueryChanged,
    this.onFindNext,
    this.onFindPrevious,
    this.onFindMatchCountChanged,
    this.onMarkRead,
    this.onMarkUnread,
    this.onShowHeaders,
    this.onReply,
    this.onReplyAll,
    this.onForward,
    this.onArchive,
    this.onDelete,
    this.onPermanentDelete,
    this.onToggleStar,
    this.onPin,
    this.onSnooze,
    this.onMove,
    this.onReportJunk,
    this.onRecover,
    this.onNotJunk,
    this.onMarkFocused,
    this.onMarkOther,
  });

  final MailMessage message;
  final List<MailAccount> accounts;
  final ViewDensity density;
  final String? folderRole;
  final bool isLoadingBody;
  final String? bodyErrorMessage;
  final bool blockRemoteImages;
  final bool allowRemoteImages;
  final VoidCallback? onLoadRemoteImages;
  final bool findOpen;
  final String findQuery;
  final int findActiveIndex;
  final int findMatchCount;
  final int findNavigateEpoch;
  final bool findNavigateReverse;
  final VoidCallback? onOpenFind;
  final VoidCallback? onCloseFind;
  final ValueChanged<String>? onFindQueryChanged;
  final VoidCallback? onFindNext;
  final VoidCallback? onFindPrevious;
  final ValueChanged<int>? onFindMatchCountChanged;
  final VoidCallback? onMarkRead;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onShowHeaders;
  final VoidCallback? onReply;
  final VoidCallback? onReplyAll;
  final VoidCallback? onForward;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onPermanentDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onPin;
  final VoidCallback? onSnooze;
  final VoidCallback? onMove;
  final ValueChanged<AddressMatchScope>? onReportJunk;
  final VoidCallback? onRecover;
  final ValueChanged<AddressMatchScope>? onNotJunk;
  final ValueChanged<AddressMatchScope>? onMarkFocused;
  final ValueChanged<AddressMatchScope>? onMarkOther;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Color secondaryText = Color.lerp(t.muted, t.text, 0.28)!;
    final MailMessage msg = message;
    final MailAccount account = accounts.firstWhere(
      (MailAccount a) => a.id == msg.accountId,
      orElse: () => MailAccount(
        id: msg.accountId,
        label: '?',
        address: msg.accountId,
        accent: t.indigo,
      ),
    );
    final EdgeInsets pad = density == ViewDensity.calm
        ? const EdgeInsets.symmetric(horizontal: 32, vertical: 28)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 18);

    final bool inTrash = msg.trashedAt != null || ReadingPane.isTrashRole(folderRole);
    final bool inJunk = ReadingPane.isJunkRole(folderRole);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(t.content, t.indigo, 0.08)!,
            t.content,
          ],
          stops: const <double>[0, 0.25],
        ),
        color: t.content,
      ),
      // Keep a minimum body slot when the reading pane is short (top/bottom
      // split); scroll the chrome instead of starving MessageBodyView.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const double minBodyHeight = 96;
          final double headerMaxHeight =
              constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                  ? (constraints.maxHeight > minBodyHeight
                      ? constraints.maxHeight - minBodyHeight
                      : constraints.maxHeight * 0.45)
                  : double.infinity;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: headerMaxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: pad,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: account.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: account.accent.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: account.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    account.address,
                                    style: TextStyle(
                                      color: Color.lerp(
                                        account.accent,
                                        t.text,
                                        0.2,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              msg.subject,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${msg.fromName} <${msg.fromAddress}> · to me',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ReadingActionBar(
                              message: msg,
                              inTrash: inTrash,
                              inJunk: inJunk,
                              onMarkRead: onMarkRead,
                              onMarkUnread: onMarkUnread,
                              onShowHeaders: onShowHeaders,
                              onReply: onReply,
                              onReplyAll: onReplyAll,
                              onForward: onForward,
                              onArchive: onArchive,
                              onDelete: onDelete,
                              onPermanentDelete: onPermanentDelete,
                              onToggleStar: onToggleStar,
                              onPin: onPin,
                              onSnooze: onSnooze,
                              onMove: onMove,
                              onReportJunk: onReportJunk,
                              onRecover: onRecover,
                              onNotJunk: onNotJunk,
                              onMarkFocused: onMarkFocused,
                              onMarkOther: onMarkOther,
                              onOpenFind: onOpenFind,
                            ),
                          ],
                        ),
                      ),
                      if (findOpen &&
                          onCloseFind != null &&
                          onFindQueryChanged != null)
                        _MessageFindBar(
                          query: findQuery,
                          activeIndex: findActiveIndex,
                          matchCount: findMatchCount,
                          onQueryChanged: onFindQueryChanged!,
                          onNext: onFindNext ?? () {},
                          onPrevious: onFindPrevious ?? () {},
                          onClose: onCloseFind!,
                        ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: t.line),
              Expanded(
                child: Padding(
                  padding: pad,
                  child: MessageBodyView(
                    body: msg.body,
                    isLoadingBody: isLoadingBody,
                    bodyErrorMessage: bodyErrorMessage,
                    bodySize: density.bodySize,
                    muted: secondaryText,
                    blockRemoteImages: blockRemoteImages,
                    allowRemoteImages: allowRemoteImages,
                    onLoadRemoteImages: onLoadRemoteImages,
                    findQuery: findOpen ? findQuery : '',
                    findActiveIndex: findActiveIndex,
                    findNavigateEpoch: findNavigateEpoch,
                    findNavigateReverse: findNavigateReverse,
                    onFindMatchCountChanged: onFindMatchCountChanged,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageFindBar extends StatefulWidget {
  const _MessageFindBar({
    required this.query,
    required this.activeIndex,
    required this.matchCount,
    required this.onQueryChanged,
    required this.onNext,
    required this.onPrevious,
    required this.onClose,
  });

  final String query;
  final int activeIndex;
  final int matchCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onClose;

  @override
  State<_MessageFindBar> createState() => _MessageFindBarState();
}

class _MessageFindBarState extends State<_MessageFindBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _focusNode = FocusNode(debugLabel: 'MessageFindBar');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _MessageFindBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final String countLabel = widget.query.trim().isEmpty
        ? ''
        : widget.matchCount == 0
            ? '0 matches'
            : '${widget.activeIndex + 1} of ${widget.matchCount}';

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        const SingleActivator(LogicalKeyboardKey.enter): widget.onNext,
        const SingleActivator(LogicalKeyboardKey.enter, shift: true):
            widget.onPrevious,
        const SingleActivator(LogicalKeyboardKey.f3): widget.onNext,
        const SingleActivator(LogicalKeyboardKey.f3, shift: true):
            widget.onPrevious,
      },
      child: Material(
        color: t.panel2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: <Widget>[
              Icon(Icons.search_rounded, size: 18, color: t.muted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: TextStyle(color: t.text, fontSize: 13),
                  cursorColor: t.teal,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Find in message',
                    hintStyle: TextStyle(color: t.muted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: widget.onQueryChanged,
                  onSubmitted: (_) => widget.onNext(),
                ),
              ),
              if (countLabel.isNotEmpty) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  countLabel,
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
              ],
              IconButton(
                tooltip: 'Previous match',
                onPressed: widget.matchCount > 0 ? widget.onPrevious : null,
                icon: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: widget.matchCount > 0 ? t.text : t.muted,
                ),
              ),
              IconButton(
                tooltip: 'Next match',
                onPressed: widget.matchCount > 0 ? widget.onNext : null,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: widget.matchCount > 0 ? t.text : t.muted,
                ),
              ),
              IconButton(
                tooltip: 'Close find',
                onPressed: widget.onClose,
                icon: Icon(Icons.close_rounded, color: t.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingActionBar extends StatelessWidget {
  const _ReadingActionBar({
    required this.message,
    required this.inTrash,
    required this.inJunk,
    this.onMarkRead,
    this.onMarkUnread,
    this.onShowHeaders,
    this.onReply,
    this.onReplyAll,
    this.onForward,
    this.onArchive,
    this.onDelete,
    this.onPermanentDelete,
    this.onToggleStar,
    this.onPin,
    this.onSnooze,
    this.onMove,
    this.onReportJunk,
    this.onRecover,
    this.onNotJunk,
    this.onMarkFocused,
    this.onMarkOther,
    this.onOpenFind,
  });

  final MailMessage message;
  final bool inTrash;
  final bool inJunk;
  final VoidCallback? onMarkRead;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onShowHeaders;
  final VoidCallback? onReply;
  final VoidCallback? onReplyAll;
  final VoidCallback? onForward;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onPermanentDelete;
  final VoidCallback? onToggleStar;
  final VoidCallback? onPin;
  final VoidCallback? onSnooze;
  final VoidCallback? onMove;
  final ValueChanged<AddressMatchScope>? onReportJunk;
  final VoidCallback? onRecover;
  final ValueChanged<AddressMatchScope>? onNotJunk;
  final ValueChanged<AddressMatchScope>? onMarkFocused;
  final ValueChanged<AddressMatchScope>? onMarkOther;
  final VoidCallback? onOpenFind;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= kReadingPaneWideBreakpoint;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (onReply != null)
              _AdaptiveAction(
                wide: wide,
                label: 'Reply',
                icon: Icons.reply_rounded,
                onPressed: onReply!,
              ),
            if (onReplyAll != null)
              _AdaptiveAction(
                wide: wide,
                label: 'Reply all',
                icon: Icons.reply_all_rounded,
                onPressed: onReplyAll!,
              ),
            if (onForward != null)
              _AdaptiveAction(
                wide: wide,
                label: 'Forward',
                icon: Icons.forward_rounded,
                onPressed: onForward!,
              ),
            if (!inTrash && onArchive != null)
              _AdaptiveAction(
                wide: wide,
                label: 'Archive',
                icon: Icons.archive_outlined,
                onPressed: onArchive!,
              ),
            if (inTrash) ...<Widget>[
              if (onRecover != null)
                _AdaptiveAction(
                  wide: wide,
                  label: 'Recover',
                  icon: Icons.restore_from_trash_outlined,
                  onPressed: onRecover!,
                ),
              if (onPermanentDelete != null)
                _AdaptiveAction(
                  wide: wide,
                  label: 'Delete permanently',
                  icon: Icons.delete_forever_outlined,
                  onPressed: onPermanentDelete!,
                  danger: true,
                ),
            ] else if (onDelete != null)
              _AdaptiveAction(
                wide: wide,
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                onPressed: onDelete!,
                danger: true,
              ),
            if (onToggleStar != null)
              _AdaptiveAction(
                wide: wide,
                label: message.starred ? 'Starred' : 'Star',
                icon: message.starred
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                onPressed: onToggleStar!,
                emphasized: message.starred,
              ),
            if (onPin != null)
              _AdaptiveAction(
                wide: wide,
                label: message.pinned ? 'Pinned' : 'Pin',
                icon: message.pinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                onPressed: onPin!,
                emphasized: message.pinned,
              ),
            if (onSnooze != null)
              _AdaptiveAction(
                wide: wide,
                label: 'Snooze',
                icon: Icons.snooze_rounded,
                onPressed: onSnooze!,
              ),
            _OverflowActions(
              wide: wide,
              message: message,
              inTrash: inTrash,
              inJunk: inJunk,
              onMarkRead: onMarkRead,
              onMarkUnread: onMarkUnread,
              onShowHeaders: onShowHeaders,
              onMove: onMove,
              onReportJunk: onReportJunk,
              onNotJunk: onNotJunk,
              onMarkFocused: onMarkFocused,
              onMarkOther: onMarkOther,
              onOpenFind: onOpenFind,
            ),
          ],
        );
      },
    );
  }
}

class _OverflowActions extends StatelessWidget {
  const _OverflowActions({
    required this.wide,
    required this.message,
    required this.inTrash,
    required this.inJunk,
    this.onMarkRead,
    this.onMarkUnread,
    this.onShowHeaders,
    this.onMove,
    this.onReportJunk,
    this.onNotJunk,
    this.onMarkFocused,
    this.onMarkOther,
    this.onOpenFind,
  });

  final bool wide;
  final MailMessage message;
  final bool inTrash;
  final bool inJunk;
  final VoidCallback? onMarkRead;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onShowHeaders;
  final VoidCallback? onMove;
  final ValueChanged<AddressMatchScope>? onReportJunk;
  final ValueChanged<AddressMatchScope>? onNotJunk;
  final ValueChanged<AddressMatchScope>? onMarkFocused;
  final ValueChanged<AddressMatchScope>? onMarkOther;
  final VoidCallback? onOpenFind;

  bool get _hasSecondaryMenu => true;

  @override
  Widget build(BuildContext context) {
    // Print / Save EML / Open in new window are always available.
    if (wide) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (onMarkFocused != null)
            AddressScopeOutlinedIconAction(
              label: 'Focused',
              icon: Icons.center_focus_strong_outlined,
              senderAddress: message.fromAddress,
              emphasized: message.bucket == FocusBucket.focused,
              onSelected: onMarkFocused!,
            ),
          if (onMarkFocused != null) const SizedBox(width: 8),
          if (onMarkOther != null)
            AddressScopeOutlinedIconAction(
              label: 'Other',
              icon: Icons.filter_alt_outlined,
              senderAddress: message.fromAddress,
              emphasized: message.bucket == FocusBucket.other,
              onSelected: onMarkOther!,
            ),
          if (onMarkOther != null) const SizedBox(width: 8),
          if (inJunk && onNotJunk != null)
            AddressScopeOutlinedIconAction(
              label: 'Not junk',
              icon: Icons.health_and_safety_outlined,
              senderAddress: message.fromAddress,
              onSelected: onNotJunk!,
            ),
          if (inJunk && onNotJunk != null) const SizedBox(width: 8),
          if (!inJunk && !inTrash && onReportJunk != null)
            AddressScopeOutlinedIconAction(
              label: 'Report junk',
              icon: Icons.report_gmailerrorred_outlined,
              senderAddress: message.fromAddress,
              danger: true,
              onSelected: onReportJunk!,
            ),
          if (!inJunk && !inTrash && onReportJunk != null)
            const SizedBox(width: 8),
          if (_hasSecondaryMenu)
            _MoreMenu(
              message: message,
              inTrash: inTrash,
              inJunk: inJunk,
              includeAddressScope: false,
              onMarkRead: onMarkRead,
              onMarkUnread: onMarkUnread,
              onShowHeaders: onShowHeaders,
              onMove: onMove,
              onReportJunk: onReportJunk,
              onNotJunk: onNotJunk,
              onMarkFocused: onMarkFocused,
              onMarkOther: onMarkOther,
              onOpenFind: onOpenFind,
            ),
        ],
      );
    }

    return _MoreMenu(
      message: message,
      inTrash: inTrash,
      inJunk: inJunk,
      includeAddressScope: true,
      onMarkRead: onMarkRead,
      onMarkUnread: onMarkUnread,
      onShowHeaders: onShowHeaders,
      onMove: onMove,
      onReportJunk: onReportJunk,
      onNotJunk: onNotJunk,
      onMarkFocused: onMarkFocused,
      onMarkOther: onMarkOther,
      onOpenFind: onOpenFind,
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.message,
    required this.inTrash,
    required this.inJunk,
    required this.includeAddressScope,
    this.onMarkRead,
    this.onMarkUnread,
    this.onShowHeaders,
    this.onMove,
    this.onReportJunk,
    this.onNotJunk,
    this.onMarkFocused,
    this.onMarkOther,
    this.onOpenFind,
  });

  final MailMessage message;
  final bool inTrash;
  final bool inJunk;
  final bool includeAddressScope;
  final VoidCallback? onMarkRead;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onShowHeaders;
  final VoidCallback? onMove;
  final ValueChanged<AddressMatchScope>? onReportJunk;
  final ValueChanged<AddressMatchScope>? onNotJunk;
  final ValueChanged<AddressMatchScope>? onMarkFocused;
  final ValueChanged<AddressMatchScope>? onMarkOther;
  final VoidCallback? onOpenFind;

  Future<void> _print(BuildContext context) async {
    try {
      final PrintingInfo info = await Printing.info();
      if (!context.mounted) {
        return;
      }
      if (!info.canPrint && !info.canShare) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Printing is not available on this device.'),
          ),
        );
        return;
      }

      // Windows PrintDlg often fails if opened during popup teardown; wait,
      // retry once, then fall back to the share/save PDF sheet.
      bool completed = false;
      if (info.canPrint) {
        completed = await printMessage(message);
        if (!completed && context.mounted) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          if (context.mounted) {
            completed = await printMessage(message);
          }
        }
      }

      if (completed || !context.mounted) {
        return;
      }

      if (info.canShare) {
        await shareMessagePdf(message);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Opened PDF share/save — use Print from there if needed.',
              ),
            ),
          );
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Print cancelled.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $error')),
      );
    }
  }

  Future<void> _saveEml(BuildContext context) async {
    try {
      final String? path = await saveMessageAsEml(message);
      if (!context.mounted) {
        return;
      }
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save cancelled')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved EML to $path')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save EML failed: $error')),
      );
    }
  }

  Future<void> _openDetached(BuildContext context) async {
    try {
      await context
          .read<DetachedMessageWindowController>()
          .showMessage(message.id);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Open in new window failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Semantics(
      button: true,
      label: 'More actions',
      child: PopupMenuButton<String>(
        tooltip: 'More actions',
        onSelected: (String value) {
          if (value.startsWith('address_scope:')) {
            return;
          }
          switch (value) {
            case 'headers':
              onShowHeaders?.call();
            case 'move':
              onMove?.call();
            case 'mark_read':
              onMarkRead?.call();
            case 'mark_unread':
              onMarkUnread?.call();
            case 'find':
              onOpenFind?.call();
            case 'print':
              // Defer until the popup route has torn down — opening PrintDlg
              // during menu dismiss often fails silently on Windows.
              final BuildContext menuContext = context;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await Future<void>.delayed(const Duration(milliseconds: 120));
                if (menuContext.mounted) {
                  await _print(menuContext);
                }
              });
            case 'save_eml':
              unawaited(_saveEml(context));
            case 'open_window':
              unawaited(_openDetached(context));
          }
        },
        itemBuilder: (BuildContext context) {
          final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[];
          if (message.unread && onMarkRead != null) {
            items.add(
              const PopupMenuItem<String>(
                value: 'mark_read',
                child: Text('Mark read'),
              ),
            );
          }
          if (!message.unread && onMarkUnread != null) {
            items.add(
              const PopupMenuItem<String>(
                value: 'mark_unread',
                child: Text('Mark unread'),
              ),
            );
          }
          if (onShowHeaders != null) {
            items.add(
              const PopupMenuItem<String>(
                value: 'headers',
                child: Text('Headers'),
              ),
            );
          }
          if (onMove != null) {
            items.add(
              const PopupMenuItem<String>(
                value: 'move',
                child: Text('Move'),
              ),
            );
          }
          if (items.isNotEmpty) {
            items.add(const PopupMenuDivider());
          }
          items.add(
            const PopupMenuItem<String>(
              value: 'find',
              child: Text('Find in message'),
            ),
          );
          items.add(
            const PopupMenuItem<String>(
              value: 'print',
              child: Text('Print'),
            ),
          );
          items.add(
            const PopupMenuItem<String>(
              value: 'save_eml',
              child: Text('Save as EML'),
            ),
          );
          if (_ReadingPaneOptions.allowOpenInNewWindowOf(context)) {
            items.add(
              const PopupMenuItem<String>(
                value: 'open_window',
                child: Text('Open in new window'),
              ),
            );
          }
          if (includeAddressScope) {
            if (onMarkFocused != null) {
              items.add(
                addressScopeOverflowItem(
                  context: context,
                  label: 'Focused',
                  senderAddress: message.fromAddress,
                  onSelected: onMarkFocused!,
                ),
              );
            }
            if (onMarkOther != null) {
              items.add(
                addressScopeOverflowItem(
                  context: context,
                  label: 'Other',
                  senderAddress: message.fromAddress,
                  onSelected: onMarkOther!,
                ),
              );
            }
            if (inJunk && onNotJunk != null) {
              items.add(
                addressScopeOverflowItem(
                  context: context,
                  label: 'Not junk',
                  senderAddress: message.fromAddress,
                  onSelected: onNotJunk!,
                ),
              );
            }
            if (!inJunk && !inTrash && onReportJunk != null) {
              items.add(
                addressScopeOverflowItem(
                  context: context,
                  label: 'Report junk',
                  senderAddress: message.fromAddress,
                  onSelected: onReportJunk!,
                  danger: true,
                ),
              );
            }
          }
          return items;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.line),
          ),
          child: Icon(Icons.more_horiz_rounded, size: 20, color: t.text),
        ),
      ),
    );
  }
}

class _AdaptiveAction extends StatelessWidget {
  const _AdaptiveAction({
    required this.wide,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
    this.emphasized = false,
  });

  final bool wide;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;
  final bool emphasized;

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

    if (wide) {
      return Semantics(
        button: true,
        label: label,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: foreground),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: foreground,
            side: BorderSide(color: border),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        tooltip: label,
        icon: Icon(icon, size: 20, color: foreground),
        style: IconButton.styleFrom(
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
