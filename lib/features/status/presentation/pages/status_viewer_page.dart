import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../chat/domain/usecases/send_message.dart';
import '../../domain/entities/status_item.dart';
import '../../domain/entities/user_status_group.dart';
import '../bloc/status_bloc.dart';
import '../bloc/status_event.dart';
import '../widgets/status_viewers_sheet.dart';

class StatusViewerPage extends StatefulWidget {
  final UserStatusGroup statusGroup;
  final int initialIndex;

  const StatusViewerPage({
    super.key,
    required this.statusGroup,
    this.initialIndex = 0,
  });

  @override
  State<StatusViewerPage> createState() => _StatusViewerPageState();
}

class _StatusViewerPageState extends State<StatusViewerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late int _currentIndex;
  final TextEditingController _replyController = TextEditingController();
  bool _isPaused = false;

  List<StatusItem> get _items => widget.statusGroup.activeItems;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _items.isEmpty ? 0 : _items.length - 1);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onNext();
      }
    });

    _loadCurrentItem();
  }

  @override
  void dispose() {
    _animController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _loadCurrentItem() {
    if (_items.isEmpty) {
      Navigator.pop(context);
      return;
    }

    _animController.stop();
    _animController.reset();
    _animController.forward();

    // Mark as viewed
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      final currentItem = _items[_currentIndex];
      if (widget.statusGroup.userId != authState.user.uid) {
        context.read<StatusBloc>().add(
              ViewStatusItemEvent(
                statusOwnerId: widget.statusGroup.userId,
                statusItemId: currentItem.id,
                viewerId: authState.user.uid,
                viewerName: authState.user.displayName.isNotEmpty
                    ? authState.user.displayName
                    : 'User',
                viewerPhotoUrl: authState.user.photoUrl,
              ),
            );
      }
    }
  }

  void _onNext() {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadCurrentItem();
    } else {
      Navigator.pop(context);
    }
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadCurrentItem();
    } else {
      _animController.reset();
      _animController.forward();
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _animController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _animController.forward();
    }
  }

  void _openViewersSheet(StatusItem item) {
    _pause();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatusViewersSheet(
        item: item,
        onDelete: () {
          context.read<StatusBloc>().add(
                DeleteStatusItemEvent(
                  statusOwnerId: widget.statusGroup.userId,
                  statusItemId: item.id,
                ),
              );
          Navigator.pop(context);
        },
      ),
    ).whenComplete(() {
      _resume();
    });
  }

  Future<void> _sendReply(String currentUserId, String currentUserName) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final currentItem = _items[_currentIndex];
    final sendMessage = getIt<SendMessage>();

    // Send reply as message
    final replyContent = 'Replying to status: "${currentItem.type == 'text' ? currentItem.content : (currentItem.caption ?? 'Photo')}"\n\n$text';

    // Generate or get 1-on-1 chatId
    final participants = [currentUserId, widget.statusGroup.userId]..sort();
    final chatId = '${participants[0]}_${participants[1]}';

    await sendMessage(
      chatId: chatId,
      content: replyContent,
      type: 'text',
      replyTo: {
        'messageId': currentItem.id,
        'senderName': widget.statusGroup.userName,
        'text': currentItem.type == 'text' ? currentItem.content : (currentItem.caption ?? 'Photo'),
      },
    );

    _replyController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply sent!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
      _resume();
    }
  }

  TextStyle _getTextStatusStyle(StatusItem item) {
    TextStyle base = const TextStyle(
      fontSize: 26,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    if (item.fontFamily == 'Courier') {
      return GoogleFonts.courierPrime(textStyle: base);
    } else if (item.fontFamily == 'Serif') {
      return GoogleFonts.playfairDisplay(textStyle: base);
    } else if (item.fontFamily == 'Cursive') {
      return GoogleFonts.pacifico(textStyle: base);
    }
    return GoogleFonts.inter(textStyle: base);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthenticatedState ? authState.user.uid : '';
    final currentUserName = authState is AuthenticatedState ? authState.user.displayName : 'User';
    final isMyStatus = widget.statusGroup.userId == currentUserId;
    final currentItem = _items[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _onPrevious();
          } else {
            _onNext();
          }
        },
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
            Navigator.pop(context); // Swipe down to exit
          } else if (isMyStatus && details.primaryVelocity != null && details.primaryVelocity! < -100) {
            _openViewersSheet(currentItem); // Swipe up to see viewers
          }
        },
        child: Stack(
          children: [
            // Status Content Canvas
            Positioned.fill(
              child: _buildStatusContent(currentItem),
            ),

            // Top Progress Bar & Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  children: [
                    // Segmented Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: List.generate(
                          _items.length,
                          (index) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: AnimatedBuilder(
                                animation: _animController,
                                builder: (context, child) {
                                  double val = 0.0;
                                  if (index < _currentIndex) {
                                    val = 1.0;
                                  } else if (index == _currentIndex) {
                                    val = _animController.value;
                                  }
                                  return LinearProgressIndicator(
                                    value: val,
                                    backgroundColor: Colors.white.withOpacity(0.3),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    minHeight: 2.5,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // User Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          CustomAvatar(
                            imageUrl: widget.statusGroup.userPhotoUrl,
                            name: widget.statusGroup.userName,
                            radius: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.statusGroup.userName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  timeago.format(currentItem.createdAt),
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Area
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: isMyStatus
                    ? GestureDetector(
                        onTap: () => _openViewersSheet(currentItem),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: Colors.transparent,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.visibility_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${currentItem.viewers.length}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                onTap: _pause,
                                onSubmitted: (_) => _sendReply(currentUserId, currentUserName),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Reply...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.5),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                              onPressed: () => _sendReply(currentUserId, currentUserName),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusItem item) {
    if (item.type == 'text') {
      final bgColor = item.backgroundColor != null ? Color(item.backgroundColor!) : AppColors.primary;
      return Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        alignment: Alignment.center,
        child: Text(
          item.content,
          style: _getTextStatusStyle(item),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.content,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
            ),
          ),
          if (item.caption != null && item.caption!.isNotEmpty)
            Positioned(
              bottom: 70,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.caption!,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }
  }
}
