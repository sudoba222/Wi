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

  Message({
    required this.id,
    required this.text,
    required this.isSent,
    required this.time,
    required this.senderId,
    required this.timestamp,
    this.meeting,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'senderId': senderId,
    'timestamp': Timestamp.fromDate(timestamp),
    'type': meeting != null ? 'meeting' : 'text',
    'meeting': meeting?.toMap(),
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
      meeting: data['meeting'] != null
          ? MeetingData.fromMap(data['meeting'] as Map<String, dynamic>)
          : null,
    );
  }
}