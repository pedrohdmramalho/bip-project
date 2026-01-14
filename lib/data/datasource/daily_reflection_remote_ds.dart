import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood_selector.dart';

class DailyReflectionRemoteDataSource {
  final FirebaseFirestore firestore;

  DailyReflectionRemoteDataSource(this.firestore);

  Future<void> saveReflection({
    required Mood mood,
    required String text,
  }) {
    return firestore.collection('daily_reflections').add({
      'mood': mood.name,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
