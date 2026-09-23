import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/phone_number_formatter.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthenticatedState) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover Photo / Mini Background Profil
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
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
                  child: CustomAvatar(
                    imageUrl: user.photoUrl,
                    name: user.displayName,
                    radius: 48,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 55),
            Text(
              user.displayName,
              style: AppTextStyles.heading2,
            ),
            AppSizes.vSpace4,
            Text(
              PhoneNumberFormatter.toDisplay(user.phoneNumber),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            AppSizes.vSpace24,
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.iconColor),
              title: const Text('About', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              subtitle: Text(user.bio, style: AppTextStyles.bodyMedium),
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.phone_rounded, color: AppColors.iconColor),
              title: const Text('Phone', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              subtitle: Text(PhoneNumberFormatter.toDisplay(user.phoneNumber), style: AppTextStyles.bodyMedium),
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.palette_outlined, color: AppColors.iconColor),
              title: const Text('Appearance & Theme', style: TextStyle(color: AppColors.textPrimary)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => context.push('/appearance-settings'),
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.iconColor),
              title: const Text('LightChatWeb / Linked Devices', style: TextStyle(color: AppColors.textPrimary)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              onTap: () => context.push('/qr-scanner'),
            ),
            const Divider(color: AppColors.divider),
            AppSizes.vSpace24,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(SignOutEvent());
                    context.go('/welcome');
                  },
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
  }
}
