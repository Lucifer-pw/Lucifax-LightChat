import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  static const MethodChannel _channel = MethodChannel('com.lucifax.lucifax_lightchat/pip');

  /// Requests Android to enter Picture-in-Picture mode
  static Future<bool> enterPip() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _channel.invokeMethod<bool>('enterPip');
      return result ?? false;
    } catch (e) {
      debugPrint('[PipService] enterPip error: $e');
      return false;
    }
  }

  /// Inform native Android whether a call is currently active
  /// (used for automatic PiP on user leave / home button)
  static Future<void> setInCall(bool inCall) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('setInCall', {'inCall': inCall});
    } catch (e) {
      debugPrint('[PipService] setInCall error: $e');
    }
  }

  /// Checks if Picture-in-Picture is supported on this device
  static Future<bool> isPipSupported() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isPipSupported');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
