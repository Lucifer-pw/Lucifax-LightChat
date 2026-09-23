import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MessageStatusIcon extends StatelessWidget {
  final String status;
  final double size;

  const MessageStatusIcon({
    super.key,
    required this.status,
    this.size = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'read':
        return Icon(
          Icons.done_all_rounded,
          size: size,
          color: AppColors.statusRead,
        );
      case 'delivered':
        return Icon(
          Icons.done_all_rounded,
          size: size,
          color: AppColors.statusDelivered,
        );
      case 'sent':
      default:
        return Icon(
          Icons.done_rounded,
          size: size,
          color: AppColors.statusSent,
        );
    }
  }
}
