// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
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

  /// Opens a bottom sheet where the user can type a name to start a new chat.
  void _showNewChatSheet() {
    final nameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          // Keep the input above the keyboard.
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _GlassBottomSheet(
            nameController: nameController,
            onStart: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              GlobalData.createConversation(name);
              setState(() {});
              Navigator.pop(ctx);
            },
          ),
        );
      },
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
class _GlassBottomSheet extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onStart;

  const _GlassBottomSheet({
    required this.nameController,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.92),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle indicator.
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mutedText.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'New conversation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkPurple,
                ),
              ),
              const SizedBox(height: 16),
              // Name text field.
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: AppColors.darkPurple),
                decoration: InputDecoration(
                  hintText: 'Enter a name',
                  hintStyle:
                      const TextStyle(color: AppColors.mutedText),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.wisteria.withOpacity(0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.wisteria.withOpacity(0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.splashPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Start Chat amber button.
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sunglow,
                    foregroundColor: AppColors.darkPurple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Start Chat',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
