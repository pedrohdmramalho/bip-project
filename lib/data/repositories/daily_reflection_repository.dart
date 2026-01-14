import '../datasource/daily_reflection_remote_ds.dart';
import '../models/mood_selector.dart';

class DailyReflectionRepository {
  final DailyReflectionRemoteDataSource ds;

  DailyReflectionRepository(this.ds);

  Future<void> saveReflection({
    required Mood mood,
    required String text,
  }) {
    return ds.saveReflection(mood: mood, text: text);
  }
}