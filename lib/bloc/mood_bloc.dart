import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../data/repositories/mood_repository.dart';

// --- EVENTS ---
abstract class MoodEvent {}
class LoadMoodStatus extends MoodEvent {}
class SelectMood extends MoodEvent {
  final String moodLabel;
  SelectMood(this.moodLabel);
}

// --- STATE ---
class MoodState {
  final String? todayMood;
  final int streakCount;
  final bool isLoading;

  MoodState({this.todayMood, this.streakCount = 0, this.isLoading = false});

  MoodState copyWith({String? todayMood, int? streakCount, bool? isLoading}) {
    return MoodState(
      todayMood: todayMood ?? this.todayMood,
      streakCount: streakCount ?? this.streakCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- BLOC ---
class MoodBloc extends Bloc<MoodEvent, MoodState> {
  final MoodRepository repository;

  MoodBloc({required this.repository}) : super(MoodState(isLoading: true)) {
    
    on<LoadMoodStatus>((event, emit) async {
      try {
        // Fetch both history (for streak) and today's label (for selection)
        final history = await repository.getMoodHistory();
        final String todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final String? savedMoodToday = await repository.getMoodForDate(todayId);
        
        emit(MoodState(
          todayMood: savedMoodToday, 
          streakCount: _calculateStreak(history),
          isLoading: false,
        ));
      } catch (e) {
        emit(MoodState(isLoading: false, streakCount: 0));
      }
    });

    on<SelectMood>((event, emit) async {
      // Save to Firebase
      await repository.saveMood(event.moodLabel);
      
      // Refresh history to ensure streak is accurate
      final history = await repository.getMoodHistory();
      
      emit(state.copyWith(
        todayMood: event.moodLabel,
        streakCount: _calculateStreak(history),
      ));
    });
  }

  // Algorithm to calculate the consecutive days streak
  int _calculateStreak(List<String> dates) {
    if (dates.isEmpty) return 0;
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      String formatted = DateFormat('yyyy-MM-dd').format(checkDate);
      if (dates.contains(formatted)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (i == 0) {
        // If nothing today, check yesterday. If nothing yesterday, streak is broken.
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}