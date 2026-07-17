// ==============================================================================
// File: lib/protocol/imap_smtp_mail_provider.dart
// Description: IMAP and SMTP implementation of the remote mail contract.
// Component: Protocol / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:bytemail/focus/focus_header_map.dart';
import 'package:bytemail/protocol/mail_date_parser.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/protocol/thread_id.dart';
import 'package:enough_mail/enough_mail.dart';

/// Maps enough_mail special-use flags to ByteMail folder roles.
String? imapMailboxRole(Mailbox mailbox) {
  if (mailbox.isInbox) {
    return 'inbox';
  }
  if (mailbox.isTrash) {
    return 'trash';
  }
  if (mailbox.isJunk) {
    return 'junk';
  }
  if (mailbox.isArchive) {
    return 'archive';
  }
  if (mailbox.isSent) {
    return 'sentitems';
  }
  if (mailbox.isDrafts) {
    return 'drafts';
  }
  return null;
}

/// Whether [messagesExists] means [ImapClient.fetchRecentMessages] must be
/// skipped (enough_mail builds `FETCH 1:0` on empty boxes).
bool imapShouldSkipRecentFetch(int messagesExists) => messagesExists < 1;

/// True when [error] looks like IMAP rejecting an empty/invalid FETCH set.
bool imapIsInvalidMessagesetError(Object error) {
  final String lower = error.toString().toLowerCase();
  return lower.contains('invalid messageset') ||
      (lower.contains('messageset') && lower.contains('fetch'));
}

/// True when [error] looks like a dropped IMAP socket (safe to reconnect once).
bool imapIsConnectionLostError(Object error) {
  final String lower = error.toString().toLowerCase();
  if (imapIsAuthFailure(error)) {
    return false;
  }
  return lower.contains('connection') ||
      lower.contains('socket') ||
      lower.contains('closed') ||
      lower.contains('not connected') ||
      lower.contains('timed out') ||
      lower.contains('timeout') ||
      lower.contains('connection lost');
}

/// True when [error] looks like IMAP/SMTP authentication failure (do not retry).
bool imapIsAuthFailure(Object error) {
  final String lower = error.toString().toLowerCase();
  return lower.contains('authentication failed') ||
      lower.contains('auth failed') ||
      lower.contains('login failed') ||
      lower.contains('not authenticated') ||
      lower.contains('invalid credentials') ||
      lower.contains('authenticationfailed');
}

/// Parent mailbox path when [mailbox] is nested; otherwise null.
String? imapMailboxParentProviderId(Mailbox mailbox) {
  final String path = mailbox.path;
  final String separator = mailbox.pathSeparator;
  if (separator.isEmpty) {
    return null;
  }
  final int lastSplit = path.lastIndexOf(separator);
  if (lastSplit <= 0) {
    return null;
  }
  final String parent = path.substring(0, lastSplit);
  return parent.isEmpty ? null : parent;
}

/// How [ImapSmtpMailProvider] authenticates to IMAP/SMTP.
enum ImapAuthMode {
  /// Classic LOGIN / PLAIN with [ImapSmtpMailProvider.password].
  password,

  /// XOAUTH2; [ImapSmtpMailProvider.password] holds a Google access token.
  xoauth2,
}

/// IMAP receiver and SMTP sender (password or XOAUTH2).
///
/// The instance serializes its use through the underlying clients. Create and
/// use it inside the sync isolate; do not share it with the Flutter UI isolate.
class ImapSmtpMailProvider extends MailProvider {
  ImapSmtpMailProvider({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.smtpHost,
    required this.smtpPort,
    this.authMode = ImapAuthMode.password,
  });

  final String host;
  final int port;
  final String user;

  /// App password / account password, or OAuth access token when [authMode]
  /// is [ImapAuthMode.xoauth2].
  final String password;
  final String smtpHost;
  final int smtpPort;
  final ImapAuthMode authMode;

  final ImapClient _imap = ImapClient();
  bool _imapConnected = false;
  bool _disposed = false;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
        supportsServerSearch: true,
        supportsPush: true,
        supportsPartialBody: true,
        supportsSend: true,
        supportsStar: true,
        supportsMove: true,
        supportsDelete: true,
        supportsAttachments: true,
      );

  @override
  Future<List<RemoteFolder>> listFolders() async {
    try {
      final ImapClient imap = await _connectedImap();
      final List<Mailbox> mailboxes = await imap.listMailboxes(recursive: true);
      return mailboxes
          .map(
            (Mailbox mailbox) => RemoteFolder(
              providerId: mailbox.path,
              name: mailbox.name,
              parentProviderId: imapMailboxParentProviderId(mailbox),
              role: imapMailboxRole(mailbox),
              unreadCount: mailbox.messagesUnseen,
              totalCount: mailbox.messagesExists,
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw _protocolError('Unable to list IMAP folders.', error);
    }
  }

  @override
  Future<RemoteFolder> createFolder({
    required String displayName,
    String? role,
  }) async {
    final String path = displayName.trim();
    if (path.isEmpty) {
      throw const ProtocolException('A folder name is required.');
    }
    try {
      final ImapClient imap = await _connectedImap();
      final Mailbox mailbox = await imap.createMailbox(path);
      return RemoteFolder(
        providerId: mailbox.path,
        name: mailbox.name,
        parentProviderId: imapMailboxParentProviderId(mailbox),
        role: role ?? imapMailboxRole(mailbox),
        unreadCount: mailbox.messagesUnseen,
        totalCount: mailbox.messagesExists,
      );
    } catch (error) {
      throw _protocolError('Unable to create IMAP folder.', error);
    }
  }

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) {
    return listRecentInFolder('INBOX', limit: limit);
  }

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async {
    if (limit < 1) {
      return <RemoteMessageHeader>[];
    }
    Object? lastError;
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final ImapClient imap = await _connectedImap(
          forceReconnect: attempt > 0,
        );
        final Mailbox mailbox = await _selectFolder(imap, folderRemoteId);
        if (imapShouldSkipRecentFetch(mailbox.messagesExists)) {
          return <RemoteMessageHeader>[];
        }
        final FetchImapResult result = await imap.fetchRecentMessages(
          messageCount: limit,
          criteria:
              '(UID FLAGS ENVELOPE BODYSTRUCTURE '
              'BODY.PEEK[HEADER.FIELDS ('
              'MESSAGE-ID SUBJECT FROM DATE '
              'LIST-ID LIST-UNSUBSCRIBE LIST-UNSUBSCRIBE-POST '
              'PRECEDENCE AUTO-SUBMITTED X-CAMPAIGN FEEDBACK-ID X-MAILER'
              ')])',
        );
        return result.messages
            .map(_headerFromMessage)
            .toList(growable: false)
            .reversed
            .toList(growable: false);
      } catch (error) {
        if (imapIsInvalidMessagesetError(error)) {
          return <RemoteMessageHeader>[];
        }
        lastError = error;
        final bool canRetry = attempt == 0 && imapIsConnectionLostError(error);
        if (canRetry) {
          continue;
        }
        throw _protocolError('Unable to list recent IMAP messages.', error);
      }
    }
    throw _protocolError(
      'Unable to list recent IMAP messages.',
      lastError ?? const ProtocolException('IMAP list failed after retry.'),
    );
  }

  @override
  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  }) async {
    final int? uid = int.tryParse(providerId);
    if (uid == null) {
      throw const ProtocolException('An IMAP message id must be a numeric UID.');
    }
    try {
      final ImapClient imap = await _connectedImap();
      await _selectFolder(imap, folderRemoteId ?? 'INBOX');
      final FetchImapResult result = await imap.uidFetchMessage(
        uid,
        'BODY.PEEK[]',
      );
      if (result.messages.isEmpty) {
        return null;
      }
      final MimeMessage message = result.messages.first;
      // Prefer HTML so the reading pane can render images/layout; plain is fallback.
      return message.decodeTextHtmlPart() ?? message.decodeTextPlainPart();
    } catch (error) {
      throw _protocolError('Unable to fetch the IMAP message body.', error);
    }
  }

  @override
  Future<String?> fetchHeaders(
    String providerId, {
    String? folderRemoteId,
  }) async {
    final int? uid = int.tryParse(providerId);
    if (uid == null) {
      throw const ProtocolException('An IMAP message id must be a numeric UID.');
    }
    try {
      final ImapClient imap = await _connectedImap();
      await _selectFolder(imap, folderRemoteId ?? 'INBOX');
      final FetchImapResult result = await imap.uidFetchMessage(
        uid,
        'BODY.PEEK[HEADER]',
      );
      if (result.messages.isEmpty) {
        return null;
      }
      return _formatMimeHeaders(result.messages.first);
    } catch (error) {
      throw _protocolError('Unable to fetch IMAP message headers.', error);
    }
  }

  Future<Mailbox> _selectFolder(
    ImapClient imap,
    String folderRemoteId,
  ) async {
    final String path = folderRemoteId.trim();
    if (path.isEmpty || path.toUpperCase() == 'INBOX') {
      return imap.selectInbox();
    }
    return imap.selectMailboxByPath(path);
  }

  @override
  Future<void> send({
    required List<String> to,
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    required String subject,
    required String body,
  }) async {
    final List<MailAddress> toAddresses = _mailAddresses(to);
    final List<MailAddress> ccAddresses = _mailAddresses(cc);
    final List<MailAddress> bccAddresses = _mailAddresses(bcc);
    if (toAddresses.isEmpty &&
        ccAddresses.isEmpty &&
        bccAddresses.isEmpty) {
      throw const ProtocolException('A recipient is required to send mail.');
    }
    final SmtpClient smtp = SmtpClient(_smtpClientDomain());
    MimeMessage? builtMessage;
    try {
      await smtp.connectToServer(
        smtpHost,
        smtpPort,
        isSecure: smtpPort == 465,
      );
      await smtp.ehlo();
      if (smtpPort != 465 && smtp.serverInfo.supportsStartTls) {
        final SmtpResponse tlsResponse = await smtp.startTls();
        if (!tlsResponse.isOkStatus) {
          throw ProtocolException(
            'SMTP STARTTLS failed: $tlsResponse',
          );
        }
      }
      if (authMode == ImapAuthMode.xoauth2) {
        await smtp.authenticate(user, password, AuthMechanism.xoauth2);
      } else {
        await smtp.authenticate(user, password);
      }
      final MessageBuilder builder = MessageBuilder(text: body)
        ..from = <MailAddress>[MailAddress(null, user)]
        ..subject = subject;
      if (toAddresses.isNotEmpty) {
        builder.to = toAddresses;
      }
      if (ccAddresses.isNotEmpty) {
        builder.cc = ccAddresses;
      }
      if (bccAddresses.isNotEmpty) {
        builder.bcc = bccAddresses;
      }
      builtMessage = builder.buildMimeMessage();
      final SmtpResponse response = await smtp.sendMessage(builtMessage);
      if (!response.isOkStatus) {
        throw ProtocolException('SMTP server rejected the message: $response');
      }
    } catch (error) {
      throw _protocolError('Unable to send SMTP mail.', error);
    } finally {
      await smtp.disconnect();
    }
    if (builtMessage != null) {
      await _appendToSentBestEffort(builtMessage);
    }
  }

  List<MailAddress> _mailAddresses(List<String> addresses) {
    final List<MailAddress> result = <MailAddress>[];
    for (final String raw in addresses) {
      final String trimmed = raw.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      try {
        result.add(MailAddress.parse(trimmed));
      } on FormatException {
        result.add(MailAddress(null, trimmed));
      }
    }
    return result;
  }

  /// Best-effort APPEND of [message] into the Sent mailbox; never fails send.
  Future<void> _appendToSentBestEffort(MimeMessage message) async {
    try {
      final ImapClient imap = await _connectedImap();
      final List<Mailbox> mailboxes = await imap.listMailboxes(recursive: true);
      Mailbox? sent;
      for (final Mailbox mailbox in mailboxes) {
        if (mailbox.isSent) {
          sent = mailbox;
          break;
        }
      }
      if (sent == null) {
        for (final Mailbox mailbox in mailboxes) {
          final String path = mailbox.path.toLowerCase();
          final String name = mailbox.name.toLowerCase();
          if (path.endsWith('sent') ||
              path.contains('sent items') ||
              name == 'sent' ||
              name == 'sent items') {
            sent = mailbox;
            break;
          }
        }
      }
      if (sent == null) {
        return;
      }
      await imap.appendMessage(
        message,
        targetMailbox: sent,
        flags: <String>[MessageFlags.seen],
      );
    } on Object {
      // Soft-fail: SMTP delivery already succeeded.
    }
  }

  @override
  Future<List<RemoteMessageHeader>> searchRemote(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return <RemoteMessageHeader>[];
    }
    if (trimmedQuery.contains('"') || trimmedQuery.contains('\r') || trimmedQuery.contains('\n')) {
      throw const ProtocolException('IMAP search text contains unsupported characters.');
    }
    try {
      final ImapClient imap = await _connectedImap();
      await imap.selectInbox();
      final SearchImapResult matches = await imap.uidSearchMessages(
        searchCriteria: 'TEXT "$trimmedQuery"',
      );
      final MessageSequence? sequence = matches.matchingSequence;
      if (sequence == null || sequence.isEmpty) {
        return <RemoteMessageHeader>[];
      }
      final FetchImapResult result = await imap.uidFetchMessages(
        sequence,
        '(UID FLAGS ENVELOPE BODYSTRUCTURE '
        'BODY.PEEK[HEADER.FIELDS (MESSAGE-ID SUBJECT FROM DATE)])',
      );
      return result.messages.map(_headerFromMessage).toList(growable: false);
    } catch (error) {
      throw _protocolError('Unable to search IMAP messages.', error);
    }
  }

  @override
  Future<void> setRead(
    String providerId, {
    required bool isRead,
    String? folderRemoteId,
  }) async {
    final int uid = _parseUid(providerId);
    try {
      final ImapClient imap = await _connectedImap();
      await _selectFolder(imap, folderRemoteId ?? 'INBOX');
      final MessageSequence sequence = MessageSequence.fromId(uid, isUid: true);
      if (isRead) {
        await imap.uidMarkSeen(sequence);
      } else {
        await imap.uidStore(
          sequence,
          <String>[MessageFlags.seen],
          action: StoreAction.remove,
        );
      }
    } catch (error) {
      throw _protocolError('Unable to update IMAP read state.', error);
    }
  }

  @override
  Future<void> setStarred(String providerMessageId, bool starred) async {
    final int uid = _parseUid(providerMessageId);
    try {
      final ImapClient imap = await _connectedImap();
      await imap.selectInbox();
      final MessageSequence sequence = MessageSequence.fromId(uid, isUid: true);
      if (starred) {
        await imap.uidMarkFlagged(sequence);
      } else {
        await imap.uidMarkUnflagged(sequence);
      }
    } catch (error) {
      throw _protocolError('Unable to update IMAP starred state.', error);
    }
  }

  @override
  Future<void> moveMessage(
    String providerMessageId,
    String targetFolderRemoteId, {
    String? sourceFolderRemoteId,
  }) async {
    final int uid = _parseUid(providerMessageId);
    final String target = targetFolderRemoteId.trim();
    if (target.isEmpty) {
      throw const ProtocolException('A target folder path is required to move mail.');
    }
    try {
      final ImapClient imap = await _connectedImap();
      await _selectFolder(imap, sourceFolderRemoteId ?? 'INBOX');
      final MessageSequence sequence = MessageSequence.fromId(uid, isUid: true);
      await imap.uidMove(sequence, targetMailboxPath: target);
    } catch (error) {
      throw _protocolError('Unable to move IMAP message.', error);
    }
  }

  @override
  Future<void> deleteMessage(
    String providerMessageId, {
    bool permanent = false,
    String? folderRemoteId,
  }) async {
    final int uid = _parseUid(providerMessageId);
    try {
      final ImapClient imap = await _connectedImap();
      await _selectFolder(imap, folderRemoteId ?? 'INBOX');
      final MessageSequence sequence = MessageSequence.fromId(uid, isUid: true);
      await imap.uidMarkDeleted(sequence);
      if (permanent) {
        await imap.uidExpunge(sequence);
      }
    } catch (error) {
      throw _protocolError('Unable to delete IMAP message.', error);
    }
  }

  @override
  Future<List<MailAttachmentMeta>> listAttachments(
    String providerMessageId,
  ) async {
    final int uid = _parseUid(providerMessageId);
    try {
      final ImapClient imap = await _connectedImap();
      await imap.selectInbox();
      final FetchImapResult result = await imap.uidFetchMessage(
        uid,
        'BODYSTRUCTURE',
      );
      if (result.messages.isEmpty) {
        return const <MailAttachmentMeta>[];
      }
      final MimeMessage message = result.messages.first;
      final List<ContentInfo> infos = message.findContentInfo();
      return infos
          .map(
            (ContentInfo info) => MailAttachmentMeta(
              partId: info.fetchId,
              name: info.fileName ?? 'attachment',
              contentType: info.mediaType?.text ?? 'application/octet-stream',
              sizeBytes: info.size,
              isInline: false,
              contentId: info.cid,
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw _protocolError('Unable to list IMAP attachments.', error);
    }
  }

  @override
  Future<MailAttachmentBytes> fetchAttachment(
    String providerMessageId,
    String partId,
  ) async {
    final int uid = _parseUid(providerMessageId);
    final String trimmedPart = partId.trim();
    if (trimmedPart.isEmpty) {
      throw const ProtocolException('An IMAP attachment part id is required.');
    }
    try {
      final ImapClient imap = await _connectedImap();
      await imap.selectInbox();
      final FetchImapResult result = await imap.uidFetchMessage(
        uid,
        'BODY.PEEK[$trimmedPart]',
      );
      if (result.messages.isEmpty) {
        throw const ProtocolException('IMAP attachment part was not found.');
      }
      final MimeMessage message = result.messages.first;
      final MimePart part = message.getPart(trimmedPart) ?? message;
      final Uint8List? bytes = part.decodeContentBinary();
      if (bytes == null) {
        throw const ProtocolException('IMAP attachment part had no binary content.');
      }
      return MailAttachmentBytes(
        partId: trimmedPart,
        bytes: bytes,
        contentType: part.mediaType.text,
        name: part.getHeaderContentDisposition()?.filename,
      );
    } catch (error) {
      throw _protocolError('Unable to fetch IMAP attachment.', error);
    }
  }

  int _parseUid(String providerId) {
    final int? uid = int.tryParse(providerId);
    if (uid == null) {
      throw const ProtocolException('An IMAP message id must be a numeric UID.');
    }
    return uid;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_imapConnected) {
      try {
        await _imap.logout();
      } catch (_) {
        // The socket still needs to be closed if logout cannot complete.
      }
      await _imap.disconnect();
      _imapConnected = false;
    }
  }

  Future<void> _forceDisconnectImap() async {
    if (!_imapConnected) {
      return;
    }
    try {
      await _imap.disconnect();
    } catch (_) {
      // Socket may already be dead; still clear the connected flag.
    }
    _imapConnected = false;
  }

  Future<ImapClient> _connectedImap({bool forceReconnect = false}) async {
    if (_disposed) {
      throw const ProtocolException('This IMAP provider has been disposed.');
    }
    if (forceReconnect) {
      await _forceDisconnectImap();
    }
    if (!_imapConnected) {
      await _imap.connectToServer(host, port, isSecure: port == 993);
      if (port != 993 && _imap.serverInfo.supportsStartTls) {
        await _imap.startTls();
      }
      if (authMode == ImapAuthMode.xoauth2) {
        await _imap.authenticateWithOAuth2(user, password);
      } else {
        await _imap.login(user, password);
      }
      _imapConnected = true;
    }
    return _imap;
  }

  /// Watches INBOX via IMAP IDLE until [shouldContinue] returns false.
  ///
  /// Calls [onMailboxChanged] on EXISTS/RECENT. Renews IDLE every [renewEvery]
  /// so the server does not drop the session. Does not block the UI isolate
  /// beyond awaiting futures in this async loop.
  ///
  /// Returns false when the server does not advertise IDLE.
  Future<bool> runInboxIdleLoop({
    required void Function() onMailboxChanged,
    required Future<bool> Function() shouldContinue,
    Duration renewEvery = const Duration(minutes: 25),
  }) async {
    final ImapClient imap = await _connectedImap();
    if (!imap.serverInfo.supportsIdle) {
      return false;
    }
    await imap.selectInbox();

    StreamSubscription<ImapEvent>? subscription;
    try {
      subscription = imap.eventBus.on<ImapEvent>().listen((ImapEvent event) {
        if (event.eventType == ImapEventType.exists ||
            event.eventType == ImapEventType.recent) {
          onMailboxChanged();
        }
      });

      while (await shouldContinue()) {
        if (_disposed) {
          break;
        }
        await imap.idleStart();
        final bool stillWanted = await _waitIdleWindow(
          renewEvery,
          shouldContinue,
        );
        try {
          await imap.idleDone();
        } on Object {
          // Connection may already be closed; exit the loop.
          break;
        }
        if (!stillWanted) {
          break;
        }
      }
    } catch (error) {
      throw _protocolError('IMAP IDLE watch failed.', error);
    } finally {
      await subscription?.cancel();
    }
    return true;
  }

  /// Waits up to [window] or until [shouldContinue] flips false.
  Future<bool> _waitIdleWindow(
    Duration window,
    Future<bool> Function() shouldContinue,
  ) async {
    final DateTime deadline = DateTime.now().add(window);
    while (DateTime.now().isBefore(deadline)) {
      if (!await shouldContinue()) {
        return false;
      }
      final Duration remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        break;
      }
      final Duration slice =
          remaining < const Duration(seconds: 5) ? remaining : const Duration(seconds: 5);
      await Future<void>.delayed(slice);
    }
    return shouldContinue();
  }

  RemoteMessageHeader _headerFromMessage(MimeMessage message) {
    final int? uid = message.uid;
    if (uid == null) {
      throw const ProtocolException('IMAP server did not return a message UID.');
    }
    final MailAddress? sender =
        message.from != null && message.from!.isNotEmpty ? message.from!.first : null;
    final String providerId = uid.toString();
    final String? messageIdHeader = message.getHeaderValue('message-id');
    final String? inReplyTo = message.getHeaderValue('in-reply-to');
    final String? references = message.getHeaderValue('references');
    return RemoteMessageHeader(
      providerId: providerId,
      subject: message.decodeSubject() ?? '',
      fromAddress: sender?.email ?? message.fromEmail ?? '',
      fromName: sender?.personalName,
      messageIdHeader: messageIdHeader,
      threadId: resolveThreadId(
        messageId: messageIdHeader,
        inReplyTo: inReplyTo,
        references: references,
        fallbackProviderId: providerId,
      ),
      inReplyTo: inReplyTo,
      references: references,
      receivedAt:
          parseMailDate(message.getHeaderValue('date')) ??
          message.decodeDate() ??
          DateTime.now(),
      isRead: message.isSeen,
      hasAttachments: message.hasAttachments(),
      classificationHeaders: focusHeadersFromFields(
        listId: message.getHeaderValue('list-id'),
        listUnsubscribe: message.getHeaderValue('list-unsubscribe'),
        listUnsubscribePost: message.getHeaderValue('list-unsubscribe-post'),
        precedence: message.getHeaderValue('precedence'),
        autoSubmitted: message.getHeaderValue('auto-submitted'),
        xCampaign: message.getHeaderValue('x-campaign'),
        feedbackId: message.getHeaderValue('feedback-id'),
        xMailer: message.getHeaderValue('x-mailer'),
      ),
    );
  }

  String? _formatMimeHeaders(MimeMessage message) {
    final List<Header>? headers = message.headers;
    if (headers == null || headers.isEmpty) {
      return null;
    }
    final String text = headers
        .map((Header header) => '${header.name}: ${header.value}')
        .join('\n')
        .trim();
    return text.isEmpty ? null : text;
  }

  String _smtpClientDomain() {
    final int atIndex = user.lastIndexOf('@');
    return atIndex == -1 ? smtpHost : user.substring(atIndex + 1);
  }

  ProtocolException _protocolError(String message, Object error) => error is ProtocolException
      ? error
      : ProtocolException(message, cause: error);
}
