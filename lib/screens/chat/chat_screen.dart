// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';

/// Full-screen chat screen for a single conversation.
/// Uses an in-memory [Conversation] from GlobalData — no Firebase wiring yet.
class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  /// Callback fired after the user sends a message so the parent can rebuild.
  final VoidCallback onMessageSent;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.onMessageSent,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  /// True when the input field contains non-whitespace text.
  bool _hasText = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Watch input changes to toggle the send button.
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
    // Scroll to the latest message after the first frame.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Animates the scroll position to the bottom of the message list.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Appends a new sent message to the conversation and scrolls down.
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final newMsg = Message(
      text: text,
      isSent: true,
      time:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    setState(() => widget.conversation.messages.add(newMsg));
    _controller.clear();
    widget.onMessageSent();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom());
  }

  /// Opens a bottom sheet to schedule a meeting with the contact.
  void _showMeetingScheduler(BuildContext context) {
    DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final _titleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.mutedText.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // Title
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.wisteria.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.calendar_month_rounded, color: AppColors.wisteria, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Schedule Meeting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkPurple)),
                  ],
                ),
                const SizedBox(height: 20),
                // Meeting title input
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.wisteria.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Meeting title…',
                      hintStyle: TextStyle(color: AppColors.mutedText),
                      prefixIcon: Icon(Icons.title_rounded, color: AppColors.wisteria, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: const TextStyle(color: AppColors.darkPurple),
                  ),
                ),
                const SizedBox(height: 12),
                // Date picker row
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (c, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: AppColors.splashPurple, onPrimary: Colors.white),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) setS(() => _selectedDate = d);
                  },
                  child: _MeetingRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  ),
                ),
                const SizedBox(height: 8),
                // Time picker row
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: _selectedTime,
                      builder: (c, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(primary: AppColors.splashPurple, onPrimary: Colors.white),
                        ),
                        child: child!,
                      ),
                    );
                    if (t != null) setS(() => _selectedTime = t);
                  },
                  child: _MeetingRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _selectedTime.format(ctx),
                  ),
                ),
                const SizedBox(height: 20),
                // Confirm button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final title = _titleCtrl.text.trim().isEmpty ? 'Meeting' : _titleCtrl.text.trim();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Meeting "$title" scheduled for ${_selectedDate.day}/${_selectedDate.month} at ${_selectedTime.format(context)}'),
                          backgroundColor: AppColors.splashPurple,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sunglow,
                      foregroundColor: AppColors.darkPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Schedule Meeting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name = widget.conversation.userName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      // Gradient background matching the app design system.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0EAFF), AppColors.background],
          ),
        ),
        child: Column(
          children: [
            // ── Top app bar ─────────────────────────────────────────────
            _buildAppBar(context, name, initial),
            // ── Message list ────────────────────────────────────────────
            Expanded(
              child: widget.conversation.messages.isEmpty
                  ? _buildEmptyState(name)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: widget.conversation.messages.length,
                      itemBuilder: (_, i) => _MessageBubble(
                          message: widget.conversation.messages[i]),
                    ),
            ),
            // ── Input bar ────────────────────────────────────────────────
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  /// Glass-tinted top bar with back arrow, avatar + name, and action icons.
  Widget _buildAppBar(
      BuildContext context, String name, String initial) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        // Subtle blur on the header background.
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(4, topPad + 4, 4, 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Back button.
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.darkPurple,
                  size: 20,
                ),
              ),
              // Gradient avatar circle.
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.wisteria, AppColors.splashPurple],
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Contact name + online status.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.darkPurple,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: Color(0xFF2ECC71),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Schedule a meeting button (replaces video/call)
              IconButton(
                onPressed: () => _showMeetingScheduler(context),
                tooltip: 'Schedule meeting',
                icon: const Icon(Icons.calendar_month_rounded, color: AppColors.wisteria),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.darkPurple),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state shown when no messages exist in the conversation.
  Widget _buildEmptyState(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tinted waving-hand icon.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.wisteria.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              size: 36,
              color: AppColors.wisteria,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Say hi to $name!',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.darkPurple,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Send your first message',
            style: TextStyle(fontSize: 14, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  /// Glass input bar at the bottom with attach, text field, and send button.
  Widget _buildInputBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Attach-file icon button.
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: AppColors.wisteria,
                    size: 22,
                  ),
                ),
                // Expandable text input field.
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      style: const TextStyle(
                        color: AppColors.darkPurple,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Message…',
                        hintStyle: TextStyle(
                          color: AppColors.mutedText.withOpacity(0.8),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button — amber circle when text is present.
                GestureDetector(
                  onTap: _hasText ? _sendMessage : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _hasText
                          ? AppColors.sunglow
                          : AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _hasText
                          ? Icons.send_rounded
                          : Icons.mic_rounded,
                      color: _hasText
                          ? AppColors.darkPurple
                          : AppColors.mutedText,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

/// Renders a single chat bubble — right-aligned amber for sent,
/// left-aligned white glass for received.
class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSent = message.isSent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Small avatar shown on the left for received messages.
          if (!isSent)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.wisteria, AppColors.splashPurple],
                ),
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Bubble + timestamp.
          Column(
            crossAxisAlignment: isSent
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // Message text bubble.
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  // Sent = amber, received = white glass.
                  color: isSent ? AppColors.sunglow : AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isSent ? 18 : 4),
                    bottomRight: Radius.circular(isSent ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkPurple.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 15,
                    // Sent bubbles use dark text on amber background.
                    color: isSent
                        ? AppColors.darkPurple
                        : AppColors.darkPurple,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Timestamp + read receipt.
              Row(
                children: [
                  Text(
                    message.time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText,
                    ),
                  ),
                  if (isSent) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      color: AppColors.wisteria,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Meeting row tile inside the scheduler sheet ───────────────────────────

/// A tappable info row showing a label + value (used for date and time pickers).
class _MeetingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MeetingRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.wisteria.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.wisteria, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText, size: 18),
        ],
      ),
    );
  }
}
