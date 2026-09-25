import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/phone_number_formatter.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  UserEntity? _cachedUser;

  final List<String> _presetBios = [
    "Hey! I'm using LightChat",
    '⚡ Available',
    '🎵 Listening to Music',
    '💻 At work / Coding',
    '☕ Coffee break',
    '🌙 Sleeping',
    '🔕 Busy',
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _cachedUser = authState.user;
    } else {
      context.read<AuthBloc>().add(CheckAuthStatusEvent());
    }
  }

  // ----------------------------------------------------
  // CRUD Methods
  // ----------------------------------------------------

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted && _cachedUser != null) {
        setState(() => _isSaving = true);
        context.read<AuthBloc>().add(
              SaveProfileEvent(
                displayName: _cachedUser!.displayName,
                bio: _cachedUser!.bio,
                imageFile: File(pickedFile.path),
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAvatarOptions(String? currentPhotoUrl, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Foto Profil', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Kamera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Galeri', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty) ...[
                ListTile(
                  leading: const Icon(Icons.fullscreen_rounded, color: Colors.blueAccent),
                  title: const Text('Lihat Foto Penuh', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showFullScreenAvatar(currentPhotoUrl, name);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenAvatar(String photoUrl, String name) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r16),
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                loadingBuilder: (c, child, progress) =>
                    progress == null ? child : const CircularProgressIndicator(color: AppColors.primary),
                errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Text(name, style: AppTextStyles.heading2),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(String currentName, String currentBio) {
    final controller = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSizes.p20,
          right: AppSizes.p20,
          top: AppSizes.p20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan Nama Anda', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Ini bukan nama pengguna atau PIN. Nama ini akan terlihat oleh kontak Anda.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: 30,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                  onPressed: () => controller.clear(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final newName = controller.text.trim();
                    if (newName.isNotEmpty) {
                      Navigator.pop(ctx);
                      setState(() => _isSaving = true);
                      context.read<AuthBloc>().add(
                            SaveProfileEvent(
                              displayName: newName,
                              bio: currentBio,
                            ),
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBioDialog(String currentName, String currentBio) {
    final controller = TextEditingController(text: currentBio);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSizes.p20,
            right: AppSizes.p20,
            top: AppSizes.p20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ubah Status / Info', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLength: 80,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Tulis status Anda...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('PILIH STATUS CEPAT', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _presetBios.map((preset) {
                  final isSelected = controller.text == preset;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppSizes.rFull),
                    onTap: () {
                      setModalState(() {
                        controller.text = preset;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppSizes.rFull),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        preset,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final newBio = controller.text.trim();
                      if (newBio.isNotEmpty) {
                        Navigator.pop(ctx);
                        setState(() => _isSaving = true);
                        context.read<AuthBloc>().add(
                              SaveProfileEvent(
                                displayName: currentName,
                                bio: newBio,
                              ),
                            );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r16)),
        title: const Text('Log out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out from LightChat?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(SignOutEvent());
              context.go('/welcome');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Main UI
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState) {
          setState(() {
            _cachedUser = state.user;
            _isSaving = false;
          });
        } else if (state is AuthErrorState) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, authState) {
        if (authState is AuthenticatedState) {
          _cachedUser = authState.user;
        }

        if (_cachedUser == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final user = _cachedUser!;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Profile'),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Top Cover Banner + Avatar
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryDark,
                            AppColors.surfaceLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -45,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CustomAvatar(
                            imageUrl: user.photoUrl,
                            name: user.displayName,
                            radius: 48,
                            onTap: () => _showAvatarOptions(user.photoUrl, user.displayName),
                          ),
                          // Camera Edit Badge
                          Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _showAvatarOptions(user.photoUrl, user.displayName),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 55),

                // Saving Indicator
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),

                // Display Name (tap to edit)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showEditNameDialog(user.displayName, user.bio),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.displayName,
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                ),
                AppSizes.vSpace4,

                // Phone Number (tap to copy)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: user.phoneNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nomor disalin ke clipboard 📋'), duration: Duration(seconds: 2)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Text(
                      PhoneNumberFormatter.toDisplay(user.phoneNumber),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                AppSizes.vSpace24,

                // 1. About / Bio Tile (tap to edit)
                const Divider(color: AppColors.divider, height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.iconColor),
                  title: const Text('About', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  subtitle: Text(user.bio, style: AppTextStyles.bodyMedium),
                  trailing: const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 18),
                  onTap: () => _showEditBioDialog(user.displayName, user.bio),
                ),

                // 2. Phone Tile
                const Divider(color: AppColors.divider, height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_rounded, color: AppColors.iconColor),
                  title: const Text('Phone', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  subtitle: Text(PhoneNumberFormatter.toDisplay(user.phoneNumber), style: AppTextStyles.bodyMedium),
                  trailing: const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 16),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: user.phoneNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nomor disalin ke clipboard 📋'), duration: Duration(seconds: 2)),
                    );
                  },
                ),

                // 3. Appearance & Theme Tile
                const Divider(color: AppColors.divider, height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: AppColors.iconColor),
                  title: const Text('Appearance & Theme', style: TextStyle(color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => context.push('/appearance-settings'),
                ),

                // 4. LightChatWeb / Linked Devices Tile
                const Divider(color: AppColors.divider, height: 1),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.iconColor),
                  title: const Text('LightChatWeb / Linked Devices', style: TextStyle(color: AppColors.textPrimary)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => context.push('/qr-scanner'),
                ),
                const Divider(color: AppColors.divider, height: 1),

                AppSizes.vSpace24,

                // Logout Button (Classic Red Outline)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text('LOG OUT', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                ),
                AppSizes.vSpace32,
              ],
            ),
          ),
        );
      },
    );
  }
}
