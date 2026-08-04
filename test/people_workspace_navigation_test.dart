// ==============================================================================
// File: test/people_workspace_navigation_test.dart
// Description: People mobile back-to-contacts navigation (DEF-072)
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/people/people_cubit.dart';
import 'package:synesis/ui/people/people_workspace.dart';

Future<(SynesisDatabase, DriftMailRepository, DriftPimStore)>
_openFixture() async {
  final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
  await database.customSelect('SELECT 1').get();
  final DriftMailRepository repo = DriftMailRepository(database);
  final DriftPimStore pimStore = DriftPimStore(
    database,
    notify: repo.notifyChanges,
  );
  await repo.upsertAccount(
    const MailAccount(
      id: 'work',
      label: 'Work',
      address: 'work@byte.io',
      accent: Color(0xFF2DD4BF),
    ),
    providerType: 'imap',
  );
  return (database, repo, pimStore);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Back to contacts returns to list on phone width (DEF-072)', (
    WidgetTester tester,
  ) async {
    final (
      SynesisDatabase database,
      DriftMailRepository repo,
      DriftPimStore pimStore,
    ) = await _openFixture();
    addTearDown(database.close);

    final String listId = DriftPimStore.stableLocalId('work', 'contacts');
    final String contactId = DriftPimStore.stableLocalId('work', 'c1');
    await pimStore.upsertContactLists(<ContactList>[
      ContactList(
        id: listId,
        accountId: 'work',
        providerId: 'contacts',
        name: 'Contacts',
        isSelectedForDisplay: true,
      ),
    ]);
    await pimStore.upsertContacts(<Contact>[
      Contact(
        id: contactId,
        accountId: 'work',
        contactListId: listId,
        providerId: 'c1',
        displayName: 'Ada Lovelace',
        updatedAt: 1,
      ),
    ]);

    final PeopleCubit cubit = PeopleCubit(
      pimStore: pimStore,
      repository: repo,
    );
    addTearDown(cubit.close);
    await cubit.refresh();

    final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: tokens.brightness,
          extensions: <ThemeExtension<dynamic>>[tokens],
        ),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 640)),
          child: BlocProvider<PeopleCubit>.value(
            value: cubit,
            child: const PeopleWorkspace(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ada Lovelace'), findsOneWidget);
    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('people_back_to_contacts')), findsOneWidget);
    expect(find.byKey(const Key('people_contact_detail')), findsOneWidget);
    expect(cubit.state.selectedContactId, contactId);

    await tester.tap(find.byKey(const Key('people_back_to_contacts')));
    await tester.pumpAndSettle();

    expect(cubit.state.selectedContactId, isNull);
    expect(find.byKey(const Key('people_back_to_contacts')), findsNothing);
    expect(find.byKey(const Key('people_contact_detail')), findsNothing);
    expect(find.byKey(const Key('people_contact_list')), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  test('selectContact(null) clears selection even after detail load', () async {
    final (
      SynesisDatabase database,
      DriftMailRepository repo,
      DriftPimStore pimStore,
    ) = await _openFixture();
    addTearDown(database.close);

    final String listId = DriftPimStore.stableLocalId('work', 'contacts');
    final String contactId = DriftPimStore.stableLocalId('work', 'c1');
    await pimStore.upsertContactLists(<ContactList>[
      ContactList(
        id: listId,
        accountId: 'work',
        providerId: 'contacts',
        name: 'Contacts',
        isSelectedForDisplay: true,
      ),
    ]);
    await pimStore.upsertContacts(<Contact>[
      Contact(
        id: contactId,
        accountId: 'work',
        contactListId: listId,
        providerId: 'c1',
        displayName: 'Ada Lovelace',
        updatedAt: 1,
      ),
    ]);
    await pimStore.upsertContactEmails(<ContactEmail>[
      ContactEmail(
        id: DriftPimStore.stableLocalId('work', 'e1'),
        contactId: contactId,
        address: 'ada@byte.io',
        isPrimary: true,
      ),
    ]);

    final PeopleCubit cubit = PeopleCubit(
      pimStore: pimStore,
      repository: repo,
    );
    addTearDown(cubit.close);
    await cubit.refresh();
    await cubit.selectContact(contactId);
    expect(cubit.state.selectedContactId, contactId);
    expect(cubit.state.selectedEmails, isNotEmpty);

    await cubit.selectContact(null);
    expect(cubit.state.selectedContactId, isNull);
    expect(cubit.state.selectedEmails, isEmpty);
  });
}
