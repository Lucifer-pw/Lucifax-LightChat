import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../calls/domain/entities/call_entity.dart';
import '../../../chat/domain/usecases/create_or_get_chat.dart';
import '../../../../app/di/injection.dart';

class ContactProfilePage extends StatefulWidget {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String phoneNumber;
  final String about;

  const ContactProfilePage({
    super.key,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.phoneNumber,
    this.about = 'Available',
  });

  @override
  State<ContactProfilePage> createState() => _ContactProfilePageState();
}

class _ContactProfilePageState extends State<ContactProfilePage> {
  String? _liveName;
  String? _livePhoto;
  String? _liveBio;
  String? _livePhone;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _liveName = widget.displayName;
    _livePhoto = widget.photoUrl;
    _liveBio = widget.about;
    _livePhone = widget.phoneNumber;
  }

  Widget _buildFullScreenImage(String? url, String name) {
    if (url == null || url.isEmpty) {
      return _buildPlaceholderPhoto(name, size: 200);
    }
    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholderPhoto(name, size: 200),
        );
      } catch (_) {
        return _buildPlaceholderPhoto(name, size: 200);
      }
    } else {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        errorWidget: (_, __, ___) => _buildPlaceholderPhoto(name, size: 200),
      );
    }
  }

  void _openFullScreenPhoto(String? url, String name) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(name, style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildFullScreenImage(url, name),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPhoto(String name, {double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  void _startChat() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return;

    final createOrGetChat = getIt<CreateOrGetPrivateChat>();
    final result = await createOrGetChat.call(
      currentUserId: authState.user.uid,
      otherUserId: widget.userId,
      otherUserName: _liveName ?? widget.displayName,
      otherUserPhoto: _livePhoto,
    );
    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
        );
      },
      (chat) {
        if (!mounted) return;
        appRouter.push('/chat/${chat.chatId}', extra: chat);
      },
    );
  }

  void _startCall(bool isVideo) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return;

    final currentUserId = authState.user.uid;
    final callId = '${currentUserId}_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';

    final call = CallEntity(
      callId: callId,
      callerId: currentUserId,
      receiverId: widget.userId,
      callerName: authState.user.displayName,
      callerPhoto: authState.user.photoUrl,
      receiverName: _liveName ?? widget.displayName,
      receiverPhoto: _livePhoto,
      type: isVideo ? 'video' : 'voice',
      status: 'calling',
      createdAt: DateTime.now(),
    );

    appRouter.push('/call', extra: {
      'call': call,
      'isCaller': true,
      'currentUserId': currentUserId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          _liveName = data['displayName'] ?? _liveName;
          _livePhoto = data['photoUrl'] ?? _livePhoto;
          _liveBio = data['about'] ?? data['bio'] ?? _liveBio;
          _livePhone = data['phoneNumber'] ?? _livePhone;
          _isOnline = data['isOnline'] ?? false;
        }

        final displayName = _liveName ?? widget.displayName;
        final photoUrl = _livePhoto;
        final phoneNumber = _livePhone ?? widget.phoneNumber;
        final bio = _liveBio ?? widget.about;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: const Text('Contact info'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '$displayName: $phoneNumber'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact info copied!')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Top Profile Header Card
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      // Large Avatar
                      GestureDetector(
                        onTap: () => _openFullScreenPhoto(photoUrl, displayName),
                        child: Stack(
                          children: [
                            CustomAvatar(
                              imageUrl: photoUrl,
                              name: displayName,
                              radius: 56,
                              isOnline: _isOnline,
                              showOnlineBadge: true,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        displayName,
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      // Phone / Status
                      Text(
                        phoneNumber.isNotEmpty ? phoneNumber : 'LightChat Contact',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isOnline ? AppColors.onlineIndicator : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOnline ? 'Online' : 'Offline',
                            style: AppTextStyles.caption.copyWith(
                              color: _isOnline ? AppColors.onlineIndicator : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons (Chat, Audio, Video)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionTile(
                            icon: Icons.chat_rounded,
                            label: 'Message',
                            onTap: _startChat,
                          ),
                          const SizedBox(width: 24),
                          _buildActionTile(
                            icon: Icons.call_rounded,
                            label: 'Audio',
                            onTap: () => _startCall(false),
                          ),
                          const SizedBox(width: 24),
                          _buildActionTile(
                            icon: Icons.videocam_rounded,
                            label: 'Video',
                            onTap: () => _startCall(true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // About / Bio Section
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio.isNotEmpty ? bio : 'Available',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Phone Details Card
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone number',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phoneNumber.isNotEmpty ? phoneNumber : '-',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Mobile',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
                            onPressed: () {
                              if (phoneNumber.isNotEmpty) {
                                Clipboard.setData(ClipboardData(text: phoneNumber));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Phone number copied to clipboard')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Encryption Security Card
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Encryption',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Messages and calls are end-to-end encrypted. No one outside of this chat can read or listen to them.',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.r12),
          border: Border.all(color: AppColors.divider.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
