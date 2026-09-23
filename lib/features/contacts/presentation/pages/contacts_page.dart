import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/domain/usecases/create_or_get_chat.dart';
import '../bloc/contacts_bloc.dart';
import '../bloc/contacts_event.dart';
import '../bloc/contacts_state.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  late ContactsBloc _contactsBloc;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _contactsBloc = getIt<ContactsBloc>();
    _requestPermissionAndFetch();
  }

  Future<void> _requestPermissionAndFetch() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (granted) {
      _contactsBloc.add(FetchContactsEvent());
    } else {
      // Permission denied — bloc will show error state when it tries
      _contactsBloc.add(FetchContactsEvent());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contactsBloc.close();
    super.dispose();
  }

  Future<void> _startChatWithContact(String otherUserId, String otherUserName, String? otherUserPhoto) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return;

    final createOrGetChat = getIt<CreateOrGetPrivateChat>();
    final result = await createOrGetChat(
      currentUserId: authState.user.uid,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserPhoto: otherUserPhoto,
    );

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
      ),
      (chat) {
        context.pushReplacement('/chat/${chat.chatId}', extra: chat);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Search contacts...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onChanged: (val) => _contactsBloc.add(SearchContactsEvent(val)),
              )
            : const Text('Select contact'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _contactsBloc.add(const SearchContactsEvent(''));
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _contactsBloc.add(FetchContactsEvent()),
          ),
        ],
      ),
      body: BlocBuilder<ContactsBloc, ContactsState>(
        bloc: _contactsBloc,
        builder: (context, state) {
          if (state is ContactsLoading) {
            return const LoadingIndicator(message: 'Scanning & matching contacts...');
          } else if (state is ContactsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.contacts_rounded, size: 64, color: AppColors.textMuted),
                    AppSizes.vSpace16,
                    Text(
                      state.message,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                    AppSizes.vSpace16,
                    ElevatedButton(
                      onPressed: () => _contactsBloc.add(FetchContactsEvent()),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('RETRY', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is ContactsLoaded) {
            if (state.filteredContacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_search_rounded, size: 64, color: AppColors.textMuted),
                    AppSizes.vSpace16,
                    Text(
                      'No contacts found on LightChat',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: state.filteredContacts.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppColors.divider,
                indent: 80,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final contact = state.filteredContacts[index];
                return ListTile(
                  leading: CustomAvatar(
                    imageUrl: contact.photoUrl,
                    name: contact.name,
                    radius: 24,
                  ),
                  title: Text(contact.name, style: AppTextStyles.chatTitle),
                  subtitle: Text(
                    contact.bio ?? contact.phoneNumber,
                    style: AppTextStyles.chatSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    if (contact.registeredUid != null) {
                      _startChatWithContact(
                        contact.registeredUid!,
                        contact.name,
                        contact.photoUrl,
                      );
                    }
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
