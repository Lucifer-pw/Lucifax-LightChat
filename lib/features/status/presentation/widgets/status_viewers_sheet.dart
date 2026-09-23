import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../domain/entities/status_item.dart';

class StatusViewersSheet extends StatelessWidget {
  final StatusItem item;
  final VoidCallback onDelete;

  const StatusViewersSheet({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AppSizes.vSpace16,
          // Header with count & delete
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Viewed by ${item.viewers.length}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Delete this status update?'),
                        content: const Text('It will also be deleted for everyone who received it.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context); // Close sheet
                              onDelete();
                            },
                            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          if (item.viewers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.p32),
              child: Text(
                'No views yet',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: 8),
                itemCount: item.viewers.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final viewer = item.viewers[index];
                  final timeStr = DateFormat('HH:mm').format(viewer.viewedAt);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CustomAvatar(
                      imageUrl: viewer.userPhotoUrl,
                      name: viewer.userName,
                      radius: 20,
                    ),
                    title: Text(
                      viewer.userName,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      timeStr,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
