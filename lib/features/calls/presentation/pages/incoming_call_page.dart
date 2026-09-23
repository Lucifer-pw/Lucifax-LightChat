import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../domain/entities/call_entity.dart';
import '../bloc/incoming_call_cubit.dart';

class IncomingCallPage extends StatelessWidget {
  final CallEntity call;
  final String currentUserId;

  const IncomingCallPage({
    super.key,
    required this.call,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final callerName = call.callerName;
    final callerPhoto = call.callerPhoto;
    final isVideo = call.isVideo;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p32),
          child: Column(
            children: [
              // Top Encryption Label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'LightChat ${isVideo ? 'Video' : 'Voice'} Call',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Caller Name
              Text(
                callerName,
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Status indicator
              Text(
                'Incoming call...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // Caller Avatar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      spreadRadius: 24,
                      blurRadius: 48,
                    ),
                  ],
                ),
                child: CustomAvatar(
                  imageUrl: callerPhoto,
                  name: callerName,
                  radius: 70,
                ),
              ),

              const Spacer(),

              // Bottom Action Buttons: Reject & Accept
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject Button (Red)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: AppColors.error,
                        shape: const CircleBorder(),
                        elevation: 6,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            getIt<IncomingCallCubit>().rejectIncomingCall(call.callId);
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Decline',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),

                  // Accept Button (Green)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        elevation: 6,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            getIt<IncomingCallCubit>().clearIncomingCall();
                            context.pushReplacement('/call', extra: {
                              'call': call,
                              'isCaller': false,
                              'currentUserId': currentUserId,
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Icon(
                              isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Accept',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
