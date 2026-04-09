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
  String _searchQuery = '';

  // ── Pin logic ──────────────────────────────────────────────────────────────

  int get _pinnedCount => GlobalData.conversations.where((c) => c.isPinned).length;

  /// Toggles pin. Shows a snackbar if the user tries to pin a 4th chat.
  void _togglePin(int originalIndex) {
    final conv = GlobalData.conversations[originalIndex];
    if (!conv.isPinned && _pinnedCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You can pin up to 3 chats only'),
          backgroundColor: AppColors.darkPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() => conv.isPinned = !conv.isPinned);
  }

  // ── New chat ───────────────────────────────────────────────────────────────

  /// Opens the Firestore user search sheet to start a new conversation.
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

  /// Opens the ChatScreen for the conversation at [originalIndex].
  void _openChat(int originalIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: GlobalData.conversations[originalIndex],
          onMessageSent: () => setState(() {}),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Split into pinned (shown first) and unpinned, both filtered by search
    final all = GlobalData.conversations;
    final pinned = all.where((c) => c.isPinned && (
      _searchQuery.isEmpty || c.userName.toLowerCase().contains(_searchQuery.toLowerCase())
    )).toList();
    final unpinned = all.where((c) => !c.isPinned && (
      _searchQuery.isEmpty || c.userName.toLowerCase().contains(_searchQuery.toLowerCase())
    )).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1E0B2C), const Color(0xFF1A0A22)]
              : [const Color(0xFFF0EAFF), AppColors.background],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: title only ─────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 0),
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.darkPurple,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Search bar — tap the "new chat" icon inside to search users ─
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchBarWithNewChat(
              onChanged: (q) => setState(() => _searchQuery = q),
              onNewChat: _showNewChatSheet,
              isDark: isDark,
            ),
          ),

          const SizedBox(height: 12),

          // ── Pinned section header ──────────────────────────────────────
          if (pinned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.mutedText),
                  const SizedBox(width: 5),
                  Text(
                    'PINNED  ${pinned.length}/3',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mutedText, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

          // ── Conversation list ──────────────────────────────────────────
          Expanded(
            child: (pinned.isEmpty && unpinned.isEmpty)
                ? _buildEmptyState(isDark)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      // Pinned chats first
                      ...pinned.map((c) {
                        final idx = all.indexOf(c);
                        return _ConversationTile(
                          conversation: c,
                          isPinned: true,
                          isDark: isDark,
                          onTap: () => _openChat(idx),
                          onTogglePin: () => _togglePin(idx),
                        );
                      }),
                      // Gap between sections if both exist
                      if (pinned.isNotEmpty && unpinned.isNotEmpty)
                        const SizedBox(height: 4),
                      // Unpinned chats
                      ...unpinned.map((c) {
                        final idx = all.indexOf(c);
                        return _ConversationTile(
                          conversation: c,
                          isPinned: false,
                          isDark: isDark,
                          onTap: () => _openChat(idx),
                          onTogglePin: () => _togglePin(idx),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Empty-state view shown when there are no conversations.
  Widget _buildEmptyState(bool isDark) {
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
                  color: (isDark ? Colors.white : AppColors.wisteria).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.wisteria.withOpacity(0.3)),
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
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.darkPurple,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start a conversation',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
          const SizedBox(height: 24),
          // Prompt to start a new chat
          GestureDetector(
            onTap: _showNewChatSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.sunglow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'New Conversation',
                style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Search bar with an inline "new chat" compose icon on the right.
class _SearchBarWithNewChat extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onNewChat;
  final bool isDark;

  const _SearchBarWithNewChat({
    required this.onChanged,
    required this.onNewChat,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.12) : AppColors.wisteria.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              // Material(transparency) fixes "No Material ancestor" error
              // when TextField is inside BackdropFilter/ClipRRect.
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    onChanged: onChanged,
                    style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.darkPurple),
                    decoration: InputDecoration(
                      hintText: 'Search conversations…',
                      hintStyle: const TextStyle(fontSize: 15, color: AppColors.mutedText),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedText, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                    ),
                  ),
                ),
              ),
              // New chat compose button
              GestureDetector(
                onTap: onNewChat,
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.sunglow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.darkPurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single conversation row — glass card with pin badge, long-press to pin/unpin.
class _ConversationTile extends StatelessWidget {
  final dynamic conversation;
  final bool isPinned;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  const _ConversationTile({
    required this.conversation,
    required this.isPinned,
    required this.isDark,
    required this.onTap,
    required this.onTogglePin,
  });

  void _showPinMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.mutedText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: isPinned ? AppColors.mutedText : AppColors.sunglow,
              ),
              title: Text(
                isPinned ? 'Unpin chat' : 'Pin chat',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.darkPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onTogglePin();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = conversation.userName as String;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showPinMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? (isPinned ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.06))
                    : (isPinned ? AppColors.sunglow.withOpacity(0.08) : Colors.white.withOpacity(0.55)),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPinned
                      ? AppColors.sunglow.withOpacity(0.45)
                      : (isDark ? Colors.white.withOpacity(0.1) : AppColors.wisteria.withOpacity(0.2)),
                  width: isPinned ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Avatar with optional pin badge
                  Stack(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppColors.wisteria, AppColors.splashPurple],
                          ),
                        ),
                        child: Center(
                          child: Text(initial,
                            style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      // Pin badge — small amber circle with pin icon
                      if (isPinned)
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 18, height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.sunglow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.push_pin_rounded, size: 11, color: AppColors.darkPurple),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Name + last message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.darkPurple,
                                )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          conversation.lastMessage as String,
                          style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Timestamp
                  Text(
                    conversation.lastMessageTime as String,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkDrawer : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
          // Header — theme-aware text color
          Align(
            alignment: Alignment.centerLeft,
            child: Text('New Conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.darkPurple)),
          ),
          const SizedBox(height: 14),
          // Search input — queries Firestore on change
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.wisteria.withOpacity(0.3)),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : AppColors.darkPurple),
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
