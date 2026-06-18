class Reflection {
  final String id;
  final String userId;
  final String date;
  final int adherenceScore;
  final int focusScore;
  final int energyScore;
  final String? notesSuccess;
  final String? notesStruggles;
  final String? notesImprovements;
  final String createdAt;

  Reflection({
    required this.id,
    required this.userId,
    required this.date,
    required this.adherenceScore,
    required this.focusScore,
    required this.energyScore,
    this.notesSuccess,
    this.notesStruggles,
    this.notesImprovements,
    required this.createdAt,
  });

  factory Reflection.fromJson(Map<String, dynamic> json) {
    return Reflection(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      date: json['date'] ?? '',
      adherenceScore: json['adherence_score'] ?? 0,
      focusScore: json['focus_score'] ?? 1,
      energyScore: json['energy_score'] ?? 1,
      notesSuccess: json['notes_success'],
      notesStruggles: json['notes_struggles'],
      notesImprovements: json['notes_improvements'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'adherence_score': adherenceScore,
    'focus_score': focusScore,
    'energy_score': energyScore,
    'notes_success': notesSuccess,
    'notes_struggles': notesStruggles,
    'notes_improvements': notesImprovements,
  };
}
