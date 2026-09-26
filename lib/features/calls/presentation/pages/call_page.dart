import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../data/services/audio_route_service.dart';
import '../../data/services/pip_service.dart';
import '../../domain/entities/call_entity.dart';
import '../bloc/call_cubit.dart';
import '../bloc/call_state.dart';
import '../widgets/audio_route_selector_dialog.dart';
import '../widgets/whatsapp_call_background.dart';

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
    _callCubit.setCallPageActive(true);

    final isSameCall = _callCubit.state.call?.callId == widget.call.callId;
    final isCallActive = _callCubit.state.status != CallStatus.initial &&
        _callCubit.state.status != CallStatus.ended &&
        _callCubit.state.status != CallStatus.error;

    if (!isSameCall || !isCallActive) {
      if (widget.isCaller) {
        _callCubit.startCall(call: widget.call);
      } else {
        _callCubit.acceptCall(call: widget.call);
      }
    }
  }

  @override
  void dispose() {
    _callCubit.setCallPageActive(false);
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    final minStr = mins.toString();
    final secStr = remainingSecs.toString().padLeft(2, '0');
    return '$minStr.$secStr';
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

  void _showAudioRouteDialog(CallState state) {
    AudioRouteSelectorDialog.show(
      context,
      currentRoute: state.audioRoute,
      availableRoutes: state.availableAudioRoutes,
      onRouteSelected: (route) {
        _callCubit.setAudioRoute(route);
      },
    );
  }

  void _showMoreMenu(CallState state, bool isVideo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF182229),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                title: const Text('Switch camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _callCubit.switchCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
                title: const Text('Picture in Picture', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  PipService.enterPip();
                },
              ),
              ListTile(
                leading: const Icon(Icons.speaker_group_rounded, color: Colors.white),
                title: const Text('Audio output', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAudioRouteDialog(state);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _minimizeCall() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      PipService.enterPip();
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
            backgroundColor: const Color(0xFF0C161C),
            body: SafeArea(
              child: Stack(
                children: [
                  // 1. Background (WhatsApp Doodle Pattern or RTC Video View)
                  if (isVideo && state.status == CallStatus.connected)
                    _buildVideoView(state)
                  else
                    WhatsAppCallBackground(
                      child: _buildVoiceView(otherUserName, otherUserPhoto, state),
                    ),

                  // 2. Top Header Bar (Minimize, Name, Duration, Add Participant)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: _buildHeader(otherUserName, state),
                  ),

                  // 3. Local Camera Preview (PiP overlay for Video Call)
                  if (isVideo && !state.isVideoOff && state.status != CallStatus.ended)
                    Positioned(
                      top: 80,
                      right: 16,
                      width: 110,
                      height: 160,
                      child: _buildLocalVideoPreview(),
                    ),

                  // 4. Bottom WhatsApp Control Sheet (2 Rows x 3 Columns)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomControlSheet(state, isVideo),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String name, CallState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Minimize / Collapse button
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _minimizeCall,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close_fullscreen_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),

        // Center: Contact Name & Status/Duration
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getStatusText(state),
                style: TextStyle(
                  fontSize: 13,
                  color: state.status == CallStatus.connected
                      ? Colors.white70
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // Right: Add Participant / Group Call button
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Group calling feature coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 24,
            ),
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
          // Circular Avatar with Atmospheric Glowing Ring
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1D5A75).withOpacity(0.5),
                  const Color(0xFF0F3142).withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: const [0.5, 0.8, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF15485E).withOpacity(0.35),
                  blurRadius: 50,
                  spreadRadius: 25,
                ),
              ],
            ),
            child: CustomAvatar(
              imageUrl: photo,
              name: name,
              radius: 72,
            ),
          ),
          const SizedBox(height: 80),
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
              color: const Color(0xFF0C161C),
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

  Widget _buildBottomControlSheet(CallState state, bool isVideo) {
    final isEnded = state.status == CallStatus.ended;

    // Determine Audio Button Icon & Active Status
    IconData audioIcon = Icons.volume_up_rounded;
    bool isAudioActive = false;

    if (state.audioRoute == AudioOutputRoute.bluetooth) {
      audioIcon = Icons.bluetooth_rounded;
      isAudioActive = true;
    } else if (state.audioRoute == AudioOutputRoute.speaker) {
      audioIcon = Icons.volume_up_rounded;
      isAudioActive = true;
    } else {
      audioIcon = Icons.phone_android_rounded;
      isAudioActive = false;
    }

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 28, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF101D24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Audio | Video | Bisukan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: audioIcon,
                label: 'Audio',
                isActive: isAudioActive,
                onTap: isEnded ? null : () => _showAudioRouteDialog(state),
              ),
              _buildActionButton(
                icon: state.isVideoOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                label: 'Video',
                isActive: isVideo && !state.isVideoOff,
                onTap: isEnded ? null : () => _callCubit.toggleVideo(),
              ),
              _buildActionButton(
                icon: state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: 'Bisukan',
                isActive: state.isMuted,
                onTap: isEnded ? null : () => _callCubit.toggleMicrophone(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row 2: Lainnya | Bagikan | Akhiri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.more_horiz_rounded,
                label: 'Lainnya',
                isActive: false,
                onTap: isEnded ? null : () => _showMoreMenu(state, isVideo),
              ),
              _buildActionButton(
                icon: Icons.file_upload_outlined,
                label: 'Bagikan',
                isActive: state.isScreenSharing,
                onTap: isEnded
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Screen sharing feature ready for conference update!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
              ),
              _buildEndCallButton(isEnded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive ? Colors.white : const Color(0xFF222E35),
          shape: const CircleBorder(),
          elevation: isActive ? 4 : 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: isActive ? Colors.black : Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton(bool isEnded) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: const Color(0xFFEA0038),
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isEnded ? null : () => _callCubit.endCall(),
            child: Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Akhiri',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
