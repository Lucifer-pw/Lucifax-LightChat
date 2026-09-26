import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

enum AudioOutputRoute {
  speaker,
  earpiece,
  bluetooth,
}

class AudioRouteService {
  static const MethodChannel _channel = MethodChannel('com.lucifax.lucifax_lightchat/audio');

  static Future<bool> setAudioRoute(AudioOutputRoute route) async {
    try {
      final routeName = route.name; // 'speaker', 'earpiece', 'bluetooth'

      // 1. Sync with Flutter WebRTC helper
      await Helper.ensureAudioSession();
      if (route == AudioOutputRoute.speaker) {
        await Helper.setSpeakerphoneOn(true);
      } else if (route == AudioOutputRoute.earpiece) {
        await Helper.setSpeakerphoneOn(false);
      } else if (route == AudioOutputRoute.bluetooth) {
        await Helper.setSpeakerphoneOn(false);
        await Helper.setSpeakerphoneOnButPreferBluetooth();
      }

      // 2. Sync with Native Android AudioManager
      final res = await _channel.invokeMethod<bool>('setAudioRoute', {'route': routeName});
      return res ?? true;
    } catch (e) {
      debugPrint('[AudioRouteService] Error setting audio route to $route: $e');
      return false;
    }
  }

  static Future<List<AudioOutputRoute>> getAvailableDevices() async {
    try {
      final res = await _channel.invokeListMethod<String>('getAvailableAudioDevices');
      if (res != null) {
        return res.map((name) {
          switch (name) {
            case 'speaker':
              return AudioOutputRoute.speaker;
            case 'bluetooth':
              return AudioOutputRoute.bluetooth;
            case 'earpiece':
            default:
              return AudioOutputRoute.earpiece;
          }
        }).toList();
      }
    } catch (e) {
      debugPrint('[AudioRouteService] Error getting available devices: $e');
    }
    return [AudioOutputRoute.speaker, AudioOutputRoute.earpiece];
  }
}
