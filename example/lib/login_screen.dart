import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  void _login() {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Username and password are required.';
      });
    } else if (username == 'admin' && password == 'password123') {
      setState(() {
        _errorMessage = '';
      });
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = 'Invalid credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage.isNotEmpty) ...[
              Text(
                _errorMessage,
                key: const Key('error_message'),
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              key: const Key('username_field'),
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('password_field'),
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('login_button'),
              onPressed: _login,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
