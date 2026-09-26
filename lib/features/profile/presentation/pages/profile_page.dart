import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../app_update/domain/usecases/check_for_update.dart';
import '../../../app_update/presentation/widgets/update_dialog.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'avatar_cropper_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  UserEntity? _cachedUser;

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
  // Image & Profile Methods
  // ----------------------------------------------------

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile != null && mounted) {
        final croppedFile = await Navigator.push<File?>(
          context,
          MaterialPageRoute(
            builder: (_) => AvatarCropperPage(imageFile: File(pickedFile.path)),
          ),
        );

        if (croppedFile != null && mounted && _cachedUser != null) {
          setState(() => _isSaving = true);
          context.read<AuthBloc>().add(
                SaveProfileEvent(
                  displayName: _cachedUser!.displayName,
                  bio: _cachedUser!.bio,
                  imageFile: croppedFile,
                ),
              );
        }
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
      backgroundColor: const Color(0xFF1F2C34),
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

  Widget _buildFullScreenImage(String photoUrl) {
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64Str = photoUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {
        return const Icon(Icons.broken_image_rounded, size: 80, color: Colors.grey);
      }
    }
    return Image.network(
      photoUrl,
      fit: BoxFit.contain,
      loadingBuilder: (c, child, progress) =>
          progress == null ? child : const CircularProgressIndicator(color: AppColors.primary),
      errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, size: 80, color: Colors.grey),
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
              child: _buildFullScreenImage(photoUrl),
            ),
            const SizedBox(height: 12),
            Text(name, style: AppTextStyles.heading2),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(String currentName, String currentBio) {
    final nameCtrl = TextEditingController(text: currentName);
    final bioCtrl = TextEditingController(text: currentBio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2C34),
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
            Text('Edit Profil', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              maxLength: 30,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Nama',
                labelStyle: const TextStyle(color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLength: 80,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Info / Status',
                labelStyle: const TextStyle(color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
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
                    final newName = nameCtrl.text.trim();
                    final newBio = bioCtrl.text.trim();
                    if (newName.isNotEmpty) {
                      Navigator.pop(ctx);
                      setState(() => _isSaving = true);
                      context.read<AuthBloc>().add(
                            SaveProfileEvent(
                              displayName: newName,
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
    );
  }

  Future<void> _checkAppUpdate() async {
    try {
      final checkUpdate = getIt<CheckForUpdate>();
      final result = await checkUpdate();

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
          );
        },
        (updateInfo) {
          if (updateInfo.hasUpdate) {
            UpdateDialog.show(context, updateInfo);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Anda menggunakan versi terbaru (v${updateInfo.currentVersion}) 👍'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
      );
    } catch (_) {}
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r16)),
        title: const Text('Keluar dari LightChat?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
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
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFeatureInfo(String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(description, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

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
          return const Scaffold(
            backgroundColor: Color(0xFF0C161C),
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final user = _cachedUser!;

        return Scaffold(
          backgroundColor: const Color(0xFF0C161C),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0C161C),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
                onPressed: () => context.push('/qr-scanner'),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => _showEditProfileDialog(user.displayName, user.bio),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Top Profile Banner: Speech Bubble + Avatar + Name
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      // Speech bubble
                      GestureDetector(
                        onTap: () => _showEditProfileDialog(user.displayName, user.bio),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2C34),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.bio.isNotEmpty ? user.bio : 'Ada kabar apa?',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Avatar
                      GestureDetector(
                        onTap: () => _showAvatarOptions(user.photoUrl, user.displayName),
                        child: CustomAvatar(
                          imageUrl: user.photoUrl,
                          name: user.displayName,
                          radius: 54,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Name + Chevron
                      GestureDetector(
                        onTap: () => _showEditProfileDialog(user.displayName, user.bio),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 24),
                          ],
                        ),
                      ),
                      if (_isSaving)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 1. Langganan (with green dot)
                _buildSettingsTile(
                  icon: Icons.diamond_outlined,
                  title: 'Langganan',
                  subtitle: 'Jelajahi keuntungan premium',
                  hasGreenDot: true,
                  onTap: () => _showFeatureInfo('Langganan Premium', 'Nikmati fitur panggilan tanpa batas, stiker eksklusif, dan sinkronisasi cloud.'),
                ),

                // 2. Perangkat tertaut
                _buildSettingsTile(
                  icon: Icons.devices_rounded,
                  title: 'Perangkat tertaut',
                  subtitle: 'Gunakan WhatsApp di perangkat lain',
                  onTap: () => context.push('/qr-scanner'),
                ),

                // 3. Akun
                _buildSettingsTile(
                  icon: Icons.key_rounded,
                  title: 'Akun',
                  subtitle: 'Notifikasi keamanan, ganti nomor',
                  onTap: () => _showAccountDialog(user),
                ),

                // 4. Privasi
                _buildSettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privasi',
                  subtitle: 'Akun diblokir, pesan sementara',
                  onTap: () => _showFeatureInfo('Privasi', 'Pengaturan privasi foto profil, status online, dan pesan sementara.'),
                ),

                // 5. Daftar
                _buildSettingsTile(
                  icon: Icons.contacts_outlined,
                  title: 'Daftar',
                  subtitle: 'Kelola orang dan grup',
                  onTap: () => context.push('/contacts'),
                ),

                // 6. Chat
                _buildSettingsTile(
                  icon: Icons.chat_outlined,
                  title: 'Chat',
                  subtitle: 'Riwayat obrolan, cadangan',
                  onTap: () => context.push('/appearance-settings'),
                ),

                // 7. Tampilan
                _buildSettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Tampilan',
                  subtitle: 'Tema obrolan, ikon aplikasi, tema aplikasi',
                  onTap: () => context.push('/appearance-settings'),
                ),

                // 8. Siaran
                _buildSettingsTile(
                  icon: Icons.campaign_outlined,
                  title: 'Siaran',
                  subtitle: 'Kelola daftar dan kirim siaran',
                  onTap: () => _showFeatureInfo('Daftar Siaran', 'Kirim satu pesan ke banyak kontak sekaligus secara privat.'),
                ),

                // 9. Notifikasi
                _buildSettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifikasi',
                  subtitle: 'Pesan, grup & nada dering panggilan',
                  onTap: () => _showFeatureInfo('Notifikasi', 'Pengaturan nada dering, getar, dan pratinjau pesan.'),
                ),

                // 10. Penyimpanan dan data
                _buildSettingsTile(
                  icon: Icons.data_usage_rounded,
                  title: 'Penyimpanan dan data',
                  subtitle: 'Penggunaan jaringan, unduh otomatis',
                  onTap: () => _showFeatureInfo('Penyimpanan & Data', 'Kelola memori aplikasi dan pengaturan unduh otomatis media.'),
                ),

                // 11. Kontrol orang tua
                _buildSettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Kontrol orang tua',
                  subtitle: 'Pengaturan untuk keluarga Anda',
                  onTap: () => _showFeatureInfo('Kontrol Orang Tua', 'Panduan dan fitur keamanan keluarga pada LightChat.'),
                ),

                // 12. Aksesibilitas
                _buildSettingsTile(
                  icon: Icons.accessibility_new_rounded,
                  title: 'Aksesibilitas',
                  subtitle: 'Tingkatkan kontras, animasi',
                  onTap: () => _showFeatureInfo('Aksesibilitas', 'Pengaturan teks tebal, kontras tinggi, dan pengurangan animasi.'),
                ),

                // 13. Bahasa Aplikasi
                _buildSettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Bahasa Aplikasi',
                  subtitle: 'Bahasa Indonesia (bahasa perangkat)',
                  onTap: () => _showFeatureInfo('Bahasa Aplikasi', 'Bahasa aktif saat ini: Bahasa Indonesia.'),
                ),

                // 14. Bantuan dan masukan
                _buildSettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Bantuan dan masukan',
                  subtitle: 'Pusat Bantuan, hubungi kami, Kebijakan Privasi',
                  onTap: () => _showFeatureInfo('Bantuan & Masukan', 'Pusat bantuan LightChat, kontak pengembang, dan syarat privasi.'),
                ),

                // 15. Undang teman
                _buildSettingsTile(
                  icon: Icons.group_outlined,
                  title: 'Undang teman',
                  subtitle: null,
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: 'Ayo download dan gunakan LightChat untuk chatting dan call gratis!'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tautan undangan disalin ke clipboard! 📋')),
                    );
                  },
                ),

                // 16. Pembaruan aplikasi
                _buildSettingsTile(
                  icon: Icons.mobile_friendly_rounded,
                  title: 'Pembaruan aplikasi',
                  subtitle: null,
                  onTap: _checkAppUpdate,
                ),

                // 17. Pusat Akun
                _buildSettingsTile(
                  icon: Icons.all_inclusive_rounded,
                  title: 'Pusat Akun',
                  subtitle: 'Kendalikan pengalaman Anda di WhatsApp, Facebook, Instagram, dan lainnya.',
                  onTap: () => _showFeatureInfo('Pusat Akun', 'Kelola akun Anda di seluruh layanan ekosistem LightChat.'),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    bool hasGreenDot = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasGreenDot)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF25D366),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAccountDialog(UserEntity user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pengaturan Akun', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone_rounded, color: AppColors.primary),
                title: const Text('Nomor Telepon', style: TextStyle(color: Colors.white)),
                subtitle: Text(user.phoneNumber, style: const TextStyle(color: Colors.white54)),
              ),
              const ListTile(
                leading: Icon(Icons.security_rounded, color: AppColors.primary),
                title: Text('Notifikasi Keamanan', style: TextStyle(color: Colors.white)),
                subtitle: Text('Pesan dan panggilan Anda dienkripsi end-to-end', style: TextStyle(color: Colors.white54)),
              ),
              const Divider(color: AppColors.divider),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text('Keluar dari Akun', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
