class MeditationExercise {
  final String id;
  final String title;
  final String description;
  final int durationInMinutes;
  final String category;
  final String audioUrl;
  final String imageUrl;

  MeditationExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.durationInMinutes,
    required this.category,
    required this.audioUrl,
    required this.imageUrl,
  });

  factory MeditationExercise.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return MeditationExercise(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      durationInMinutes: data['durationInMinutes'] ?? 0,
      category: data['category'] ?? 'General',
      audioUrl: data['audioUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'durationInMinutes': durationInMinutes,
      'category': category,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
    };
  }
}
