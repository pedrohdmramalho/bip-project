import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MoodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = "user_123"; // Replace with your actual Auth logic later

  // 1. Save the mood for a specific day
  Future<void> saveMood(String moodLabel) async {
    final String todayDocId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _firestore.collection('users').doc(userId).collection('moods').doc(todayDocId).set({
      'label': moodLabel,
      'date': todayDocId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 2. Fetch the label for a specific day (to keep selection on app restart)
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

  // 3. Fetch all recorded dates to calculate the streak
  Future<List<String>> getMoodHistory() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .get();
    
    // Returns a list of strings like ["2026-01-13", "2026-01-12"]
    return snapshot.docs.map((doc) => doc['date'] as String).toList();
  }
}