// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucifax_lightchat/core/constants/app_colors.dart';
import 'package:lucifax_lightchat/core/theme/app_theme.dart';
import 'package:lucifax_lightchat/core/utils/phone_number_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Phone number normalizer converts to E.164 properly', () {
    expect(PhoneNumberFormatter.toE164('081234567890'), '+6281234567890');
    expect(PhoneNumberFormatter.toE164('6281234567890'), '+6281234567890');
    expect(PhoneNumberFormatter.toE164('+62 812-3456-7890'), '+6281234567890');
  });

  test('Dark Theme default configuration', () {
    final theme = AppTheme.darkTheme;
    expect(theme.brightness, equals(Brightness.dark));
    expect(theme.scaffoldBackgroundColor, equals(AppColors.background));
  });
}
