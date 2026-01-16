import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'bloc/mood_bloc.dart';
import 'data/repositories/mood_repository.dart';
import 'data/repositories/meditation_repository.dart';
import 'pages/main_navigation_page.dart';
import 'pages/meditation_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final meditationRepo = MeditationRepository();
  runApp(MyApp(meditationRepo: meditationRepo));
}

class MyApp extends StatelessWidget {
  final MeditationRepository meditationRepo; 

  const MyApp({super.key, required this.meditationRepo});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MoodBloc>(
          create: (context) => MoodBloc(
            repository: MoodRepository(),
          )..add(LoadMoodStatus()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
        home: const MainNavigationPage(),
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