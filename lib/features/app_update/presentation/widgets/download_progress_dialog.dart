import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';

class DownloadProgressDialog extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;

  const DownloadProgressDialog({
    super.key,
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    final receivedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);

    return PopScope(
      canPop: false, // Prevent dismissal during download
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.downloading_rounded, color: AppColors.primary, size: 48),
              AppSizes.vSpace16,
              Text('Downloading Update...', style: AppTextStyles.heading3),
              AppSizes.vSpace8,
              Text(
                '$percentage% ($receivedMb MB / $totalMb MB)',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              AppSizes.vSpace16,
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
              AppSizes.vSpace12,
              Text(
                'Please wait while the update is being downloaded. The installer will launch automatically.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
