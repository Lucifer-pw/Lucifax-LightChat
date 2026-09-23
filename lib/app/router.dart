import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/otp_verification_page.dart';
import '../features/auth/presentation/pages/phone_input_page.dart';
import '../features/auth/presentation/pages/profile_setup_page.dart';
import '../features/auth/presentation/pages/qr_scanner_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/chat/domain/entities/chat_entity.dart';
import '../features/chat/presentation/pages/chat_room_page.dart';
import '../features/chat/presentation/pages/create_group_page.dart';
import '../features/chat/presentation/pages/home_page.dart';
import '../features/contacts/presentation/pages/contacts_page.dart';
import '../features/profile/presentation/pages/appearance_settings_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';

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
  ],
);
