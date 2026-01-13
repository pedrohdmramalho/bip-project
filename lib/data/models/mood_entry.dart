class MoodEntry {
  final String id;
  final DateTime date;
  final String label;

  MoodEntry({required this.id, required this.date, required this.label});

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'label': label,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map, String id) {
    return MoodEntry(
      id: id,
      date: DateTime.parse(map['date']),
      label: map['label'],
    );
  }
}