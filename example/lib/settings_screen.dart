import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  double _volume = 50.0;
  final String _termsText = 'Please read our terms and conditions...';

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms & Conditions'),
          content: SingleChildScrollView(
            child: Text(
              _termsText,
              key: const Key('terms_text'),
            ),
          ),
          actions: [
            TextButton(
              key: const Key('close_terms'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            key: const Key('notifications_switch'),
            title: const Text('Enable Notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          CheckboxListTile(
            key: const Key('dark_mode_checkbox'),
            title: const Text('Enable Dark Mode'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value ?? false;
              });
            },
          ),
          const SizedBox(height: 16),
          const Text('Volume'),
          Slider(
            key: const Key('volume_slider'),
            min: 0,
            max: 100,
            value: _volume,
            onChanged: (value) {
              setState(() {
                _volume = value;
              });
            },
          ),
          Text('Volume: ${_volume.round()}', key: const Key('volume_label')),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('view_terms_button'),
            onPressed: _showTermsDialog,
            child: const Text('View Terms & Conditions'),
          ),
        ],
      ),
    );
  }
}
