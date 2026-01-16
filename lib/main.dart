import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Services & Auth
import 'auth/services/auth_service.dart';
import 'auth/screens/google_login_screen.dart';
import 'data/models/user_model.dart';

// Repositories
import 'data/repositories/mood_repository.dart';
import 'data/repositories/meditation_repository.dart';

// BLoC
import 'bloc/mood_bloc.dart';

// Pages
import 'pages/main_navigation_page.dart';
import 'pages/meditation_page.dart';
import 'services/notification_service.dart';

// Config
import 'config/theme_mode_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authService = FirebaseAuthService();
  final meditationRepo = MeditationRepository();
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.scheduleDailyMeditationReminder();

  runApp(MyApp(
    authService: authService,
    meditationRepo: meditationRepo,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final MeditationRepository meditationRepo;

  const MyApp({
    super.key, 
    required this.authService, 
    required this.meditationRepo,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeModeManager(),
      child: Consumer<ThemeModeManager>(
        builder: (context, themeModeManager, _) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<MoodBloc>(
                create: (context) =>
                    MoodBloc(repository: MoodRepository())..add(LoadMoodStatus()),
              ),
            ],
            child: MaterialApp(
              title: 'Balance',
              debugShowCheckedModeBanner: false,
              themeMode: themeModeManager.themeMode,
              theme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: Colors.deepPurple,
                brightness: Brightness.dark,
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