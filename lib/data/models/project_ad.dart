import 'package:equatable/equatable.dart';

class ProjectAd extends Equatable{
  final String id; 
  final String title;
  final String description;  
  final String authorId;  
  final DateTime createdAt;

  const ProjectAd(
    {
      required this.id,
      required this.title, 
      required this.description, 
      required this.authorId,
      required this.createdAt, 
    }
  );
  
  @override
  List<Object?> get props => [id, title, description, authorId, createdAt];

  Map<String, dynamic> toMap() => {
       'id': id,
       'title': title,
       'description': description,
       'authorId': authorId,
       'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
     };

  factory ProjectAd.fromMap(Map<String, dynamic> map) => ProjectAd(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        authorId: map['authorId'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as int),
          isUtc: true,
        ).toLocal(),
      );

  
}


