import 'package:equatable/equatable.dart';

class AppUpdateInfo extends Equatable {
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String? downloadUrl;
  final int? apkSize;
  final bool hasUpdate;
  final bool isForceUpdate;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    this.downloadUrl,
    this.apkSize,
    required this.hasUpdate,
    this.isForceUpdate = false,
  });

  @override
  List<Object?> get props => [
        latestVersion,
        currentVersion,
        releaseNotes,
        downloadUrl,
        apkSize,
        hasUpdate,
        isForceUpdate,
      ];
}
