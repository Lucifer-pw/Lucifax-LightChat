import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/status_bloc.dart';
import '../bloc/status_event.dart';

class CreateMediaStatusPage extends StatefulWidget {
  final File file;
  final String type; // 'image' or 'video'

  const CreateMediaStatusPage({
    super.key,
    required this.file,
    this.type = 'image',
  });

  @override
  State<CreateMediaStatusPage> createState() => _CreateMediaStatusPageState();
}

class _CreateMediaStatusPageState extends State<CreateMediaStatusPage> {
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _submitMediaStatus() {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      context.read<StatusBloc>().add(
            AddMediaStatusEvent(
              file: widget.file,
              type: widget.type,
              caption: _captionController.text.trim().isNotEmpty
                  ? _captionController.text.trim()
                  : null,
              userId: authState.user.uid,
              userName: authState.user.displayName.isNotEmpty
                  ? authState.user.displayName
                  : 'User',
              userPhotoUrl: authState.user.photoUrl,
            ),
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Media Preview
          Center(
            child: widget.type == 'image'
                ? Image.file(widget.file, fit: BoxFit.contain)
                : const Icon(Icons.video_file_rounded, size: 100, color: Colors.white),
          ),

          // Caption & Send Bar at Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black.withOpacity(0.6),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _captionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          filled: true,
                          fillColor: AppColors.surface.withOpacity(0.8),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    AppSizes.hSpace12,
                    FloatingActionButton.small(
                      backgroundColor: AppColors.primary,
                      onPressed: _isUploading ? null : _submitMediaStatus,
                      child: _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
