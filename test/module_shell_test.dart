// ==============================================================================
// File: test/module_shell_test.dart
// Description: Module switcher shell tests — Mail default, Calendar/People swap.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synesis/account/account_service.dart';
import 'package:synesis/app.dart';
import 'package:synesis/auth/oauth_identity_manager.dart';
import 'package:synesis/auth/secure_credential_store.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/ui/shell/module_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
    final DriftMailRepository repo = DriftMailRepository(database);
    await repo.seedDemoDataIfEmpty();
    final DriftPimStore pimStore = DriftPimStore(
      database,
      notify: repo.notifyChanges,
    );
    final SyncEngine syncEngine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => null,
    );
    final SecureCredentialStore credentialStore = SecureCredentialStore();
    final OAuthIdentityManager identityManager = OAuthIdentityManager(
      credentialStore,
    );
    final AccountService accountService = AccountService(
      repo,
      credentialStore,
      identityManager,
    );

    addTearDown(database.close);

    final TestFlutterView view = tester.view;
    view.physicalSize = const Size(1400, 900);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SynesisApp(
        prefs: prefs,
        repository: repo,
        syncEngine: syncEngine,
        accountService: accountService,
        identityManager: identityManager,
        resolveProvider: (_) async => null,
        pimStore: pimStore,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Mail is the default module at launch', (tester) async {
    await pumpApp(tester);

    // Mail's own chrome (wordmark + Unified Inbox) is visible by default.
    expect(find.text('synesis'), findsOneWidget);
    expect(find.textContaining('Unified'), findsWidgets);

    // The desktop module rail shows Mail selected; Calendar/People reachable.
    expect(find.byKey(const Key('module_rail')), findsOneWidget);
    expect(find.byKey(Key('module_rail_${AppModule.mail.name}')), findsOneWidget);
    expect(
      find.byKey(Key('module_rail_${AppModule.calendar.name}')),
      findsOneWidget,
    );
    expect(
      find.byKey(Key('module_rail_${AppModule.people.name}')),
      findsOneWidget,
    );
  });

  testWidgets('switching to Calendar and People swaps the body', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(Key('module_rail_${AppModule.calendar.name}')));
    await tester.pumpAndSettle();
    expect(find.text('Calendar'), findsWidgets);
    expect(find.byKey(const Key('calendar_picker_button')), findsOneWidget);

    await tester.tap(find.byKey(Key('module_rail_${AppModule.people.name}')));
    await tester.pumpAndSettle();
    expect(find.text('People'), findsWidgets);
    expect(find.byKey(const Key('people_search_field')), findsOneWidget);

    // Switching back to Mail restores its chrome without a reload flicker
    // (IndexedStack keeps state alive across module switches).
    await tester.tap(find.byKey(Key('module_rail_${AppModule.mail.name}')));
    await tester.pumpAndSettle();
    expect(find.text('synesis'), findsOneWidget);
    expect(find.textContaining('Unified'), findsWidgets);
  });
}
