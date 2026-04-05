import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'files_screen.dart';
import 'dialogs_screen.dart';

void main() {
  runApp(const BddExampleApp());
}

class BddExampleApp extends StatelessWidget {
  const BddExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamSync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
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
  }
}
