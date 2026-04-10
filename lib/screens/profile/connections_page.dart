// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../models/user_profile.dart';

class ConnectionsPage extends StatefulWidget {
  final UserProfile profile;
  const ConnectionsPage({super.key, required this.profile});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final Set<String> _removed = {};

  Stream<QuerySnapshot> get _usersStream {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('users')
        .where('uid', isNotEqualTo: myUid)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.background;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.darkPurple;
    final subColor =
        isDark ? Colors.white60 : AppColors.darkPurple.withOpacity(0.55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.darkPurple,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: Text(
          '${widget.profile.connections} Connections',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.wisteria));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState('No connections yet', subColor);
          }

          final docs = snapshot.data!.docs
              .where((d) => !_removed.contains(d.id))
              .toList();

          if (docs.isEmpty) {
            return _emptyState('No connections', subColor);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final uid = docs[i].id;
              final name = data['fullName'] as String? ?? 'Unknown';
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
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
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
                    TextButton(
                      onPressed: () =>
                          setState(() => _removed.add(uid)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                      child: const Text('Remove',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
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
