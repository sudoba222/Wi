/// Data for a meeting invite message.
class MeetingData {
  final String title;
  final String date;
  final String time;
  /// 'pending' | 'accepted' | 'declined'
  String status;

  MeetingData({
    required this.title,
    required this.date,
    required this.time,
    this.status = 'pending',
  });
}

class Message {
  final String text;
  final bool isSent;
  final String time;

  /// Non-null when this message is a meeting invite card.
  final MeetingData? meeting;

  Message({
    required this.text,
    required this.isSent,
    required this.time,
    this.meeting,
  });
}
