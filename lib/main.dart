import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase avec les options de la plateforme (Version distante)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialisation des services et repositories
  final authService = FirebaseAuthService();
  final meditationRepo = MeditationRepository();

  // On lance l'app en passant les deux dépendances
  runApp(MyApp(
    authService: authService,
    meditationRepo: meditationRepo,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final MeditationRepository meditationRepo;

  // Constructeur unique fusionné
  const MyApp({
    super.key, 
    required this.authService, 
    required this.meditationRepo,
  });

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
        // AuthGate gère la redirection automatique
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