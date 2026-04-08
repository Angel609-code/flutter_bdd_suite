import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'files_screen.dart';
import 'dialogs_screen.dart';

void main() {
  runApp(const BddExampleApp());
}

/// The root widget of the BDD example application.
class BddExampleApp extends StatelessWidget {
  const BddExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'TeamSync',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeMode,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/files': (context) => const FilesScreen(),
            '/dialogs': (context) => const DialogsScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
