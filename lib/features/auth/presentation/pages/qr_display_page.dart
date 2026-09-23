import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';

class QrDisplayPage extends StatefulWidget {
  const QrDisplayPage({super.key});

  @override
  State<QrDisplayPage> createState() => _QrDisplayPageState();
}

class _QrDisplayPageState extends State<QrDisplayPage> {
  String? _sessionId;
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  Timer? _countdownTimer;
  int _secondsLeft = 60;
  bool _isExpired = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _generateAndListenSession();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateAndListenSession() async {
    _sessionSubscription?.cancel();
    _countdownTimer?.cancel();

    final newSessionId = const Uuid().v4();
    setState(() {
      _sessionId = newSessionId;
      _secondsLeft = 60;
      _isExpired = false;
      _isAuthenticated = false;
    });

    final firestore = FirebaseFirestore.instance;
    final sessionRef = firestore.collection('webSessions').doc(newSessionId);

    try {
      await sessionRef.set({
        'sessionId': newSessionId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(seconds: 60))),
      });

      // Listen for mobile scan confirmation
      _sessionSubscription = sessionRef.snapshots().listen((doc) {
        if (!doc.exists) return;
        final data = doc.data();
        if (data?['status'] == 'authenticated' && data?['userId'] != null) {
          setState(() => _isAuthenticated = true);
          _sessionSubscription?.cancel();
          _countdownTimer?.cancel();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Linked successfully! Logging into LightChatWeb...'),
              backgroundColor: AppColors.success,
            ),
          );

          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.go('/home');
            }
          });
        }
      });

      // Countdown timer
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft <= 1) {
          timer.cancel();
          _sessionSubscription?.cancel();
          setState(() => _isExpired = true);
        } else {
          setState(() => _secondsLeft--);
        }
      });
    } catch (e) {
      // Offline fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(AppSizes.p32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.r16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left side: Instructions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 32),
                          const SizedBox(width: 12),
                          Text('LightChatWeb', style: AppTextStyles.heading2),
                        ],
                      ),
                      AppSizes.vSpace24,
                      Text(
                        'To use LightChat on your computer:',
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      AppSizes.vSpace16,
                      _buildStep('1', 'Open LightChat on your phone'),
                      AppSizes.vSpace12,
                      _buildStep('2', 'Tap Menu (⋮) or Settings and select Linked Devices'),
                      AppSizes.vSpace12,
                      _buildStep('3', 'Point your phone to this screen to capture the code'),
                    ],
                  ),
                ),
                const SizedBox(width: 48),

                // Right side: QR Code
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _sessionId == null
                          ? const SizedBox(
                              width: 200,
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                QrImageView(
                                  data: _sessionId!,
                                  version: QrVersions.auto,
                                  size: 200,
                                ),
                                if (_isExpired)
                                  Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.white.withOpacity(0.9),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.refresh_rounded, size: 40, color: AppColors.primary),
                                        const SizedBox(height: 8),
                                        Text(
                                          'QR Code Expired',
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: _generateAndListenSession,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          child: const Text('RELOAD QR', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_isAuthenticated)
                                  Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.white.withOpacity(0.9),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 50, color: AppColors.success),
                                        SizedBox(height: 8),
                                        Text('Authenticated!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    AppSizes.vSpace16,
                    if (!_isExpired && !_isAuthenticated)
                      Text(
                        'Expires in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
