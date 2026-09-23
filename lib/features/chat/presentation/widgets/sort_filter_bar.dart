import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';

class SortFilterBar extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSortChanged;

  const SortFilterBar({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
      color: AppColors.surface,
      child: Row(
        children: [
          Icon(
            Icons.sort_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          AppSizes.hSpace8,
          Text(
            'Sort by:',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          AppSizes.hSpace8,
          _FilterChip(
            label: 'Recent',
            isSelected: currentSort == 'time',
            onTap: () => onSortChanged('time'),
          ),
          AppSizes.hSpace8,
          _FilterChip(
            label: 'Unread',
            isSelected: currentSort == 'unread',
            onTap: () => onSortChanged('unread'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
