// ==============================================================================
// File: lib/ui/people/people_cubit.dart
// Description: People workspace Cubit — local contact lists, search, detail.
// Component: Bloc / UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-04
// ==============================================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/pim_copy_service.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/ui/people/people_state.dart';

/// Owns the People workspace's contact-list display prefs, local FTS search,
/// and contact detail lookups (Wave 5 / V2.0c).
///
/// Read-only for remote-sourced contacts in this wave — there is no
/// CardDAV/Graph PUT path; the only writes are local display-preference
/// toggles via [setContactListSelected]. Refreshes on
/// [MailRepository.watchChanges] (shared with the mail + PIM change stream).
class PeopleCubit extends Cubit<PeopleState> {
  PeopleCubit({
    required DriftPimStore pimStore,
    required MailRepository repository,
    PimCopyService? copyService,
    SyncEngine? syncEngine,
  }) : _pimStore = pimStore,
       _repository = repository,
       _copyService = copyService,
       _syncEngine = syncEngine,
       super(const PeopleState()) {
    _changesSub = _repository.watchChanges().listen((_) => refresh());
    unawaited(refresh());
  }

  final DriftPimStore _pimStore;
  final MailRepository _repository;
  final PimCopyService? _copyService;
  final SyncEngine? _syncEngine;
  StreamSubscription<void>? _changesSub;
  Timer? _searchDebounce;
  int _selectionEpoch = 0;

  Future<void> refresh() async {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final List<MailAccount> accounts = await _repository.listAccounts();
      final List<ContactList> lists = await _pimStore.listContactLists();
      final List<Contact> contacts = await _pimStore
          .listContactsForSelectedLists();
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          accounts: accounts,
          contactLists: lists,
          contacts: contacts,
          isLoading: false,
        ),
      );
      final String query = state.searchQuery;
      if (query.trim().isNotEmpty) {
        unawaited(_runSearch(query));
      }
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  /// Debounced local FTS search scoped to selected contact lists.
  void setSearchQuery(String query) {
    if (state.searchQuery == query) {
      return;
    }
    emit(state.copyWith(searchQuery: query));
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      emit(state.copyWith(searchResults: const <ContactSearchHit>[]));
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_runSearch(query));
    });
  }

  Future<void> _runSearch(String query) async {
    final List<ContactSearchHit> hits = await _pimStore.searchContacts(
      query,
      selectedListsOnly: true,
    );
    if (isClosed || state.searchQuery != query) {
      return;
    }
    emit(state.copyWith(searchResults: hits));
  }

  /// Toggles [ContactList.isSelectedForDisplay], then refreshes so picker
  /// sheets listening via BlocBuilder update immediately (DEF-060).
  Future<void> setContactListSelected(String listId, bool selected) async {
    await _pimStore.setContactListDisplayPrefs(
      listId,
      isSelectedForDisplay: selected,
    );
    await refresh();
  }

  /// Selects a contact for the detail pane and loads its emails/phones.
  /// Pass `null` to clear the detail pane.
  Future<void> selectContact(String? contactId) async {
    final int epoch = ++_selectionEpoch;
    if (contactId == null) {
      if (state.selectedContactId == null &&
          state.selectedEmails.isEmpty &&
          state.selectedPhones.isEmpty) {
        return;
      }
      emit(
        state.copyWith(
          clearSelectedContactId: true,
          selectedEmails: const <ContactEmail>[],
          selectedPhones: const <ContactPhone>[],
        ),
      );
      return;
    }
    emit(state.copyWith(selectedContactId: contactId));
    final List<ContactEmail> emails = await _pimStore.listContactEmails(
      contactId,
    );
    final List<ContactPhone> phones = await _pimStore.listContactPhones(
      contactId,
    );
    if (isClosed || epoch != _selectionEpoch) {
      return;
    }
    emit(state.copyWith(selectedEmails: emails, selectedPhones: phones));
  }

  /// Local-first duplicate of [sourceContactId] onto [targetContactListId]
  /// (Wave 6 / 6b). Enqueues `contacts_copy` for Graph/Google/DAV targets.
  Future<PimCopyResult<Contact>> copyContactToList({
    required String sourceContactId,
    required String targetAccountId,
    required String targetContactListId,
  }) async {
    final PimCopyService? copyService = _copyService;
    if (copyService == null) {
      throw StateError('PeopleCubit.copyContactToList: PimCopyService '
          'not configured.');
    }
    final PimCopyResult<Contact> result = await copyService.copyContactToList(
      sourceContactId: sourceContactId,
      targetAccountId: targetAccountId,
      targetContactListId: targetContactListId,
    );
    if (result.remotePushEnqueued) {
      unawaited(_syncEngine?.kick());
    }
    await refresh();
    return result;
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    unawaited(_changesSub?.cancel());
    return super.close();
  }
}
