import 'package:flutter/material.dart';
import 'package:starteu/auth/services/auth_service.dart';

class GoogleLoginScreen extends StatefulWidget {
  final AuthService authService;

  const GoogleLoginScreen({super.key, required this.authService});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  Future<void> _handleGoogleSignIn() async {
    final bool result = await widget.authService.signInWithGoogle();

    if (!mounted) return;

    if (!result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Continue with Google'),
          onPressed: _handleGoogleSignIn,
        ),
      ),
    );
  }
}
