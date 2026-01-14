import '../data/models/mood_selector.dart';

enum DailyReflectionStatus { initial, loading, success, failure }

class DailyReflectionState {
  final Mood? mood;
  final String text;
  final DailyReflectionStatus status;
  final String? errorMessage;

  const DailyReflectionState({
    this.mood,
    this.text = '',
    this.status = DailyReflectionStatus.initial,
    this.errorMessage,
  });

  DailyReflectionState copyWith({
    Mood? mood,
    String? text,
    DailyReflectionStatus? status,
    String? errorMessage,
  }) {
    return DailyReflectionState(
      mood: mood ?? this.mood,
      text: text ?? this.text,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}
