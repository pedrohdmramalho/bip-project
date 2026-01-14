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
  final List<double> weeklyScores; 
  final bool isLoading;

  MoodState({
    this.todayMood, 
    this.streakCount = 0, 
    this.weeklyScores = const [], 
    this.isLoading = false
  });

  MoodState copyWith({
    String? todayMood, 
    int? streakCount, 
    List<double>? weeklyScores, 
    bool? isLoading
  }) {
    return MoodState(
      todayMood: todayMood ?? this.todayMood,
      streakCount: streakCount ?? this.streakCount,
      weeklyScores: weeklyScores ?? this.weeklyScores,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// --- BLOC ---
class MoodBloc extends Bloc<MoodEvent, MoodState> {
  final MoodRepository repository;

  MoodBloc({required this.repository}) : super(MoodState(isLoading: true)) {
    
    // Événement de chargement initial
    on<LoadMoodStatus>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      try {
        final history = await repository.getMoodHistory();
        final String todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final String? savedMoodToday = await repository.getMoodForDate(todayId);
        
        // Calcul des scores pour le graphique
        final List<double> scores = await _fetchWeeklyScores();
        
        emit(MoodState(
          todayMood: savedMoodToday, 
          streakCount: _calculateStreak(history),
          weeklyScores: scores,
          isLoading: false,
        ));
      } catch (e) {
        emit(MoodState(isLoading: false, streakCount: 0));
      }
    });

    // Événement lors du clic sur un Mood
    on<SelectMood>((event, emit) async {
      await repository.saveMood(event.moodLabel);
      
      final history = await repository.getMoodHistory();
      // On rafraîchit aussi les scores du graphique immédiatement
      final List<double> scores = await _fetchWeeklyScores();
      
      emit(state.copyWith(
        todayMood: event.moodLabel,
        streakCount: _calculateStreak(history),
        weeklyScores: scores,
      ));
    });
  }

  // --- FONCTIONS PRIVÉES DE LOGIQUE ---

  // Transforme les labels Firestore en chiffres pour le graphique
  double _moodToScore(String? label) {
    switch (label) {
      case 'Great': return 5.0;
      case 'Good': return 4.0;
      case 'Okay': return 3.0;
      case 'Sad': return 2.0;
      case 'Awful': return 1.0;
      default: return 0.0; // 0 si pas de donnée pour ce jour
    }
  }

  // Récupère les données des 7 derniers jours
  Future<List<double>> _fetchWeeklyScores() async {
    final List<String> last7Days = List.generate(7, (i) {
      // Génère les dates de J-6 jusqu'à aujourd'hui
      return DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(Duration(days: 6 - i))
      );
    });

    final moodMap = await repository.getMoodLabelsForRange(last7Days);
    return last7Days.map((date) => _moodToScore(moodMap[date])).toList();
  }

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
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}