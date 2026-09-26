import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/services/audio_route_service.dart';

class AudioRouteSelectorDialog extends StatelessWidget {
  final AudioOutputRoute currentRoute;
  final List<AudioOutputRoute> availableRoutes;
  final ValueChanged<AudioOutputRoute> onRouteSelected;

  const AudioRouteSelectorDialog({
    super.key,
    required this.currentRoute,
    required this.availableRoutes,
    required this.onRouteSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required AudioOutputRoute currentRoute,
    required List<AudioOutputRoute> availableRoutes,
    required ValueChanged<AudioOutputRoute> onRouteSelected,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: AudioRouteSelectorDialog(
          currentRoute: currentRoute,
          availableRoutes: availableRoutes,
          onRouteSelected: (route) {
            Navigator.of(ctx).pop();
            onRouteSelected(route);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C34),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            context: context,
            icon: Icons.volume_up_rounded,
            title: 'Speaker',
            route: AudioOutputRoute.speaker,
          ),
          _buildItem(
            context: context,
            icon: Icons.phone_android_rounded,
            title: 'Earpiece',
            route: AudioOutputRoute.earpiece,
          ),
          _buildItem(
            context: context,
            icon: Icons.bluetooth_rounded,
            title: 'Bluetooth',
            route: AudioOutputRoute.bluetooth,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required AudioOutputRoute route,
  }) {
    final isSelected = currentRoute == route;

    return InkWell(
      onTap: () => onRouteSelected(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
