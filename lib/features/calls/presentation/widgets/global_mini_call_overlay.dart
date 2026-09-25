import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/call_cubit.dart';
import '../bloc/call_state.dart';

class GlobalMiniCallOverlay extends StatefulWidget {
  final Widget child;

  const GlobalMiniCallOverlay({super.key, required this.child});

  @override
  State<GlobalMiniCallOverlay> createState() => _GlobalMiniCallOverlayState();
}

class _GlobalMiniCallOverlayState extends State<GlobalMiniCallOverlay> {
  double _top = 80;
  double _right = 16;

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    final minStr = mins.toString().padLeft(2, '0');
    final secStr = remainingSecs.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallCubit, CallState>(
      builder: (context, callState) {
        final isActive = callState.status == CallStatus.connected ||
            callState.status == CallStatus.calling ||
            callState.status == CallStatus.ringing;

        final currentRoute = appRouter.routerDelegate.currentConfiguration.uri.toString();
        final isCallPageOpen = currentRoute.contains('/call') || currentRoute.contains('/incoming-call');

        final showOverlay = isActive && !isCallPageOpen && callState.call != null;

        return Stack(
          children: [
            widget.child,
            if (showOverlay)
              Positioned(
                top: _top,
                right: _right,
                child: _buildDraggableFloatingCallCard(context, callState),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDraggableFloatingCallCard(BuildContext context, CallState callState) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState is AuthenticatedState ? authState.user.uid : '';
    final otherUserName = callState.call!.getOtherUserName(currentUserId);
    final otherUserPhoto = callState.call!.getOtherUserPhoto(currentUserId);

    final isConnected = callState.status == CallStatus.connected;
    final statusText = isConnected ? _formatDuration(callState.duration) : 'Calling...';

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _top += details.delta.dy;
          _right -= details.delta.dx;
          // Clamp inside screen boundaries
          _top = _top.clamp(50.0, MediaQuery.of(context).size.height - 180.0);
          _right = _right.clamp(8.0, MediaQuery.of(context).size.width - 240.0);
        });
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(AppSizes.r16),
            border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row: Avatar + Name + Timer (Tap to expand)
              InkWell(
                onTap: () {
                  appRouter.push('/call', extra: {
                    'call': callState.call,
                    'isCaller': callState.isCaller,
                    'currentUserId': currentUserId,
                  });
                },
                borderRadius: BorderRadius.circular(AppSizes.r12),
                child: Row(
                  children: [
                    CustomAvatar(
                      imageUrl: otherUserPhoto,
                      name: otherUserName,
                      radius: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherUserName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isConnected ? AppColors.onlineIndicator : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: AppTextStyles.caption.copyWith(
                                  color: isConnected ? AppColors.primary : AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.open_in_full_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 8),

              // Quick control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mic
                  InkWell(
                    onTap: () => context.read<CallCubit>().toggleMicrophone(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        size: 20,
                        color: callState.isMuted ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // Speaker
                  InkWell(
                    onTap: () => context.read<CallCubit>().toggleSpeakerphone(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        callState.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        size: 20,
                        color: callState.isSpeakerOn ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // End Call (Red)
                  InkWell(
                    onTap: () => context.read<CallCubit>().endCall(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
