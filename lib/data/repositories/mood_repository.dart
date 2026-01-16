import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MoodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = "user_123";

  Future<void> saveMood(String moodLabel) async {
    final String todayDocId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .doc(todayDocId)
        .set({
          'label': moodLabel,
          'date': todayDocId,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<String?> getMoodForDate(String dateId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .doc(dateId)
        .get();

    if (doc.exists) {
      return doc.data()?['label'] as String?;
    }
    return null;
  }

  Future<List<String>> getMoodHistory() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .get();

    return snapshot.docs.map((doc) => doc['date'] as String).toList();
  }

  Future<Map<String, String>> getMoodLabelsForRange(
    List<String> dateIds,
  ) async {
    Map<String, String> results = {};

    for (String dateId in dateIds) {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .doc(dateId)
          .get();

      if (doc.exists) {
        results[dateId] = doc.data()?['label'] as String;
      }
    }
    return results;
  }
}
