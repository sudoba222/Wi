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
}