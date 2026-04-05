class Education {
  final String id;
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final DateTime startDate;
  final DateTime? endDate;
  final String grade;
  final String description;

  Education({
    required this.id,
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    this.endDate,
    this.grade = '',
    this.description = '',
  });

  String get duration {
    final start = startDate.year.toString();
    if (endDate != null) {
      return '$start - ${endDate!.year}';
    }
    return start;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'institution': institution,
      'degree': degree,
      'fieldOfStudy': fieldOfStudy,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'grade': grade,
      'description': description,
    };
  }

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      id: map['id'] ?? '',
      institution: map['institution'] ?? '',
      degree: map['degree'] ?? '',
      fieldOfStudy: map['fieldOfStudy'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      grade: map['grade'] ?? '',
      description: map['description'] ?? '',
    );
  }
}