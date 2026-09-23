import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../domain/entities/user_status_group.dart';
import 'segmented_status_circle.dart';

class StatusItemTile extends StatelessWidget {
  final UserStatusGroup statusGroup;
  final String currentUserId;
  final VoidCallback onTap;

  const StatusItemTile({
    super.key,
    required this.statusGroup,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeItems = statusGroup.activeItems;
    if (activeItems.isEmpty) return const SizedBox.shrink();

    final unviewedCount = activeItems.where((i) => !i.isViewedBy(currentUserId)).length;
    final latestItem = activeItems.last;
    final timeStr = timeago.format(latestItem.createdAt, locale: 'en_short');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: 4),
      leading: SegmentedStatusCircle(
        totalCount: activeItems.length,
        unviewedCount: unviewedCount,
        child: CustomAvatar(
          imageUrl: statusGroup.userPhotoUrl,
          name: statusGroup.userName,
          radius: 26,
        ),
      ),
      title: Text(
        statusGroup.userName,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: unviewedCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '$timeStr ago',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      onTap: onTap,
    );
  }
}
