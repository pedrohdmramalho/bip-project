import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/mood_bloc.dart';
import '../widgets/mood_chart.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fond blanc pour faire ressortir la carte
      appBar: AppBar(
        title: const Text("Mood Analytics", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Mood Progress", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 24),
            BlocBuilder<MoodBloc, MoodState>(
              builder: (context, state) {
                // On passe les scores réels du BLoC
                return MoodChart(scores: state.weeklyScores);
              },
            ),
            const SizedBox(height: 20),
            // Tu peux ajouter ici des détails textuels sur la semaine
          ],
        ),
      ),
    );
  }
}