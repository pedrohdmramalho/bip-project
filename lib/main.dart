import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'auth/services/auth_service.dart';
import 'data/models/user_model.dart';
import 'auth/screens/google_login_screen.dart';

// Import your navigation page
import 'pages/main_navigation_page.dart';

// Import Bloc/Repo for the Mental Health features
import 'bloc/mood_bloc.dart';
import 'data/repositories/mood_repository.dart';
import 'pages/meditation_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = FirebaseAuthService();
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.scheduleDailyMeditationReminder();

  runApp(MyApp(authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MoodBloc>(
          create: (context) =>
              MoodBloc(repository: MoodRepository())..add(LoadMoodStatus()),
        ),
      ],
      child: MaterialApp(
        title: 'Mental Health App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepPurple,
        ),
        home: AuthGate(authService: authService),
        routes: {
          '/meditation': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return MeditationPage(
              selectedMusic: args,
            );
          },
        },
      ),
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
          return MainNavigationPage(authService: authService);
        }
        return GoogleLoginScreen(authService: authService);
      },
    );
  }
}
