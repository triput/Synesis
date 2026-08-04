// ==============================================================================
// File: lib/ui/people/people_state.dart
// Description: People workspace state — contact lists, contacts, search, detail.
// Component: Bloc / UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-04
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';

class PeopleState extends Equatable {
  const PeopleState({
    this.accounts = const <MailAccount>[],
    this.contactLists = const <ContactList>[],
    this.contacts = const <Contact>[],
    this.searchQuery = '',
    this.searchResults = const <ContactSearchHit>[],
    this.selectedContactId,
    this.selectedEmails = const <ContactEmail>[],
    this.selectedPhones = const <ContactPhone>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<MailAccount> accounts;
  final List<ContactList> contactLists;

  /// Contacts belonging to lists with [ContactList.isSelectedForDisplay].
  final List<Contact> contacts;

  final String searchQuery;

  /// Local FTS results for [searchQuery], scoped to selected lists.
  final List<ContactSearchHit> searchResults;

  final String? selectedContactId;
  final List<ContactEmail> selectedEmails;
  final List<ContactPhone> selectedPhones;
  final bool isLoading;
  final String? errorMessage;

  bool get isSearching => searchQuery.trim().isNotEmpty;

  /// Rows to render: search results while searching, else the full
  /// selected-lists contact list.
  List<Contact> get visibleContacts =>
      isSearching
          ? searchResults
                .map((ContactSearchHit hit) => hit.contact)
                .toList(growable: false)
          : contacts;

  Contact? get selectedContact {
    final String? id = selectedContactId;
    if (id == null) {
      return null;
    }
    for (final Contact contact in visibleContacts) {
      if (contact.id == id) {
        return contact;
      }
    }
    for (final Contact contact in contacts) {
      if (contact.id == id) {
        return contact;
      }
    }
    return null;
  }

  PeopleState copyWith({
    List<MailAccount>? accounts,
    List<ContactList>? contactLists,
    List<Contact>? contacts,
    String? searchQuery,
    List<ContactSearchHit>? searchResults,
    String? selectedContactId,
    bool clearSelectedContactId = false,
    List<ContactEmail>? selectedEmails,
    List<ContactPhone>? selectedPhones,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PeopleState(
      accounts: accounts ?? this.accounts,
      contactLists: contactLists ?? this.contactLists,
      contacts: contacts ?? this.contacts,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      selectedContactId: clearSelectedContactId
          ? null
          : (selectedContactId ?? this.selectedContactId),
      selectedEmails: selectedEmails ?? this.selectedEmails,
      selectedPhones: selectedPhones ?? this.selectedPhones,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    accounts,
    contactLists,
    contacts,
    searchQuery,
    searchResults,
    selectedContactId,
    selectedEmails,
    selectedPhones,
    isLoading,
    errorMessage,
  ];
}
