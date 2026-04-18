import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingData {
  final String title;
  final String date;
  final String time;
  String status;

  MeetingData({
    required this.title,
    required this.date,
    required this.time,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'date': date,
    'time': time,
    'status': status,
  };

  factory MeetingData.fromMap(Map<String, dynamic> map) => MeetingData(
    title: map['title'] ?? '',
    date: map['date'] ?? '',
    time: map['time'] ?? '',
    status: map['status'] ?? 'pending',
  );
}

class Message {
  final String id;
  final String text;
  final bool isSent;
  final String time;
  final String senderId;
  final DateTime timestamp;
  final MeetingData? meeting;
  final List<String> readBy;
  final Map<String, String> reactions; // userId → emoji
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;

  Message({
    required this.id,
    required this.text,
    required this.isSent,
    required this.time,
    required this.senderId,
    required this.timestamp,
    this.meeting,
    this.readBy = const [],
    this.reactions = const {},
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
  });

  bool isReadBy(String userId) => readBy.contains(userId);

  Map<String, int> get groupedReactions {
    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'senderId': senderId,
    'timestamp': Timestamp.fromDate(timestamp),
    'type': meeting != null ? 'meeting' : 'text',
    'meeting': meeting?.toMap(),
    'readBy': readBy,
    'reactions': reactions,
    if (replyToId != null) 'replyToId': replyToId,
    if (replyToText != null) 'replyToText': replyToText,
    if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
  };

  factory Message.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');

    return Message(
      id: doc.id,
      text: data['text'] ?? '',
      isSent: data['senderId'] == currentUserId,
      senderId: data['senderId'] ?? '',
      time: '$hour:$minute',
      timestamp: timestamp,
      readBy: List<String>.from(data['readBy'] ?? []),
      meeting: data['meeting'] != null
          ? MeetingData.fromMap(data['meeting'] as Map<String, dynamic>)
          : null,
      reactions: Map<String, String>.from(data['reactions'] ?? {}),
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      replyToSenderName: data['replyToSenderName'],
    );
  }
}