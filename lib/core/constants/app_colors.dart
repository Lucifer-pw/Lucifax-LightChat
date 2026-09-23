// App Colors - Dark theme first as requested
import 'package:flutter/material.dart';

class AppColors {
  // Primary Dark Palette (WhatsApp Dark style)
  static const Color background = Color(0xFF0B141A);
  static const Color surface = Color(0xFF111B21);
  static const Color surfaceLight = Color(0xFF202C33);
  static const Color appBar = Color(0xFF111B21);
  static const Color bottomNav = Color(0xFF111B21);
  static const Color card = Color(0xFF182229);

  // Accent & Brand Colors
  static const Color primary = Color(0xFF00A884);
  static const Color primaryDark = Color(0xFF008069);
  static const Color primaryLight = Color(0xFF25D366);
  static const Color secondary = Color(0xFF53BDEB);

  // Chat Bubbles
  static const Color bubbleSent = Color(0xFF005C4B);
  static const Color bubbleReceived = Color(0xFF202C33);
  static const Color bubbleSentText = Color(0xFFE9EDEF);
  static const Color bubbleReceivedText = Color(0xFFE9EDEF);

  // Message Status Checkmarks
  static const Color statusSent = Color(0xFF8696A0);
  static const Color statusDelivered = Color(0xFF8696A0);
  static const Color statusRead = Color(0xFF53BDEB); // Cyan Blue

  // Text Colors
  static const Color textPrimary = Color(0xFFE9EDEF);
  static const Color textSecondary = Color(0xFF8696A0);
  static const Color textMuted = Color(0xFF667781);
  static const Color textLink = Color(0xFF53BDEB);

  // Dividers & Borders
  static const Color divider = Color(0xFF222D34);
  static const Color border = Color(0xFF2A3942);

  // Indicators & Badges
  static const Color unreadBadge = Color(0xFF00A884);
  static const Color onlineIndicator = Color(0xFF00A884);
  static const Color error = Color(0xFFEA4335);
  static const Color warning = Color(0xFFFBBC05);
  static const Color success = Color(0xFF34A853);

  // Input & Buttons
  static const Color inputBackground = Color(0xFF2A3942);
  static const Color iconColor = Color(0xFF8696A0);
  static const Color iconSelected = Color(0xFF00A884);
}
