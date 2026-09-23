import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/status_bloc.dart';
import '../bloc/status_event.dart';

class CreateTextStatusPage extends StatefulWidget {
  const CreateTextStatusPage({super.key});

  @override
  State<CreateTextStatusPage> createState() => _CreateTextStatusPageState();
}

class _CreateTextStatusPageState extends State<CreateTextStatusPage> {
  final TextEditingController _textController = TextEditingController();

  final List<Color> _backgroundColors = [
    const Color(0xFF005C4B), // WhatsApp Dark Emerald
    const Color(0xFF1E3A8A), // Midnight Blue
    const Color(0xFF581C87), // Deep Purple
    const Color(0xFF9F1239), // Crimson
    const Color(0xFFB45309), // Amber Orange
    const Color(0xFF0F766E), // Teal
    const Color(0xFF1F2937), // Dark Slate
  ];

  int _currentColorIndex = 0;
  int _currentFontIndex = 0;

  final List<String> _fontFamilies = ['Inter', 'Courier', 'Serif', 'Cursive'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  TextStyle _getSelectedTextStyle() {
    final fontName = _fontFamilies[_currentFontIndex];
    TextStyle base = const TextStyle(
      fontSize: 28,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    if (fontName == 'Courier') {
      return GoogleFonts.courierPrime(textStyle: base);
    } else if (fontName == 'Serif') {
      return GoogleFonts.playfairDisplay(textStyle: base);
    } else if (fontName == 'Cursive') {
      return GoogleFonts.pacifico(textStyle: base);
    }
    return GoogleFonts.inter(textStyle: base);
  }

  void _cycleColor() {
    setState(() {
      _currentColorIndex = (_currentColorIndex + 1) % _backgroundColors.length;
    });
  }

  void _cycleFont() {
    setState(() {
      _currentFontIndex = (_currentFontIndex + 1) % _fontFamilies.length;
    });
  }

  void _submitStatus() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      context.read<StatusBloc>().add(
            AddTextStatusEvent(
              text: text,
              backgroundColor: _backgroundColors[_currentColorIndex].value,
              fontFamily: _fontFamilies[_currentFontIndex],
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
    final currentColor = _backgroundColors[_currentColorIndex];

    return Scaffold(
      backgroundColor: currentColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 28),
            tooltip: 'Change Font',
            onPressed: _cycleFont,
          ),
          IconButton(
            icon: const Icon(Icons.palette_rounded, color: Colors.white, size: 28),
            tooltip: 'Change Color',
            onPressed: _cycleColor,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: TextField(
            controller: _textController,
            style: _getSelectedTextStyle(),
            textAlign: TextAlign.center,
            maxLines: null,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Type a status...',
              hintStyle: _getSelectedTextStyle().copyWith(
                color: Colors.white.withOpacity(0.5),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _submitStatus,
        child: const Icon(Icons.send_rounded, color: Colors.white),
      ),
    );
  }
}
