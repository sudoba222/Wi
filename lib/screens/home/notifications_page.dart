// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../providers/language_provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.background;
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.t('notifications'), style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => _markAllRead(uid),
              child: Text(lang.t('markAllRead'), style: const TextStyle(color: AppColors.wisteria, fontSize: 13)),
            ),
        ],
      ),
      body: uid == null
          ? _emptyState(lang, isDark)
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(uid)
                  .collection('items')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.wisteria));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return _emptyState(lang, isDark);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final isRead = data['read'] == true;
                    return _NotificationTile(
                      data: data,
                      isRead: isRead,
                      isDark: isDark,
                      onTap: () => _markRead(uid, docs[i].id),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _markRead(String uid, String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(docId)
        .update({'read': true});
  }

  Future<void> _markAllRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Widget _emptyState(LanguageProvider lang, bool isDark) {
    final sub = isDark ? Colors.white38 : AppColors.mutedText;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              color: AppColors.wisteria.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 42, color: AppColors.wisteria.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          Text(lang.t('noNotifications'), style: TextStyle(color: sub, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(lang.t('noNotificationsSub'), style: TextStyle(color: sub, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isRead, isDark;
  final VoidCallback onTap;
  const _NotificationTile({required this.data, required this.isRead, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? 'general';
    final message = data['message'] as String? ?? '';
    final senderName = data['senderName'] as String? ?? '';
    final senderPhoto = data['senderPhoto'] as String?;
    final createdAt = data['createdAt'];
    final card = isDark ? AppColors.darkCard : AppColors.white;
    final unreadBg = isDark ? const Color(0xFF2A1245) : const Color(0xFFF0EAFF);
    final text = isDark ? Colors.white : AppColors.darkPurple;
    final sub = isDark ? Colors.white54 : AppColors.mutedText;

    String timeLabel = '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) timeLabel = '${diff.inMinutes}m';
      else if (diff.inHours < 24) timeLabel = '${diff.inHours}h';
      else timeLabel = '${diff.inDays}d';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isRead ? card : unreadBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Row(
          children: [
            // Avatar or icon
            Stack(
              children: [
                _Avatar(name: senderName, photoUrl: senderPhoto),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(color: _typeColor(type), shape: BoxShape.circle, border: Border.all(color: card, width: 2)),
                    child: Icon(_typeIcon(type), size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: text, fontSize: 13, height: 1.4),
                      children: [
                        if (senderName.isNotEmpty)
                          TextSpan(text: '$senderName ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: message),
                      ],
                    ),
                  ),
                  if (timeLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(timeLabel, style: TextStyle(color: sub, fontSize: 11)),
                  ],
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.wisteria, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'like': return Icons.favorite_rounded;
      case 'comment': return Icons.chat_bubble_rounded;
      case 'follow': return Icons.person_add_rounded;
      case 'connection': return Icons.handshake_rounded;
      case 'message': return Icons.mail_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'like': return Colors.red;
      case 'comment': return AppColors.splashPurple;
      case 'follow': return Colors.teal;
      case 'connection': return Colors.blue;
      case 'message': return AppColors.sunglow;
      default: return AppColors.wisteria;
    }
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _Avatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: 44, height: 44,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.wisteria, AppColors.splashPurple]),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(photoUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(name))
            : _initials(name),
      ),
    );
  }

  Widget _initials(String name) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );
}
