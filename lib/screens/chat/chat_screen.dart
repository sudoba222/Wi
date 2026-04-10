// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../services/global_data.dart';

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

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final newMsg = Message(
      text: text,
      isSent: true,
      time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    );
    setState(() => widget.conversation.messages.add(newMsg));
    _controller.clear();
    widget.onMessageSent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  /// Three-dot menu: pin/unpin, clear history, delete chat.
  void _showChatOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conv = widget.conversation;
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
            Center(
              child: Container(
                width: 36, height: 4, margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.mutedText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                conv.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                color: AppColors.sunglow,
              ),
              title: Text(
                conv.isPinned ? 'Unpin chat' : 'Pin chat',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.darkPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (mounted) setState(() => conv.isPinned = !conv.isPinned);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_rounded, color: Colors.orange),
              title: Text(
                'Clear history',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.darkPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                if (mounted) setState(() => conv.messages.clear());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text(
                'Delete chat',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                GlobalData.conversations.remove(conv);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a bottom sheet to schedule a meeting with the contact.
  void _showMeetingScheduler(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final titleCtrl = TextEditingController();

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
                Center(
                  child: Container(
                    width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.mutedText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.wisteria.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: AppColors.wisteria, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Schedule Meeting',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkPurple),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.wisteria.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: titleCtrl,
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
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (c, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.splashPurple,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) setS(() => selectedDate = d);
                  },
                  child: _MeetingRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                      builder: (c, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.splashPurple,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (t != null) setS(() => selectedTime = t);
                  },
                  child: _MeetingRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: selectedTime.format(ctx),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final title = titleCtrl.text.trim().isEmpty ? 'Meeting' : titleCtrl.text.trim();
                      final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
                      final timeStr = selectedTime.format(context);
                      final now = DateTime.now();
                      final timeLabel = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                      final meetingMsg = Message(
                        text: 'Meeting invite: $title',
                        isSent: true,
                        time: timeLabel,
                        meeting: MeetingData(title: title, date: dateStr, time: timeStr),
                      );
                      setState(() => widget.conversation.messages.add(meetingMsg));
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                      widget.onMessageSent();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sunglow,
                      foregroundColor: AppColors.darkPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Schedule Meeting',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    final name = widget.conversation.userName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E0B2C), AppColors.darkBg]
                : [const Color(0xFFF0EAFF), AppColors.background],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(context, name, initial),
            Expanded(
              child: widget.conversation.messages.isEmpty
                  ? _buildEmptyState(name)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: widget.conversation.messages.length,
                      itemBuilder: (_, i) => _MessageBubble(
                        message: widget.conversation.messages[i],
                        onStatusChange: () => setState(() {}),
                      ),
                    ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String name, String initial) {
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(4, topPad + 4, 4, 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.72),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDark ? Colors.white : AppColors.darkPurple,
                  size: 20,
                ),
              ),
              // Tappable avatar — opens peer profile
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _PeerProfilePage(name: name, initial: initial),
                  ),
                ),
                child: Container(
                  width: 38, height: 38,
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
              ),
              const SizedBox(width: 10),
              // Tappable name — also opens peer profile
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _PeerProfilePage(name: name, initial: initial),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.darkPurple,
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
              ),
              IconButton(
                onPressed: () => _showMeetingScheduler(context),
                tooltip: 'Schedule meeting',
                icon: const Icon(Icons.calendar_month_rounded, color: AppColors.wisteria),
              ),
              IconButton(
                onPressed: () => _showChatOptions(context),
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white : AppColors.darkPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.wisteria.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.waving_hand_rounded, size: 36, color: AppColors.wisteria),
          ),
          const SizedBox(height: 16),
          Text(
            'Say hi to $name!',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.darkPurple,
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

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.72),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.attach_file_rounded, color: AppColors.wisteria, size: 22),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.darkPurple,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message…',
                          hintStyle: TextStyle(
                            color: AppColors.mutedText.withOpacity(0.8),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _hasText ? _sendMessage : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _hasText ? AppColors.sunglow : AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _hasText ? Icons.send_rounded : Icons.mic_rounded,
                      color: _hasText ? AppColors.darkPurple : AppColors.mutedText,
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

class _MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback onStatusChange;

  const _MessageBubble({required this.message, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    // If this message is a meeting invite, render the meeting card
    if (message.meeting != null) {
      return _MeetingCard(
        message: message,
        onStatusChange: onStatusChange,
      );
    }

    final isSent = message.isSent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receivedColor = isDark ? AppColors.darkCard : AppColors.white;
    final receivedTextColor = isDark ? Colors.white : AppColors.darkPurple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent)
            Container(
              width: 28, height: 28,
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
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSent ? AppColors.sunglow : receivedColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isSent ? 18 : 4),
                    bottomRight: Radius.circular(isSent ? 4 : 18),
                  ),
                  border: (!isSent && isDark)
                      ? Border.all(color: Colors.white.withOpacity(0.1), width: 1)
                      : null,
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
                    color: isSent ? AppColors.darkPurple : receivedTextColor,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    message.time,
                    style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                  ),
                  if (isSent) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all_rounded, size: 14, color: AppColors.wisteria),
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

// ─── Meeting Card ─────────────────────────────────────────────────────────────

/// Renders a meeting invite ticket in the chat.
/// Sent: shows title/date/time + status badge.
/// Received: shows title/date/time + accept ✓ / decline ✗ buttons (pending only).
class _MeetingCard extends StatefulWidget {
  final Message message;
  final VoidCallback onStatusChange;

  const _MeetingCard({required this.message, required this.onStatusChange});

  @override
  State<_MeetingCard> createState() => _MeetingCardState();
}

class _MeetingCardState extends State<_MeetingCard> {
  void _respond(String status) {
    setState(() => widget.message.meeting!.status = status);
    widget.onStatusChange();
  }

  @override
  Widget build(BuildContext context) {
    final isSent = widget.message.isSent;
    final meeting = widget.message.meeting!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = meeting.status; // 'pending' | 'accepted' | 'declined'

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received
          if (!isSent)
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.wisteria, AppColors.splashPurple],
                ),
              ),
              child: const Center(
                child: Text('?', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),

          // Card body
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isSent ? 18 : 4),
                bottomRight: Radius.circular(isSent ? 4 : 18),
              ),
              border: Border.all(
                color: AppColors.wisteria.withOpacity(isDark ? 0.25 : 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkPurple.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.wisteria, AppColors.splashPurple],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(17),
                      topRight: const Radius.circular(17),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Meeting Invite',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      // Status badge
                      if (status == 'accepted')
                        _StatusBadge(label: 'Accepted', color: const Color(0xFF2ECC71)),
                      if (status == 'declined')
                        _StatusBadge(label: 'Declined', color: Colors.red),
                    ],
                  ),
                ),

                // Title + details
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Text(
                    meeting.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.darkPurple,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.wisteria),
                      const SizedBox(width: 5),
                      Text(
                        meeting.date,
                        style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.wisteria),
                      const SizedBox(width: 5),
                      Text(
                        meeting.time,
                        style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),

                // Accept / Decline buttons — only for received + pending
                if (!isSent && status == 'pending') ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Row(
                      children: [
                        // Accept button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _respond('accepted'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 5),
                                  Text(
                                    'Accept',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Decline button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _respond('declined'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.35)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.close_rounded, color: Colors.red, size: 16),
                                  SizedBox(width: 5),
                                  Text(
                                    'Decline',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const SizedBox(height: 14),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(right: 14, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.message.time,
                        style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, size: 14, color: AppColors.wisteria),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small colored label badge used in the meeting card header.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

// ─── Meeting Row (date/time picker row) ───────────────────────────────────────

class _MeetingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MeetingRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
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

// ─── Peer Profile Page ────────────────────────────────────────────────────────

/// Profile screen shown when tapping the contact's avatar/name in the chat header.
/// Presentational only — in-memory conversations don't have Firebase user lookups.
class _PeerProfilePage extends StatefulWidget {
  final String name;
  final String initial;

  const _PeerProfilePage({required this.name, required this.initial});

  @override
  State<_PeerProfilePage> createState() => _PeerProfilePageState();
}

class _PeerProfilePageState extends State<_PeerProfilePage> {
  bool _isFollowing = false;
  bool _isConnected = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkPurple, AppColors.splashPurple],
              ),
            ),
            child: Column(
              children: [
                // Back button row
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Avatar
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.wisteria, Color(0xFFBB6BD9)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                  ),
                  child: Center(
                    child: Text(
                      widget.initial,
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Name
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                // Mock job title
                Text(
                  'Professional · Tajikistan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // Mock company
                Text(
                  'Wi Network Member',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Action buttons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                // Follow/Following toggle
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFollowing = !_isFollowing),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isFollowing ? AppColors.sunglow : AppColors.splashPurple,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: _isFollowing ? AppColors.darkPurple : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Connect button
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isConnected = !_isConnected),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? (isDark ? AppColors.darkCard : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isConnected
                              ? AppColors.wisteria.withOpacity(0.4)
                              : AppColors.wisteria,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _isConnected ? 'Connected' : 'Connect',
                          style: TextStyle(
                            color: AppColors.wisteria,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Message button — goes back to the chat
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.wisteria.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.wisteria.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.wisteria, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Stats row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.07) : AppColors.wisteria.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  _StatItem(value: '328', label: 'Connections', isDark: isDark),
                  _StatDivider(isDark: isDark),
                  _StatItem(value: '1.2K', label: 'Followers', isDark: isDark),
                  _StatDivider(isDark: isDark),
                  _StatItem(value: '47', label: 'Posts', isDark: isDark),
                ],
              ),
            ),
          ),

          // ── About section ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.07) : AppColors.wisteria.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.darkPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Professional member of the Wi network in Tajikistan.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.mutedText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  const _StatItem({required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.darkPurple,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
      ],
    ),
  );
}

class _StatDivider extends StatelessWidget {
  final bool isDark;
  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    color: isDark ? Colors.white.withOpacity(0.1) : AppColors.wisteria.withOpacity(0.15),
  );
}
