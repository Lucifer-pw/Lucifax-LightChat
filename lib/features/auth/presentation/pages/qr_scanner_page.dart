import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isScanned) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        final sessionId = barcode.rawValue!;

        final authState = context.read<AuthBloc>().state;
        if (authState is! AuthenticatedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login on mobile first'), backgroundColor: AppColors.error),
          );
          Navigator.pop(context);
          return;
        }

        try {
          final firestore = FirebaseFirestore.instance;

          // 1. Authenticate web session
          await firestore.collection('webSessions').doc(sessionId).update({
            'status': 'authenticated',
            'userId': authState.user.uid,
            'authenticatedAt': FieldValue.serverTimestamp(),
          });

          // 2. Track in user's linked sessions
          await firestore
              .collection('userWebSessions')
              .doc(authState.user.uid)
              .collection('sessions')
              .doc(sessionId)
              .set({
            'sessionId': sessionId,
            'isActive': true,
            'connectedAt': FieldValue.serverTimestamp(),
            'lastActiveAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Linked successfully to LightChatWeb! 🎉'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to link device: $e'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isScanned = false);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(AppSizes.r16),
            ),
          ),
          Positioned(
            bottom: 48,
            child: Column(
              children: [
                Text(
                  'Point camera at LightChatWeb QR Code',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
                AppSizes.vSpace8,
                Text(
                  'Open LightChatWeb on your browser to scan',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
