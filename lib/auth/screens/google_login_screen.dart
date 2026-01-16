import 'package:flutter/material.dart';
import 'package:starteu/auth/services/auth_service.dart';

class GoogleLoginScreen extends StatefulWidget {
  final AuthService authService;

  const GoogleLoginScreen({super.key, required this.authService});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final bool result = await widget.authService.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (!result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              _buildHeader(),
              const Spacer(flex: 1),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.self_improvement_rounded,
                  size: 100,
                  color: Colors.deepPurple[200],
                ),
              ),
              const Spacer(flex: 2),
              _buildLoginButton(),
              const SizedBox(height: 24),
              const Text(
                'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Icon(Icons.spa_rounded, size: 60, color: Colors.deepPurple),
        SizedBox(height: 16),
        Text(
          "Mindful Journey",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Find your peace, one day at a time.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, color: Colors.deepPurple),
                  SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
