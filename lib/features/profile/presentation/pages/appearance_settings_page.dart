import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/appearance_cubit.dart';
import '../../../../core/theme/text_styles.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  Future<void> _pickCustomWallpaper(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && context.mounted) {
      context.read<AppearanceCubit>().setWallpaper('custom', customPath: pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appearance & Theme'),
      ),
      body: BlocBuilder<AppearanceCubit, AppearanceState>(
        builder: (context, state) {
          final cubit = context.read<AppearanceCubit>();

          return ListView(
            padding: const EdgeInsets.all(AppSizes.p16),
            children: [
              Text('LIVE PREVIEW', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              AppSizes.vSpace12,
              Container(
                padding: const EdgeInsets.all(AppSizes.p16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.r16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bubbleReceived,
                          borderRadius: BorderRadius.circular(state.bubbleStyle == 'rounded' ? 16 : 4),
                        ),
                        child: const Text('Hello! How does this dynamic bubble look? ✨'),
                      ),
                    ),
                    AppSizes.vSpace12,
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: state.sentBubbleColor,
                          borderRadius: BorderRadius.circular(state.bubbleStyle == 'rounded' ? 16 : 4),
                        ),
                        child: const Text('Looks sleek and custom! 🚀', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              AppSizes.vSpace24,

              // Bubble Style
              Text('BUBBLE STYLE', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              AppSizes.vSpace8,
              RadioListTile<String>(
                title: const Text('Modern Rounded (WhatsApp Style)'),
                value: 'rounded',
                groupValue: state.bubbleStyle,
                activeColor: AppColors.primary,
                onChanged: (val) => cubit.setBubbleStyle(val!),
              ),
              RadioListTile<String>(
                title: const Text('Classic Sharp'),
                value: 'sharp',
                groupValue: state.bubbleStyle,
                activeColor: AppColors.primary,
                onChanged: (val) => cubit.setBubbleStyle(val!),
              ),
              AppSizes.vSpace24,

              // Bubble Color Palette
              Text('SENT BUBBLE COLOR', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              AppSizes.vSpace12,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ColorChoice(
                    color: const Color(0xFF005C4B), // Emerald Dark (Default)
                    isSelected: state.sentBubbleColor.value == const Color(0xFF005C4B).value,
                    onTap: () => cubit.setSentBubbleColor(const Color(0xFF005C4B)),
                  ),
                  _ColorChoice(
                    color: const Color(0xFF1E3A8A), // Sapphire Blue
                    isSelected: state.sentBubbleColor.value == const Color(0xFF1E3A8A).value,
                    onTap: () => cubit.setSentBubbleColor(const Color(0xFF1E3A8A)),
                  ),
                  _ColorChoice(
                    color: const Color(0xFF581C87), // Royal Purple
                    isSelected: state.sentBubbleColor.value == const Color(0xFF581C87).value,
                    onTap: () => cubit.setSentBubbleColor(const Color(0xFF581C87)),
                  ),
                  _ColorChoice(
                    color: const Color(0xFF9F1239), // Crimson
                    isSelected: state.sentBubbleColor.value == const Color(0xFF9F1239).value,
                    onTap: () => cubit.setSentBubbleColor(const Color(0xFF9F1239)),
                  ),
                  _ColorChoice(
                    color: const Color(0xFF374151), // Midnight Slate
                    isSelected: state.sentBubbleColor.value == const Color(0xFF374151).value,
                    onTap: () => cubit.setSentBubbleColor(const Color(0xFF374151)),
                  ),
                ],
              ),
              AppSizes.vSpace24,

              // Chat Wallpaper Options
              Text('CHAT WALLPAPER', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              AppSizes.vSpace8,
              RadioListTile<String>(
                title: const Text('Default WhatsApp Dark Doodle'),
                value: 'default',
                groupValue: state.wallpaperType,
                activeColor: AppColors.primary,
                onChanged: (val) => cubit.setWallpaper(val!),
              ),
              RadioListTile<String>(
                title: const Text('Solid Midnight Black'),
                value: 'solid_dark',
                groupValue: state.wallpaperType,
                activeColor: AppColors.primary,
                onChanged: (val) => cubit.setWallpaper(val!),
              ),
              RadioListTile<String>(
                title: const Text('Solid Dark Forest'),
                value: 'solid_forest',
                groupValue: state.wallpaperType,
                activeColor: AppColors.primary,
                onChanged: (val) => cubit.setWallpaper(val!),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.primary),
                title: const Text('Custom Photo from Gallery'),
                subtitle: state.wallpaperType == 'custom'
                    ? const Text('Custom wallpaper active', style: TextStyle(color: AppColors.primary))
                    : const Text('Select a photo from device storage'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickCustomWallpaper(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChoice({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
