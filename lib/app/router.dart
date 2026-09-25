import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/otp_verification_page.dart';
import '../features/auth/presentation/pages/phone_input_page.dart';
import '../features/auth/presentation/pages/profile_setup_page.dart';
import '../features/auth/presentation/pages/qr_display_page.dart';
import '../features/auth/presentation/pages/qr_scanner_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/chat/domain/entities/chat_entity.dart';
import '../features/chat/presentation/pages/chat_room_page.dart';
import '../features/chat/presentation/pages/create_group_page.dart';
import '../features/chat/presentation/pages/home_page.dart';
import '../features/contacts/presentation/pages/contact_profile_page.dart';
import '../features/contacts/presentation/pages/contacts_page.dart';
import '../features/music/presentation/pages/full_music_player_page.dart';
import '../features/music/presentation/pages/music_browse_page.dart';
import '../features/profile/presentation/pages/appearance_settings_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/status/domain/entities/user_status_group.dart';
import '../features/status/presentation/pages/create_media_status_page.dart';
import '../features/status/presentation/pages/create_text_status_page.dart';
import '../features/status/presentation/pages/status_viewer_page.dart';
import '../features/calls/domain/entities/call_entity.dart';
import '../features/calls/presentation/pages/call_page.dart';
import '../features/calls/presentation/pages/incoming_call_page.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: '/phone-input',
      builder: (context, state) => const PhoneInputPage(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OtpVerificationPage(
          verificationId: extra['verificationId'] ?? '',
          phoneNumber: extra['phoneNumber'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final chatId = state.pathParameters['id'] ?? '';
        final chat = state.extra as ChatEntity?;
        return ChatRoomPage(chatId: chatId, chat: chat);
      },
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const ContactsPage(),
    ),
    GoRoute(
      path: '/create-group',
      builder: (context, state) => const CreateGroupPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/appearance-settings',
      builder: (context, state) => const AppearanceSettingsPage(),
    ),
    GoRoute(
      path: '/qr-scanner',
      builder: (context, state) => const QrScannerPage(),
    ),
    GoRoute(
      path: '/web-login',
      builder: (context, state) => const QrDisplayPage(),
    ),
    GoRoute(
      path: '/status-viewer',
      builder: (context, state) {
        final group = state.extra as UserStatusGroup;
        return StatusViewerPage(statusGroup: group);
      },
    ),
    GoRoute(
      path: '/create-text-status',
      builder: (context, state) => const CreateTextStatusPage(),
    ),
    GoRoute(
      path: '/create-media-status',
      builder: (context, state) {
        final file = state.extra as File;
        return CreateMediaStatusPage(file: file);
      },
    ),
    GoRoute(
      path: '/music-browse',
      builder: (context, state) => const MusicBrowsePage(),
    ),
    GoRoute(
      path: '/music-player',
      builder: (context, state) => const FullMusicPlayerPage(),
    ),
    GoRoute(
      path: '/call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final call = extra['call'] as CallEntity;
        final isCaller = extra['isCaller'] as bool? ?? false;
        final currentUserId = extra['currentUserId'] as String? ?? '';
        return CallPage(
          call: call,
          isCaller: isCaller,
          currentUserId: currentUserId,
        );
      },
    ),
    GoRoute(
      path: '/incoming-call',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final call = extra['call'] as CallEntity;
        final currentUserId = extra['currentUserId'] as String? ?? '';
        return IncomingCallPage(
          call: call,
          currentUserId: currentUserId,
        );
      },
    ),
    GoRoute(
      path: '/contact-profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ContactProfilePage(
          userId: extra['userId'] ?? '',
          displayName: extra['displayName'] ?? 'Contact',
          photoUrl: extra['photoUrl'],
          phoneNumber: extra['phoneNumber'] ?? '',
          about: extra['about'] ?? 'Available',
        );
      },
    ),
  ],
);

