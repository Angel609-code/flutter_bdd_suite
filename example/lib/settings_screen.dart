import 'package:flutter/material.dart';
import 'app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = themeNotifier.value == ThemeMode.dark;
  }

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const Key('notifications_switch'),
                      title: const Text('Enable Notifications'),
                      secondary: const Icon(Icons.notifications),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      key: const Key('dark_mode_checkbox'),
                      title: const Text('Enable Dark Mode'),
                      secondary: const Icon(Icons.dark_mode),
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        final enabled = value ?? false;
                        setState(() {
                          _darkModeEnabled = enabled;
                        });
                        themeNotifier.value =
                            enabled ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Text(
                        _darkModeEnabled
                            ? 'Dark Mode: Enabled'
                            : 'Dark Mode: Disabled',
                        key: const Key('theme_mode_indicator'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Volume', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      Text('Current Volume: ${_volume.round()}', key: const Key('volume_label')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const Key('view_terms_button'),
                icon: const Icon(Icons.description),
                label: const Text('View Terms & Conditions'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: _showTermsDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
