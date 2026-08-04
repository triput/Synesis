// ==============================================================================
// File: test/mail_navigation_drawer_test.dart
// Description: Widget tests for phone navigation drawer and drawer-mode sidebar
// Component: Test
// Version: 1.2 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/mailbox/mailbox_state.dart';
import 'package:synesis/ui/shell/folder_sidebar.dart';
import 'package:synesis/ui/shell/mail_navigation_drawer.dart';
import 'package:synesis/ui/shell/mail_split_layout.dart';

MailboxState _mailboxState() {
  return MailboxState(
    accounts: const <MailAccount>[
      MailAccount(
        id: 'acc-1',
        label: 'W',
        address: 'work@example.com',
        accent: Color(0xFF2DD4BF),
      ),
    ],
    folders: const <MailFolder>[
      MailFolder(
        id: 'inbox-acc-1',
        accountId: 'acc-1',
        name: 'Inbox',
        remoteId: 'INBOX',
        role: 'inbox',
      ),
    ],
    unified: true,
    expandedAccountIds: const <String>{'acc-1'},
  );
}

MailboxState _multiAccountMailboxState({
  String? accountId,
  String? folderId,
  bool unified = false,
}) {
  return MailboxState(
    accounts: const <MailAccount>[
      MailAccount(
        id: 'acc-1',
        label: 'Work',
        address: 'work@example.com',
        accent: Color(0xFF2DD4BF),
      ),
      MailAccount(
        id: 'acc-2',
        label: 'Home',
        address: 'home@example.com',
        accent: Color(0xFFA78BFA),
      ),
    ],
    folders: const <MailFolder>[
      MailFolder(
        id: 'inbox-acc-1',
        accountId: 'acc-1',
        name: 'Inbox',
        remoteId: 'INBOX',
        role: 'inbox',
      ),
      MailFolder(
        id: 'sent-acc-1',
        accountId: 'acc-1',
        name: 'Sent',
        remoteId: 'SENT',
        role: 'sent',
      ),
      MailFolder(
        id: 'archive-acc-1',
        accountId: 'acc-1',
        name: 'Archive Work',
        remoteId: 'ARCHIVE',
      ),
      MailFolder(
        id: 'inbox-acc-2',
        accountId: 'acc-2',
        name: 'Inbox',
        remoteId: 'INBOX',
        role: 'inbox',
      ),
      MailFolder(
        id: 'sent-acc-2',
        accountId: 'acc-2',
        name: 'Sent',
        remoteId: 'SENT',
        role: 'sent',
      ),
      MailFolder(
        id: 'projects-acc-2',
        accountId: 'acc-2',
        name: 'Projects Home',
        remoteId: 'PROJECTS',
      ),
    ],
    unified: unified,
    accountId: accountId,
    folderId: folderId,
    expandedAccountIds: const <String>{'acc-1', 'acc-2'},
  );
}

Widget _themeWrap(Widget child) {
  final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      extensions: <ThemeExtension<dynamic>>[tokens],
    ),
    home: child,
  );
}

void main() {
  group('FolderSidebar embeddedInDrawer', () {
    testWidgets('hides Hide control and keeps Unified Inbox', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _themeWrap(
          Scaffold(
            body: SizedBox(
              width: 320,
              height: 600,
              child: FolderSidebar(
                state: _mailboxState(),
                settings: const AppSettingsState(),
                embeddedInDrawer: true,
                onHideSidebar: () {},
                onCollapseAll: () {},
                onSelectUnified: () {},
                onSelectVirtualView: (_) {},
                onToggleAccountExpanded: (_) {},
                onSelectAccount: (_) {},
                onSelectFolder: (String a, String f) {},
                onMarkFolderUnread: (String a, String f, bool u) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hide'), findsNothing);
      expect(find.text('Collapse'), findsNothing);
      expect(find.text('MAIL'), findsOneWidget);
      expect(find.text('Unified Inbox'), findsOneWidget);
      expect(find.text('RETENTION DIAL'), findsNothing);
      expect(find.text('FOLDERS'), findsOneWidget);
    });

    testWidgets('opens folder sheet for active account and switches chips', (
      WidgetTester tester,
    ) async {
      String? selectedAccount;
      String? selectedFolderAccount;
      String? selectedFolderId;

      await tester.pumpWidget(
        _themeWrap(
          Scaffold(
            body: SizedBox(
              width: 320,
              height: 700,
              child: FolderSidebar(
                state: _multiAccountMailboxState(
                  accountId: 'acc-1',
                  folderId: 'inbox-acc-1',
                ),
                settings: const AppSettingsState(),
                embeddedInDrawer: true,
                onHideSidebar: () {},
                onCollapseAll: () {},
                onSelectUnified: () {},
                onSelectVirtualView: (_) {},
                onToggleAccountExpanded: (_) {},
                onSelectAccount: (String id) => selectedAccount = id,
                onSelectFolder: (String a, String f) {
                  selectedFolderAccount = a;
                  selectedFolderId = f;
                },
                onMarkFolderUnread: (String a, String f, bool u) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.textContaining('Tap to browse'), findsOneWidget);
      expect(find.text('Archive Work'), findsNothing);
      expect(find.text('Projects Home'), findsNothing);
      expect(find.text('work@example.com'), findsOneWidget);
      expect(find.textContaining('Inbox'), findsWidgets);

      await tester.tap(find.textContaining('Tap to browse'));
      await tester.pumpAndSettle();

      expect(find.text('Folders'), findsOneWidget);
      expect(find.text('Archive Work'), findsOneWidget);
      expect(find.text('Projects Home'), findsNothing);

      await tester.tap(find.text('Sent').first);
      await tester.pumpAndSettle();
      expect(selectedFolderAccount, 'acc-1');
      expect(selectedFolderId, 'sent-acc-1');

      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(selectedAccount, 'acc-2');
    });

    testWidgets('folder launch tile keeps last-active account under Unified', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _themeWrap(
          Scaffold(
            body: SizedBox(
              width: 320,
              height: 700,
              child: FolderSidebar(
                state: _multiAccountMailboxState(
                  accountId: 'acc-2',
                  folderId: 'inbox-acc-2',
                ),
                settings: const AppSettingsState(),
                embeddedInDrawer: true,
                onHideSidebar: () {},
                onCollapseAll: () {},
                onSelectUnified: () {},
                onSelectVirtualView: (_) {},
                onToggleAccountExpanded: (_) {},
                onSelectAccount: (_) {},
                onSelectFolder: (String a, String f) {},
                onMarkFolderUnread: (String a, String f, bool u) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('home@example.com'), findsOneWidget);

      await tester.pumpWidget(
        _themeWrap(
          Scaffold(
            body: SizedBox(
              width: 320,
              height: 700,
              child: FolderSidebar(
                state: _multiAccountMailboxState(unified: true),
                settings: const AppSettingsState(),
                embeddedInDrawer: true,
                onHideSidebar: () {},
                onCollapseAll: () {},
                onSelectUnified: () {},
                onSelectVirtualView: (_) {},
                onToggleAccountExpanded: (_) {},
                onSelectAccount: (_) {},
                onSelectFolder: (String a, String f) {},
                onMarkFolderUnread: (String a, String f, bool u) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('home@example.com'), findsOneWidget);
      expect(find.text('Unified Inbox'), findsOneWidget);

      await tester.tap(find.textContaining('Tap to browse'));
      await tester.pumpAndSettle();
      expect(find.text('Projects Home'), findsOneWidget);
      expect(find.text('Archive Work'), findsNothing);
    });

    testWidgets('desktop mode still shows Hide', (WidgetTester tester) async {
      await tester.pumpWidget(
        _themeWrap(
          Scaffold(
            body: SizedBox(
              width: 280,
              height: 600,
              child: FolderSidebar(
                state: _mailboxState(),
                settings: const AppSettingsState(),
                onHideSidebar: () {},
                onCollapseAll: () {},
                onSelectUnified: () {},
                onSelectVirtualView: (_) {},
                onToggleAccountExpanded: (_) {},
                onSelectAccount: (_) {},
                onSelectFolder: (String a, String f) {},
                onMarkFolderUnread: (String a, String f, bool u) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hide'), findsOneWidget);
      expect(find.text('MAILBOX'), findsOneWidget);
      expect(find.text('FOLDERS'), findsNothing);
    });
  });

  group('MailNavigationDrawer', () {
    testWidgets('selecting Unified Inbox pops drawer and invokes callback', (
      WidgetTester tester,
    ) async {
      bool selectedUnified = false;
      final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        _themeWrap(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              key: scaffoldKey,
              drawer: MailNavigationDrawer(
                state: _mailboxState(),
                settings: const AppSettingsState(),
                onCollapseAll: () {},
                onSelectUnified: () => selectedUnified = true,
                onSelectVirtualView: (_) {},
                onToggleAccountExpanded: (_) {},
                onSelectAccount: (_) {},
                onSelectFolder: (String a, String f) {},
                onMarkFolderUnread: (String a, String f, bool u) {},
                onCompose: () {},
                onOpenOutbox: () {},
                onAddAccount: () {},
                onManageAccounts: () {},
                onOpenSettings: () {},
                onOpenSyncStatus: () {},
              ),
              body: const Center(child: Text('main')),
            ),
          ),
        ),
      );

      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Compose'), findsOneWidget);
      expect(find.text('Outbox'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      await tester.tap(find.text('Unified Inbox'));
      await tester.pumpAndSettle();

      expect(selectedUnified, isTrue);
      expect(find.text('Compose'), findsNothing);
      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('account chip tap closes drawer and selects account', (
      WidgetTester tester,
    ) async {
      String? selectedAccount;
      final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        _themeWrap(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              key: scaffoldKey,
              drawer: MailNavigationDrawer(
                state: _multiAccountMailboxState(
                  accountId: 'acc-1',
                  folderId: 'inbox-acc-1',
                ),
                settings: const AppSettingsState(),
                onCollapseAll: () {},
                onSelectUnified: () {},
                onSelectVirtualView: (_) {},
                onToggleAccountExpanded: (_) {},
                onSelectAccount: (String id) => selectedAccount = id,
                onSelectFolder: (String a, String f) {},
                onMarkFolderUnread: (String a, String f, bool u) {},
                onCompose: () {},
                onOpenOutbox: () {},
                onAddAccount: () {},
                onManageAccounts: () {},
                onOpenSettings: () {},
                onOpenSyncStatus: () {},
              ),
              body: const Center(child: Text('main')),
            ),
          ),
        ),
      );

      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(selectedAccount, 'acc-2');
      expect(find.text('Compose'), findsNothing);
      expect(find.text('main'), findsOneWidget);
    });
  });

  group('resolveFolderPickerAccountId', () {
    test('prefers current accountId over fallback', () {
      final MailboxState state = _multiAccountMailboxState(
        accountId: 'acc-2',
        folderId: 'inbox-acc-2',
      );
      expect(
        resolveFolderPickerAccountId(state, fallbackAccountId: 'acc-1'),
        'acc-2',
      );
    });

    test('uses fallback when unified clears accountId', () {
      final MailboxState state = _multiAccountMailboxState(unified: true);
      expect(
        resolveFolderPickerAccountId(state, fallbackAccountId: 'acc-2'),
        'acc-2',
      );
    });

    test('falls back to first account when nothing else matches', () {
      final MailboxState state = MailboxState(
        accounts: const <MailAccount>[
          MailAccount(
            id: 'acc-1',
            label: 'Work',
            address: 'work@example.com',
            accent: Color(0xFF2DD4BF),
          ),
        ],
        unified: true,
      );
      expect(resolveFolderPickerAccountId(state), 'acc-1');
    });
  });

  group('showDrawerFolderPickerSheet from title-bar style entry', () {
    testWidgets('selecting a folder invokes callback without drawer', (
      WidgetTester tester,
    ) async {
      String? selectedFolderAccount;
      String? selectedFolderId;
      final MailboxState state = _multiAccountMailboxState(
        accountId: 'acc-1',
        folderId: 'inbox-acc-1',
      );

      await tester.pumpWidget(
        _themeWrap(
          Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return TextButton(
                  key: const Key('mail_folder_picker'),
                  onPressed: () {
                    unawaited(
                      showDrawerFolderPickerSheet(
                        context: context,
                        state: state,
                        accountId: resolveFolderPickerAccountId(state)!,
                        onSelectFolder: (String a, String f) {
                          selectedFolderAccount = a;
                          selectedFolderId = f;
                        },
                        onMarkFolderUnread: (String a, String f, bool u) {},
                      ),
                    );
                  },
                  child: const Text('Inbox'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('mail_folder_picker')));
      await tester.pumpAndSettle();
      expect(find.text('Folders'), findsOneWidget);
      expect(find.text('Archive Work'), findsOneWidget);

      await tester.tap(find.text('Sent').first);
      await tester.pumpAndSettle();
      expect(selectedFolderAccount, 'acc-1');
      expect(selectedFolderId, 'sent-acc-1');
      expect(find.text('Folders'), findsNothing);
    });
  });

  group('MailNavigationDrawer overflow (DEF-063)', () {
    testWidgets(
      'drawer with full footer no overflow at short phone height',
      (WidgetTester tester) async {
        final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
        final void Function(FlutterErrorDetails)? oldOnError =
            FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          errors.add(details);
          oldOnError?.call(details);
        };
        addTearDown(() {
          FlutterError.onError = oldOnError;
        });

        final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
        await tester.pumpWidget(
          _themeWrap(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                padding: EdgeInsets.only(top: 24, bottom: 48),
                viewPadding: EdgeInsets.only(top: 24, bottom: 48),
              ),
              child: Scaffold(
                key: scaffoldKey,
                drawer: MailNavigationDrawer(
                  state: _multiAccountMailboxState(
                    accountId: 'acc-1',
                    folderId: 'inbox-acc-1',
                  ),
                  settings: const AppSettingsState(),
                  onCollapseAll: () {},
                  onSelectUnified: () {},
                  onSelectVirtualView: (_) {},
                  onToggleAccountExpanded: (_) {},
                  onSelectAccount: (_) {},
                  onSelectFolder: (String a, String f) {},
                  onMarkFolderUnread: (String a, String f, bool u) {},
                  onCompose: () {},
                  onOpenOutbox: () {},
                  onAddAccount: () {},
                  onManageAccounts: () {},
                  onOpenSettings: () {},
                  onOpenSyncStatus: () {},
                  onOpenNotifications: () {},
                ),
                body: const Center(child: Text('main')),
                bottomNavigationBar: NavigationBar(
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.mail_outline),
                      label: 'Mail',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_today_outlined),
                      label: 'Calendar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      label: 'People',
                    ),
                  ],
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                ),
              ),
            ),
          ),
        );

        scaffoldKey.currentState!.openDrawer();
        await tester.pumpAndSettle();

        expect(find.text('Compose'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Unified Inbox'), findsOneWidget);
        // May need a flick if footer is tall — prove MAIL section scrolls.
        await tester.drag(find.text('Unified Inbox'), const Offset(0, -120));
        await tester.pumpAndSettle();
        expect(find.text('Snoozed'), findsOneWidget);
        final bool overflow = errors.any(
          (FlutterErrorDetails e) =>
              e.toString().contains('overflowed') ||
              e.toString().contains('BOTTOM OVERFLOWED'),
        );
        expect(overflow, isFalse, reason: errors.join('\n'));
      },
    );
  });

  group('isPortraitMobileLayout', () {
    testWidgets('true under 600 width', (WidgetTester tester) async {
      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Builder(
              builder: (BuildContext context) {
                result = isPortraitMobileLayout(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(result, isTrue);
    });
  });
}
