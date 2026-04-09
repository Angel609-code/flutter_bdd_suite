import 'package:flutter/material.dart';

/// A screen to demonstrate various dialog and interaction types.
class DialogsScreen extends StatelessWidget {
  const DialogsScreen({super.key});

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert'),
        content: const Text('This is a simple alert dialog.'),
        actions: [
          TextButton(
            key: const Key('alert_ok_button'),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: const Text('Are you sure you want to proceed?'),
        actions: [
          TextButton(
            key: const Key('confirm_cancel_button'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_yes_button'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        height: 200,
        child: Column(
          children: [
            const Text('Bottom Sheet Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              key: const Key('bottom_sheet_option_1'),
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              key: const Key('bottom_sheet_option_2'),
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This is a snackbar message!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactions & Dialogs')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  key: const Key('show_alert_button'),
                  onPressed: () => _showAlertDialog(context),
                  child: const Text('Show Alert Dialog'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('show_confirm_button'),
                  onPressed: () => _showConfirmationDialog(context),
                  child: const Text('Show Confirmation Dialog'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('show_bottom_sheet_button'),
                  onPressed: () => _showBottomSheet(context),
                  child: const Text('Show Bottom Sheet'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('show_snackbar_button'),
                  onPressed: () => _showSnackbar(context),
                  child: const Text('Show Snackbar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
