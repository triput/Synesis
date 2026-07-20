// ==============================================================================
// File: test/saved_message_filter_test.dart
// Description: Saved filter domain JSON and AppSettingsCubit persistence cap.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/domain/saved_message_filter.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SavedMessageFilter JSON', () {
    test('round-trips filter including recipientContains', () {
      const SavedMessageFilter original = SavedMessageFilter(
        id: 'f1',
        name: 'Invoices',
        filter: MessageViewFilter(
          unread: true,
          recipientContains: 'finance@',
          keyword: 'invoice',
        ),
        createdAt: 100,
        updatedAt: 200,
      );

      final SavedMessageFilter decoded = SavedMessageFilter.fromJson(
        original.toJson(),
      );
      expect(decoded, original);
    });
  });

  group('AppSettingsCubit saved filters', () {
    test('save, rename, delete, and enforce soft cap', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      expect(cubit.state.savedFilters, isEmpty);

      final bool saved = await cubit.saveSavedFilter(
        'Unread finance',
        const MessageViewFilter(unread: true, recipientContains: 'finance@'),
      );
      expect(saved, isTrue);
      expect(cubit.state.savedFilters, hasLength(1));
      expect(cubit.state.savedFilters.first.name, 'Unread finance');

      await cubit.renameSavedFilter(
        cubit.state.savedFilters.first.id,
        'Finance unread',
      );
      expect(cubit.state.savedFilters.first.name, 'Finance unread');

      for (int i = cubit.state.savedFilters.length;
          i < kMaxSavedMessageFilters;
          i++) {
        await cubit.saveSavedFilter('Filter $i', const MessageViewFilter());
      }
      expect(cubit.state.savedFilters.length, kMaxSavedMessageFilters);

      final bool capped = await cubit.saveSavedFilter(
        'One too many',
        const MessageViewFilter(unread: true),
      );
      expect(capped, isFalse);
      expect(cubit.state.savedFilters.length, kMaxSavedMessageFilters);

      final SavedMessageFilter keepFilter = cubit.state.savedFilters.firstWhere(
        (SavedMessageFilter filter) => filter.name == 'Finance unread',
      );
      final SavedMessageFilter deleteTarget = cubit.state.savedFilters.firstWhere(
        (SavedMessageFilter filter) => filter.id != keepFilter.id,
      );
      await cubit.deleteSavedFilter(deleteTarget.id);
      expect(
        cubit.state.savedFilters.any(
          (SavedMessageFilter filter) => filter.id == keepFilter.id,
        ),
        isTrue,
      );

      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.savedFilters.length, kMaxSavedMessageFilters - 1);
      expect(
        reloaded.state.savedFilters.any(
          (SavedMessageFilter filter) => filter.name == 'Finance unread',
        ),
        isTrue,
      );
      await reloaded.close();
    });

    test('replaceSavedFilters caps list length', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      final List<SavedMessageFilter> many = List<SavedMessageFilter>.generate(
        kMaxSavedMessageFilters + 5,
        (int index) => SavedMessageFilter(
          id: 'id-$index',
          name: 'Name $index',
          filter: const MessageViewFilter(),
          createdAt: index,
          updatedAt: index,
        ),
      );
      await cubit.replaceSavedFilters(many);
      expect(cubit.state.savedFilters.length, kMaxSavedMessageFilters);
      await cubit.close();
    });
  });
}
