class Experience {
  final String id;
  final String position;
  final String company;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String description;
  final List<String> achievements;

  Experience({
    required this.id,
    required this.position,
    required this.company,
    required this.location,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description = '',
    this.achievements = const [],
  });

  String get duration {
    final start = '${_getMonthName(startDate.month)} ${startDate.year}';
    if (isCurrent) {
      return '$start - Present';
    } else if (endDate != null) {
      final end = '${_getMonthName(endDate!.month)} ${endDate!.year}';
      return '$start - $end';
    }
    return start;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}