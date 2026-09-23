import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  String _selectedBubbleStyle = 'rounded';
  Color _sentBubbleColor = AppColors.bubbleSent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Appearance & Theme'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.p16),
        children: [
          Text('PREVIEW', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bubbleReceived,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Hello! How does this dynamic bubble look? ✨'),
                  ),
                ),
                AppSizes.vSpace12,
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _sentBubbleColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Looks sleek and dark! 🚀'),
                  ),
                ),
              ],
            ),
          ),
          AppSizes.vSpace24,
          Text('BUBBLE STYLE', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
          AppSizes.vSpace8,
          RadioListTile<String>(
            title: const Text('Modern Rounded'),
            value: 'rounded',
            groupValue: _selectedBubbleStyle,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _selectedBubbleStyle = val!),
          ),
          RadioListTile<String>(
            title: const Text('Classic Sharp'),
            value: 'sharp',
            groupValue: _selectedBubbleStyle,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _selectedBubbleStyle = val!),
          ),
          AppSizes.vSpace24,
          Text('SENT BUBBLE COLOR', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
          AppSizes.vSpace12,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ColorChoice(
                color: const Color(0xFF005C4B), // Emerald Dark (Default)
                isSelected: _sentBubbleColor == const Color(0xFF005C4B),
                onTap: () => setState(() => _sentBubbleColor = const Color(0xFF005C4B)),
              ),
              _ColorChoice(
                color: const Color(0xFF1E3A8A), // Blue
                isSelected: _sentBubbleColor == const Color(0xFF1E3A8A),
                onTap: () => setState(() => _sentBubbleColor = const Color(0xFF1E3A8A)),
              ),
              _ColorChoice(
                color: const Color(0xFF581C87), // Purple
                isSelected: _sentBubbleColor == const Color(0xFF581C87),
                onTap: () => setState(() => _sentBubbleColor = const Color(0xFF581C87)),
              ),
              _ColorChoice(
                color: const Color(0xFF374151), // Charcoal
                isSelected: _sentBubbleColor == const Color(0xFF374151),
                onTap: () => setState(() => _sentBubbleColor = const Color(0xFF374151)),
              ),
            ],
          ),
        ],
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
        ),
      ),
    );
  }
}
