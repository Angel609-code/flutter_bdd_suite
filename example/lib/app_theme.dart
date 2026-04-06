import 'package:flutter/material.dart';

/// Global notifier that drives the app-level [ThemeMode].
///
/// Any screen can read the current value or update it:
/// ```dart
/// themeNotifier.value = ThemeMode.dark;
/// ```
final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);
