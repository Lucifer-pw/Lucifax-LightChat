import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../domain/entities/call_entity.dart';
import '../bloc/call_cubit.dart';
import '../bloc/call_state.dart';

class CallPage extends StatefulWidget {
  final CallEntity call;
  final bool isCaller;
  final String currentUserId;

  const CallPage({
    super.key,
    required this.call,
    required this.isCaller,
    required this.currentUserId,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late CallCubit _callCubit;

  @override
  void initState() {
    super.initState();
    _callCubit = getIt<CallCubit>();

    if (widget.isCaller) {
      _callCubit.startCall(call: widget.call);
    } else {
      _callCubit.acceptCall(call: widget.call);
    }
  }

  @override
  void dispose() {
    _callCubit.close();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    final minStr = mins.toString().padLeft(2, '0');
    final secStr = remainingSecs.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  String _getStatusText(CallState state) {
    switch (state.status) {
      case CallStatus.connecting:
        return 'Connecting...';
      case CallStatus.calling:
        return 'Calling...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.connected:
        return _formatDuration(state.duration);
      case CallStatus.ended:
        return 'Call ended';
      case CallStatus.error:
        return state.errorMessage ?? 'Call failed';
      case CallStatus.initial:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUserName = widget.call.getOtherUserName(widget.currentUserId);
    final otherUserPhoto = widget.call.getOtherUserPhoto(widget.currentUserId);
    final isVideo = widget.call.isVideo;

    return BlocProvider.value(
      value: _callCubit,
      child: BlocConsumer<CallCubit, CallState>(
        listener: (context, state) {
          if (state.status == CallStatus.ended) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Stack(
                children: [
                  // 1. Background / Video Content
                  if (isVideo && state.status == CallStatus.connected)
                    _buildVideoView(state)
                  else
                    _buildVoiceView(otherUserName, otherUserPhoto, state),

                  // 2. Top Header (Name, Status, Encryption badge)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _buildHeader(otherUserName, state, isVideo),
                  ),

                  // 3. Local Camera Preview (PiP for Video Call)
                  if (isVideo && !state.isVideoOff && state.status != CallStatus.ended)
                    Positioned(
                      top: 80,
                      right: 16,
                      width: 110,
                      height: 160,
                      child: _buildLocalVideoPreview(),
                    ),

                  // 4. Bottom Controls Bar
                  Positioned(
                    bottom: 32,
                    left: 16,
                    right: 16,
                    child: _buildControlButtons(state, isVideo),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String name, CallState state, bool isVideo) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'End-to-end encrypted',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: AppTextStyles.heading1.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _getStatusText(state),
          style: AppTextStyles.bodyMedium.copyWith(
            color: state.status == CallStatus.connected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: state.status == CallStatus.connected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceView(String name, String? photo, CallState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (state.status == CallStatus.connected ? AppColors.primary : AppColors.surfaceLight)
                      .withOpacity(0.2),
                  spreadRadius: 20,
                  blurRadius: 40,
                ),
              ],
            ),
            child: CustomAvatar(
              imageUrl: photo,
              name: name,
              radius: 65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoView(CallState state) {
    return Positioned.fill(
      child: state.isRemoteVideoActive
          ? RTCVideoView(
              _callCubit.webrtcService.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          : Container(
              color: AppColors.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Camera is turned off',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLocalVideoPreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: RTCVideoView(
        _callCubit.webrtcService.localRenderer,
        mirror: true,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    );
  }

  Widget _buildControlButtons(CallState state, bool isVideo) {
    final isEnded = state.status == CallStatus.ended;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(AppSizes.r24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Speakerphone Button
          _buildCircleButton(
            icon: state.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            isActive: state.isSpeakerOn,
            onTap: isEnded ? null : () => _callCubit.toggleSpeakerphone(),
          ),

          // Microphone Mute Button
          _buildCircleButton(
            icon: state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            isActive: !state.isMuted,
            onTap: isEnded ? null : () => _callCubit.toggleMicrophone(),
          ),

          // Video On/Off Button (for video call)
          if (isVideo) ...[
            _buildCircleButton(
              icon: state.isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
              isActive: !state.isVideoOff,
              onTap: isEnded ? null : () => _callCubit.toggleVideo(),
            ),
            // Switch Camera Button
            _buildCircleButton(
              icon: Icons.flip_camera_ios_rounded,
              isActive: true,
              onTap: isEnded ? null : () => _callCubit.switchCamera(),
            ),
          ],

          // End Call Button (Red)
          Material(
            color: AppColors.error,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isEnded ? null : () => _callCubit.endCall(),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: isActive ? AppColors.surfaceLight : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: isActive ? Colors.white : AppColors.textMuted,
            size: 24,
          ),
        ),
      ),
    );
  }
}
