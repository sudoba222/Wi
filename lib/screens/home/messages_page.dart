// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../services/global_data.dart';
import '../chat/chat_screen.dart';

/// Messages list page — shows all in-memory conversations from GlobalData.
/// Data is ephemeral (GlobalData is in-memory only, not backed by Firebase).
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  /// Search query typed into the glass search bar.
  String _searchQuery = '';

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Opens a search-by-username/email bottom sheet to start a new chat.
  void _showNewChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _UserSearchSheet(onStart: (name) {
          GlobalData.createConversation(name);
          setState(() {});
        }),
      ),
    );
  }

  /// Navigates to the ChatScreen for the selected conversation.
  void _openChat(int index) {
    final conversation = GlobalData.conversations[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: conversation,
          onMessageSent: () => setState(() {}),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    // Filter conversations by search query (case-insensitive name match).
    final filtered = GlobalData.conversations.where((c) {
      return _searchQuery.isEmpty ||
          c.userName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      // Gradient background matching the app design system.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0EAFF), AppColors.background],
        ),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkPurple,
                  ),
                ),
                const Spacer(),
                // Amber rounded-square FAB for starting a new conversation.
                GestureDetector(
                  onTap: _showNewChatSheet,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.sunglow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.darkPurple,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Glass search bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _GlassSearchBar(
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),

          const SizedBox(height: 12),

          // ── Conversation list or empty state ───────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      // Find the original index so _openChat works correctly.
                      final originalIndex =
                          GlobalData.conversations.indexOf(filtered[i]);
                      return _ConversationTile(
                        conversation: filtered[i],
                        onTap: () => _openChat(originalIndex),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Empty-state view shown when there are no conversations.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon inside a glass-tinted container.
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 36,
                  color: AppColors.wisteria,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkPurple,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Glass-styled search bar with a search icon and clear-on-type feedback.
class _GlassSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _GlassSearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: TextField(
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.darkPurple,
            ),
            decoration: InputDecoration(
              hintText: 'Search conversations…',
              hintStyle: const TextStyle(
                fontSize: 15,
                color: AppColors.mutedText,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.mutedText,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single conversation row wrapped in a glass card.
class _ConversationTile extends StatelessWidget {
  final dynamic conversation; // Conversation model from GlobalData.
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (conversation.userName as String).isNotEmpty
        ? conversation.userName[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  // Gradient avatar with contact initial.
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.wisteria,
                          AppColors.splashPurple,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name + last message preview.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.userName as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkPurple,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          conversation.lastMessage as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Timestamp aligned to the right.
                  Text(
                    conversation.lastMessageTime as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet content for starting a new conversation.
/// Search-by-username/email bottom sheet.
/// Queries Firestore `users` collection in real time as the user types.
class _UserSearchSheet extends StatefulWidget {
  final void Function(String name) onStart;
  const _UserSearchSheet({required this.onStart});

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  // Search Firestore users by fullName or email prefix
  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) { setState(() { _results = []; _loading = false; }); return; }
    setState(() => _loading = true);

    try {
      // Query by fullName
      final byName = await FirebaseFirestore.instance
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10).get();

      // Query by email
      final byEmail = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: q)
          .where('email', isLessThanOrEqualTo: '$q\uf8ff')
          .limit(10).get();

      // Merge and deduplicate results
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final doc in [...byName.docs, ...byEmail.docs]) {
        if (seen.add(doc.id)) {
          merged.add({...doc.data(), 'uid': doc.id});
        }
      }
      if (mounted) setState(() { _results = merged; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.mutedText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('New Conversation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkPurple)),
          ),
          const SizedBox(height: 14),
          // Search input — queries Firestore on change
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.wisteria.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.darkPurple),
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Search by name or email…',
                hintStyle: TextStyle(color: AppColors.mutedText),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.wisteria, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Results list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.wisteria, strokeWidth: 2))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _ctrl.text.isEmpty ? 'Type a name or email to search' : 'No users found',
                          style: const TextStyle(color: AppColors.mutedText, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final u = _results[i];
                          final name = u['fullName'] ?? u['email'] ?? 'Unknown';
                          final email = u['email'] ?? '';
                          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                            leading: Container(
                              width: 44, height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppColors.wisteria, AppColors.splashPurple]),
                              ),
                              child: Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                            ),
                            title: Text(name, style: const TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: Text(email, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(color: AppColors.sunglow, borderRadius: BorderRadius.circular(20)),
                              child: const Text('Chat', style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onStart(name);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
