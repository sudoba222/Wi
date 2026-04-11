// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';

class ConnectionsPage extends StatelessWidget {
  final UserProfile profile;
  const ConnectionsPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.background;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final subColor =
        isDark ? Colors.white60 : AppColors.darkPurple.withOpacity(0.55);

    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwnProfile = profile.id == myUid;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkPurple,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(profile.id)
              .collection('connections')
              .snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            return Text(
              '$count Connections',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(profile.id)
            .collection('connections')
            .orderBy('connectedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.wisteria));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState('No connections yet', subColor);
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final uid = docs[i].id;
              final name = data['name'] as String? ?? 'Unknown';
              final jobTitle = data['jobTitle'] as String? ?? '';
              final company = data['company'] as String? ?? '';
              final pic = data['profilePicture'] as String? ?? '';

              final subtitle = [
                if (jobTitle.isNotEmpty) jobTitle,
                if (company.isNotEmpty) company,
              ].join(' · ');

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.wisteria,
                      backgroundImage:
                          pic.isNotEmpty ? NetworkImage(pic) : null,
                      child: pic.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textColor)),
                          if (subtitle.isNotEmpty)
                            Text(subtitle,
                                style: TextStyle(
                                    fontSize: 13, color: subColor)),
                        ],
                      ),
                    ),
                    if (isOwnProfile)
                      _RemoveButton(
                        profileId: profile.id,
                        connectionUid: uid,
                        subColor: subColor,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(String text, Color subColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 64, color: subColor),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 16, color: subColor)),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatefulWidget {
  final String profileId;
  final String connectionUid;
  final Color subColor;

  const _RemoveButton({
    required this.profileId,
    required this.connectionUid,
    required this.subColor,
  });

  @override
  State<_RemoveButton> createState() => _RemoveButtonState();
}

class _RemoveButtonState extends State<_RemoveButton> {
  bool _loading = false;

  Future<void> _remove() async {
    setState(() => _loading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('users')
          .doc(widget.profileId)
          .collection('connections')
          .doc(widget.connectionUid)
          .delete();
      await firestore
          .collection('users')
          .doc(widget.connectionUid)
          .collection('connections')
          .doc(widget.profileId)
          .delete();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent));
    }
    return TextButton(
      onPressed: _remove,
      style: TextButton.styleFrom(
        foregroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent),
        ),
      ),
      child: const Text('Remove',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
