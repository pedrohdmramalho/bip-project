import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/bloc/daily_reflection_bloc.dart';
import '/bloc/daily_reflection_state.dart';
import '/bloc/daily_reflection_event.dart';

enum Mood { verySad, sad, neutral, happy, veryHappy }

class MoodSelector extends StatelessWidget {
  const MoodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyReflectionBloc, DailyReflectionState>(
      buildWhen: (p, c) => p.mood != c.mood,
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: Mood.values.map((mood) {
            final isSelected = state.mood == mood;

            return GestureDetector(
              onTap: () {
                context
                    .read<DailyReflectionBloc>()
                    .add(MoodChanged(mood));
              },
              child: Icon(
                _iconForMood(mood),
                size: 32,
                color: isSelected ? Colors.purple : Colors.grey,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _iconForMood(Mood mood) {
    switch (mood) {
      case Mood.verySad:
        return Icons.sentiment_very_dissatisfied_rounded;
      case Mood.sad:
        return Icons.sentiment_very_dissatisfied;
      case Mood.neutral:
        return Icons.sentiment_neutral;
      case Mood.happy:
        return Icons.sentiment_satisfied_rounded;
      case Mood.veryHappy:
        return Icons.sentiment_very_satisfied_sharp;
    }
  }
}