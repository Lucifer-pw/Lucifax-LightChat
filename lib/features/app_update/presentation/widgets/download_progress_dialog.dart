import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/usecases/download_apk.dart';

class DownloadProgressDialog extends StatefulWidget {
  final String downloadUrl;
  final int? expectedSize;

  const DownloadProgressDialog({
    super.key,
    required this.downloadUrl,
    this.expectedSize,
  });

  static Future<void> show(
    BuildContext context, {
    required String downloadUrl,
    int? expectedSize,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        downloadUrl: downloadUrl,
        expectedSize: expectedSize,
      ),
    );
  }

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 1;
  bool _isDownloading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _totalBytes = (widget.expectedSize != null && widget.expectedSize! > 0)
        ? widget.expectedSize!
        : 1;
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    final downloadUseCase = getIt<DownloadAndInstallApk>();
    final result = await downloadUseCase(
      widget.downloadUrl,
      (received, total) {
        if (mounted) {
          setState(() {
            _receivedBytes = received;
            if (total > 0) {
              _totalBytes = total;
            }
            _progress = _totalBytes > 0 ? (_receivedBytes / _totalBytes) : 0.0;
          });
        }
      },
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isDownloading = false;
          _errorMessage = failure.message;
        });
      },
      (success) {
        // Installer launched, close dialog
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_progress * 100).clamp(0, 100).toStringAsFixed(0);
    final receivedMb = (_receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = (_totalBytes > 1)
        ? (_totalBytes / (1024 * 1024)).toStringAsFixed(1)
        : '...';

    return PopScope(
      canPop: !_isDownloading, // Prevent accidental dismissal during active download
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.r16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _errorMessage != null
                    ? Icons.error_outline_rounded
                    : Icons.downloading_rounded,
                color: _errorMessage != null
                    ? AppColors.error
                    : AppColors.primary,
                size: 48,
              ),
              AppSizes.vSpace16,
              Text(
                _errorMessage != null
                    ? 'Gagal Mengunduh'
                    : 'Mengunduh Pembaruan...',
                style: AppTextStyles.heading3,
              ),
              AppSizes.vSpace8,
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error),
                ),
                AppSizes.vSpace20,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: const Text('BATAL',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    AppSizes.hSpace12,
                    ElevatedButton(
                      onPressed: _startDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('COBA LAGI',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  '$percentage% ($receivedMb MB / $totalMb MB)',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                AppSizes.vSpace16,
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                    minHeight: 8,
                  ),
                ),
                AppSizes.vSpace12,
                Text(
                  'Mohon tunggu, berkas pembaruan sedang diunduh. Installer akan terbuka secara otomatis.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
