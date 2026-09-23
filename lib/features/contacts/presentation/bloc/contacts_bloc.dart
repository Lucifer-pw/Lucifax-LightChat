import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/usecases/sync_contacts.dart';
import 'contacts_event.dart';
import 'contacts_state.dart';

class ContactsBloc extends Bloc<ContactsEvent, ContactsState> {
  final SyncContacts syncContacts;
  List<ContactEntity> _allContacts = [];

  ContactsBloc({required this.syncContacts}) : super(ContactsInitial()) {
    on<FetchContactsEvent>(_onFetchContacts);
    on<SearchContactsEvent>(_onSearchContacts);
  }

  Future<void> _onFetchContacts(
    FetchContactsEvent event,
    Emitter<ContactsState> emit,
  ) async {
    emit(ContactsLoading());
    final result = await syncContacts();

    result.fold(
      (failure) => emit(ContactsError(failure.message)),
      (contacts) {
        _allContacts = contacts;
        emit(ContactsLoaded(
          allContacts: contacts,
          filteredContacts: contacts,
        ));
      },
    );
  }

  void _onSearchContacts(
    SearchContactsEvent event,
    Emitter<ContactsState> emit,
  ) {
    if (event.query.trim().isEmpty) {
      emit(ContactsLoaded(
        allContacts: _allContacts,
        filteredContacts: _allContacts,
      ));
      return;
    }

    final query = event.query.toLowerCase();
    final filtered = _allContacts.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.phoneNumber.contains(query);
    }).toList();

    emit(ContactsLoaded(
      allContacts: _allContacts,
      filteredContacts: filtered,
    ));
  }
}
