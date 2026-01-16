import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/meditation_exercise.dart';

class MeditationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MeditationExercise>> fetchExercises() async {
    try {
      final snapshot = await _firestore.collection('meditations').get();
      return snapshot.docs.map((doc) => 
        MeditationExercise.fromFirestore(doc.data(), doc.id)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCompletedSession({
    required String userId,
    required String title,
    required String duration, 
  }) async {
    try {
      DateTime now = DateTime.now();
      String dateString = DateFormat('yyyy-MM-dd').format(now);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('meditation_history')
          .add({ 
        'title': title,
        'duration': duration, 
        'date': dateString,   
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Erreur Firestore: $e");
    }
  }

  Future<Map<String, int>> getMeditationCounts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meditation_history')
          .get();

      Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        String? date = doc.data()['date']; 
        if (date != null) {
          counts[date] = (counts[date] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e) {
      return {};
    }
  }
}