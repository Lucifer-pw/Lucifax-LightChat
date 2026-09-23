import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../contacts/domain/entities/contact_entity.dart';
import '../../../contacts/presentation/bloc/contacts_bloc.dart';
import '../../../contacts/presentation/bloc/contacts_event.dart';
import '../../../contacts/presentation/bloc/contacts_state.dart';
import '../../domain/usecases/create_group_chat.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<ContactEntity> _selectedContacts = {};
  late ContactsBloc _contactsBloc;
  String? _groupImagePath;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _contactsBloc = getIt<ContactsBloc>()..add(FetchContactsEvent());
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _contactsBloc.close();
    super.dispose();
  }

  Future<void> _pickGroupImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _groupImagePath = image.path);
    }
  }

  Future<void> _handleCreateGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact'), backgroundColor: AppColors.error),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return;

    setState(() => _isCreating = true);

    final createGroupChat = getIt<CreateGroupChat>();
    final participantIds = _selectedContacts
        .map((c) => c.registeredUid ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final result = await createGroupChat(
      name: groupName,
      currentUserId: authState.user.uid,
      participantIds: participantIds,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
        );
      },
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Group', style: TextStyle(fontSize: 18)),
            Text(
              '${_selectedContacts.length} selected',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (_isCreating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: AppColors.primary),
              onPressed: _handleCreateGroup,
            ),
        ],
      ),
      body: Column(
        children: [
          // Group Details Header
          Container(
            padding: const EdgeInsets.all(AppSizes.p16),
            color: AppColors.surface,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickGroupImage,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: _groupImagePath != null ? FileImage(File(_groupImagePath!)) : null,
                    child: _groupImagePath == null
                        ? const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 28)
                        : null,
                  ),
                ),
                AppSizes.hSpace16,
                Expanded(
                  child: TextField(
                    controller: _groupNameController,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'Type group subject here...',
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected Contacts Chips
          if (_selectedContacts.isNotEmpty)
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppColors.surface,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedContacts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final contact = _selectedContacts.elementAt(index);
                  return Stack(
                    children: [
                      Column(
                        children: [
                          CustomAvatar(
                            imageUrl: contact.photoUrl,
                            name: contact.name,
                            radius: 20,
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 50,
                            child: Text(
                              contact.name,
                              style: AppTextStyles.caption.copyWith(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedContacts.remove(contact)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const Divider(height: 1, color: AppColors.divider),

          // Contact Selection List
          Expanded(
            child: BlocBuilder<ContactsBloc, ContactsState>(
              bloc: _contactsBloc,
              builder: (context, state) {
                if (state is ContactsLoading) {
                  return const LoadingIndicator(message: 'Loading contacts...');
                } else if (state is ContactsError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: AppColors.error)));
                } else if (state is ContactsLoaded) {
                  if (state.filteredContacts.isEmpty) {
                    return Center(
                      child: Text(
                        'No contacts found on LightChat',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
                      final isSelected = _selectedContacts.contains(contact);

                      return ListTile(
                        leading: Stack(
                          children: [
                            CustomAvatar(
                              imageUrl: contact.photoUrl,
                              name: contact.name,
                              radius: 22,
                            ),
                            if (isSelected)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        title: Text(contact.name, style: AppTextStyles.chatTitle),
                        subtitle: Text(
                          contact.bio ?? contact.phoneNumber,
                          style: AppTextStyles.chatSubtitle,
                          maxLines: 1,
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedContacts.add(contact);
                              } else {
                                _selectedContacts.remove(contact);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedContacts.remove(contact);
                            } else {
                              _selectedContacts.add(contact);
                            }
                          });
                        },
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateGroup,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
      ),
    );
  }
}
