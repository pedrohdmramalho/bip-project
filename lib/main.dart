import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'auth/services/auth_service.dart';
import 'data/models/user_model.dart';
import 'auth/screens/google_login_screen.dart';
import 'auth/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final authService = FirebaseAuthService();
  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mental Health App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthGate(authService: authService),
    );
  }
}

class AuthGate extends StatelessWidget {
  final AuthService authService;

  const AuthGate({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen(authService: authService);
        }

        return GoogleLoginScreen(authService: authService);
      },
    );
  }
}
