import '../data/models/mood_selector.dart';

abstract class DailyReflectionEvent {}

class MoodChanged extends DailyReflectionEvent {
  final Mood mood;
  MoodChanged(this.mood);
}

class TextChanged extends DailyReflectionEvent {
  final String text;
  TextChanged(this.text);
}

class SubmitPressed extends DailyReflectionEvent {}
