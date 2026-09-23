import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/phone_number_formatter.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/domain/usecases/create_or_get_chat.dart';
import '../bloc/contacts_bloc.dart';
import '../bloc/contacts_event.dart';
import '../bloc/contacts_state.dart';
import '../../domain/usecases/find_user_by_phone.dart';

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

    if (!mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
      ),
      (chat) {
        context.pushReplacement('/chat/${chat.chatId}', extra: chat);
      },
    );
  }

  Future<void> _openNewContact() async {
    try {
      await FlutterContacts.openExternalInsert();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open contact editor')),
      );
    }
  }

  Future<void> _showDirectChatDialog() async {
    final phoneController = TextEditingController();
    bool isSearching = false;
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Chat by Phone Number', style: AppTextStyles.heading3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the phone number of the person you want to chat with:',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'e.g. 081234567890 or +628...',
                    prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                    errorText: errorMessage,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: isSearching
                    ? null
                    : () async {
                        final rawPhone = phoneController.text.trim();
                        final normalized = PhoneNumberFormatter.toE164(rawPhone);

                        if (!PhoneNumberFormatter.isValid(normalized)) {
                          setDialogState(() {
                            errorMessage = 'Invalid phone number format';
                          });
                          return;
                        }

                        final authState = context.read<AuthBloc>().state;
                        if (authState is AuthenticatedState && authState.user.phoneNumber == normalized) {
                          setDialogState(() {
                            errorMessage = 'Cannot start a chat with yourself';
                          });
                          return;
                        }

                        setDialogState(() {
                          isSearching = true;
                          errorMessage = null;
                        });

                        final findUser = getIt<FindUserByPhone>();
                        final result = await findUser(normalized);

                        if (!dialogContext.mounted) return;

                        result.fold(
                          (failure) {
                            setDialogState(() {
                              isSearching = false;
                              errorMessage = failure.message;
                            });
                          },
                          (contact) {
                            if (contact == null) {
                              setDialogState(() {
                                isSearching = false;
                                errorMessage = 'No user registered with this phone number';
                              });
                            } else {
                              Navigator.pop(dialogContext);
                              _startChatWithContact(
                                contact.registeredUid ?? contact.id,
                                contact.name,
                                contact.photoUrl,
                              );
                            }
                          },
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSearching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Start Chat', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
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
            return ListView(
              children: [
                // Quick Action: New Group
                if (!_isSearching) ...[
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 20,
                      child: Icon(Icons.group_add_rounded, color: Colors.white, size: 20),
                    ),
                    title: const Text('New group', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => context.push('/create-group'),
                  ),
                  // Quick Action: New Contact
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 20,
                      child: Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                    ),
                    title: const Text('New contact', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: _openNewContact,
                  ),
                  // Quick Action: Direct Chat by Phone
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary.withOpacity(0.85),
                      radius: 20,
                      child: const Icon(Icons.phone_forwarded_rounded, color: Colors.white, size: 20),
                    ),
                    title: const Text('Chat by phone number', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Message someone without saving contact', style: TextStyle(fontSize: 12)),
                    onTap: _showDirectChatDialog,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Contacts on LightChat',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],

                if (state.filteredContacts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No contacts found on LightChat',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...state.filteredContacts.map((contact) {
                    return ListTile(
                      leading: CustomAvatar(
                        imageUrl: contact.photoUrl,
                        name: contact.name,
                        radius: 22,
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
                  }),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
