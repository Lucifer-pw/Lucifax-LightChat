import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_colors.dart';

class AppearanceState extends Equatable {
  final Color sentBubbleColor;
  final String bubbleStyle; // 'rounded', 'sharp'
  final String wallpaperType; // 'default', 'solid_dark', 'solid_navy', 'solid_forest', 'custom'
  final String? customWallpaperPath;

  const AppearanceState({
    this.sentBubbleColor = AppColors.bubbleSent,
    this.bubbleStyle = 'rounded',
    this.wallpaperType = 'default',
    this.customWallpaperPath,
  });

  AppearanceState copyWith({
    Color? sentBubbleColor,
    String? bubbleStyle,
    String? wallpaperType,
    String? customWallpaperPath,
  }) {
    return AppearanceState(
      sentBubbleColor: sentBubbleColor ?? this.sentBubbleColor,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      wallpaperType: wallpaperType ?? this.wallpaperType,
      customWallpaperPath: customWallpaperPath ?? this.customWallpaperPath,
    );
  }

  @override
  List<Object?> get props => [
        sentBubbleColor,
        bubbleStyle,
        wallpaperType,
        customWallpaperPath,
      ];
}

class AppearanceCubit extends Cubit<AppearanceState> {
  static const String boxName = 'appearance_settings';
  Box? _box;

  AppearanceCubit() : super(const AppearanceState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _box = await Hive.openBox(boxName);
      final colorVal = _box?.get('sentBubbleColor') as int?;
      final style = _box?.get('bubbleStyle') as String?;
      final wallpaper = _box?.get('wallpaperType') as String?;
      final customPath = _box?.get('customWallpaperPath') as String?;

      emit(state.copyWith(
        sentBubbleColor: colorVal != null ? Color(colorVal) : AppColors.bubbleSent,
        bubbleStyle: style ?? 'rounded',
        wallpaperType: wallpaper ?? 'default',
        customWallpaperPath: customPath,
      ));
    } catch (_) {}
  }

  Future<void> setSentBubbleColor(Color color) async {
    emit(state.copyWith(sentBubbleColor: color));
    await _box?.put('sentBubbleColor', color.value);
  }

  Future<void> setBubbleStyle(String style) async {
    emit(state.copyWith(bubbleStyle: style));
    await _box?.put('bubbleStyle', style);
  }

  Future<void> setWallpaper(String type, {String? customPath}) async {
    emit(state.copyWith(
      wallpaperType: type,
      customWallpaperPath: customPath,
    ));
    await _box?.put('wallpaperType', type);
    if (customPath != null) {
      await _box?.put('customWallpaperPath', customPath);
    }
  }
}
