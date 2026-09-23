import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/app_update_info.dart';
import '../../domain/usecases/download_apk.dart';
import 'download_progress_dialog.dart';

class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback onDismiss;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.isForceUpdate,
      builder: (context) => UpdateDialog(
        updateInfo: updateInfo,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _startDownload(BuildContext context) async {
    final downloadUrl = updateInfo.downloadUrl;
    if (downloadUrl == null || downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download URL not available for this release')),
      );
      return;
    }

    Navigator.pop(context); // Close update dialog

    double progress = 0.0;
    int received = 0;
    int total = updateInfo.apkSize ?? 1;

    // Show Progress Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (progressContext) => StatefulBuilder(
        builder: (context, setProgressState) {
          final downloadUseCase = getIt<DownloadAndInstallApk>();

          // Start downloading
          downloadUseCase(
            downloadUrl,
            (rec, tot) {
              if (progressContext.mounted) {
                setProgressState(() {
                  received = rec;
                  total = tot > 0 ? tot : total;
                  progress = total > 0 ? (received / total) : 0.0;
                });
              }
            },
          ).then((result) {
            if (progressContext.mounted) {
              Navigator.pop(progressContext);
            }
            result.fold(
              (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
                );
              },
              (success) {
                // Installer is launched by OpenFilex
              },
            );
          });

          return DownloadProgressDialog(
            progress: progress,
            receivedBytes: received,
            totalBytes: total,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizeMb = updateInfo.apkSize != null
        ? ' (${(updateInfo.apkSize! / (1024 * 1024)).toStringAsFixed(1)} MB)'
        : '';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 28),
                ),
                AppSizes.hSpace12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update Available!', style: AppTextStyles.heading3),
                      Text(
                        'v${updateInfo.latestVersion}$sizeMb',
                        style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSizes.vSpace16,
            Text('What\'s New:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            AppSizes.vSpace8,
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Text(
                  updateInfo.releaseNotes,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                ),
              ),
            ),
            AppSizes.vSpace24,
            Row(
              children: [
                if (!updateInfo.isForceUpdate)
                  Expanded(
                    child: TextButton(
                      onPressed: onDismiss,
                      child: const Text('LATER', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _startDownload(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('UPDATE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
