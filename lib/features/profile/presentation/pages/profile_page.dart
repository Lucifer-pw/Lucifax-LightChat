import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/phone_number_formatter.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../app_update/domain/usecases/check_for_update.dart';
import '../../../app_update/presentation/widgets/update_dialog.dart';
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
  bool _isUpdating = false;

  final List<String> _presetBios = [
    '⚡ Available & Active',
    '🎵 Vibe with Music Lounge',
    '💻 Coding & Building LightChat',
    '☕ Coffee & Chill',
    '🌙 Night Owl Mode',
    '🔕 In a Meeting / Busy',
    '🚀 Exploring the Universe',
    '✨ Simple. Fast. Secure.',
  ];

  // ----------------------------------------------------
  // CRUD Actions
  // ----------------------------------------------------

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthenticatedState) {
          setState(() => _isUpdating = true);
          context.read<AuthBloc>().add(
                SaveProfileEvent(
                  displayName: authState.user.displayName,
                  bio: authState.user.bio,
                  imageFile: File(pickedFile.path),
                ),
              );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAvatarOptions(String? currentPhotoUrl, String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Foto Profil',
                style: AppTextStyles.heading3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Ambil Foto Kamera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.blueAccent),
                  ),
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
        insetPadding: const EdgeInsets.all(16),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSizes.p24,
          right: AppSizes.p24,
          top: AppSizes.p24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.badge_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Ubah Nama Tampilan', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nama ini akan terlihat oleh semua kontak dan anggota grup Anda.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLength: 30,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Ketik nama Anda...',
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                  onPressed: () => controller.clear(),
                ),
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
                    final newName = controller.text.trim();
                    if (newName.isNotEmpty) {
                      Navigator.pop(ctx);
                      setState(() => _isUpdating = true);
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSizes.p24,
            right: AppSizes.p24,
            top: AppSizes.p24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Status & Bio', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih vibe instan atau tulis pesan bio Anda sendiri.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLength: 80,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Tuliskan status bio Anda...',
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
              const SizedBox(height: 12),
              Text('PRESET VIBE CEPAT', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
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
                        setState(() => _isUpdating = true);
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMyQrCode(String name, String phone, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text('QR Kontak Saya', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.r16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: 'lightchat:user:$uid:$phone',
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF00A884)),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF111B21)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: AppTextStyles.heading2.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              PhoneNumberFormatter.toDisplay(phone),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Arahkan kamera LightChat teman Anda ke QR ini untuk mulai mengobrol secara instan.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSecurityModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('Enkripsi & Keamanan Data', style: AppTextStyles.heading3.copyWith(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSecurityFeature(
              Icons.lock_rounded,
              'Enkripsi End-to-End P2P',
              'Panggilan suara dan video terenkripsi langsung antar-perangkat menggunakan teknologi WebRTC DTLS/SRTP.',
            ),
            const SizedBox(height: 12),
            _buildSecurityFeature(
              Icons.security_rounded,
              'Firestore Security Rules v2',
              'Pesan dan status hanya dapat dibaca oleh partisipan yang sah melalui otentikasi Firebase.',
            ),
            const SizedBox(height: 12),
            _buildSecurityFeature(
              Icons.timer_outlined,
              'Status Kedaluwarsa 24 Jam',
              'Semua cerita dan status otomatis terhapus setelah 24 jam untuk menjaga privasi Anda.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFeature(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(desc, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
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

  // ----------------------------------------------------
  // Main UI
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthenticatedState && _isUpdating) {
          setState(() => _isUpdating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profil berhasil diperbarui ✨'),
                ],
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AuthErrorState && _isUpdating) {
          setState(() => _isUpdating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (context, authState) {
        if (authState is! AuthenticatedState) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Belum login', style: TextStyle(color: Colors.white))),
          );
        }

        final user = authState.user;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Profil & Akun'),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_rounded),
                tooltip: 'QR Code Saya',
                onPressed: () => _showMyQrCode(user.displayName, user.phoneNumber, user.uid),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Signature Cyber-Glass Header Card
                _buildSignatureHeaderCard(user),

                const SizedBox(height: 20),

                // 2. Kustomisasi & Media Section
                _buildSectionHeader('KUSTOMISASI & MEDIA'),
                _buildSettingsCard([
                  _buildMenuTile(
                    icon: Icons.palette_outlined,
                    iconBg: const Color(0xFF6C5CE7),
                    title: 'Tema & Wallpaper Obrolan',
                    subtitle: 'Kustomisasi latar belakang dan gaya tampilan chat',
                    onTap: () => context.push('/appearance-settings'),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  _buildMenuTile(
                    icon: Icons.music_note_rounded,
                    iconBg: const Color(0xFF00CEC9),
                    title: 'Music Lounge',
                    subtitle: 'Dengarkan lagu dan kelola musik bersama',
                    onTap: () => context.push('/music-browse'),
                  ),
                ]),

                const SizedBox(height: 16),

                // 3. Konektivitas & Keamanan Section
                _buildSectionHeader('KONEKTIVITAS & KEAMANAN'),
                _buildSettingsCard([
                  _buildMenuTile(
                    icon: Icons.laptop_chromebook_rounded,
                    iconBg: const Color(0xFF0984E3),
                    title: 'Perangkat Tertaut (LightChatWeb)',
                    subtitle: 'Pindai QR code untuk login di browser web',
                    onTap: () => context.push('/qr-scanner'),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  _buildMenuTile(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFF00B894),
                    title: 'Enkripsi & Keamanan Data',
                    subtitle: 'Informasi enkripsi end-to-end P2P WebRTC',
                    onTap: _showSecurityModal,
                  ),
                ]),

                const SizedBox(height: 16),

                // 4. Informasi & Pembaruan
                _buildSectionHeader('INFORMASI APLIKASI'),
                _buildSettingsCard([
                  _buildMenuTile(
                    icon: Icons.system_update_rounded,
                    iconBg: AppColors.primary,
                    title: 'Cek Pembaruan Versi',
                    subtitle: 'Versi rilis saat ini: v1.0.9',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSizes.rFull),
                      ),
                      child: const Text('Latest', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    onTap: _checkAppUpdate,
                  ),
                ]),

                const SizedBox(height: 24),

                // 5. Danger Zone / Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppColors.error),
                      ),
                      title: const Text('Keluar dari Akun', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Keluar dari sesi LightChat pada perangkat ini', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                      onTap: () => _confirmLogout(),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // Header Widget (Signature UI)
  // ----------------------------------------------------

  Widget _buildSignatureHeaderCard(dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Cover Banner Gradient
            Container(
              height: 90,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24 - 2)),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF005C4B),
                    Color(0xFF0F3E36),
                    Color(0xFF111B21),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(AppSizes.rFull),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, color: AppColors.primary, size: 14),
                          SizedBox(width: 4),
                          Text('LightChat Verified', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Avatar + Info Section
            Transform.translate(
              offset: const Offset(0, -45),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                child: Column(
                  children: [
                    // Avatar with glowing ring & Camera Button
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF00E676)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CustomAvatar(
                            imageUrl: user.photoUrl,
                            name: user.displayName,
                            radius: 46,
                            onTap: () => _showAvatarOptions(user.photoUrl, user.displayName),
                          ),
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
                              padding: EdgeInsets.all(7),
                              child: Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Display Name + Edit Icon
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showEditNameDialog(user.displayName, user.bio),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.displayName,
                              style: AppTextStyles.heading1.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Phone Number with Copy Button
                    InkWell(
                      borderRadius: BorderRadius.circular(AppSizes.rFull),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: user.phoneNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nomor telepon disalin ke clipboard 📋'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppSizes.rFull),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              PhoneNumberFormatter.toDisplay(user.phoneNumber),
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bio Card (Interactive)
                    InkWell(
                      borderRadius: BorderRadius.circular(AppSizes.r16),
                      onTap: () => _showEditBioDialog(user.displayName, user.bio),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppSizes.r16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('STATUS & BIO', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 18),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '"${user.bio}"',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Action: Show My QR Code Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showMyQrCode(user.displayName, user.phoneNumber, user.uid),
                        icon: const Icon(Icons.qr_code_rounded, color: AppColors.primary, size: 18),
                        label: const Text('Buka QR Code Kontak Saya', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // Section & Menu Builders
  // ----------------------------------------------------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.r16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBg.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconBg, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Keluar Akun?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun LightChat pada perangkat ini?',
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
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
