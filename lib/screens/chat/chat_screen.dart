// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../models/message.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;
  final bool isPinned;
  final VoidCallback? onTogglePin;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
    this.isPinned = false,
    this.onTogglePin,
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
    // Mark messages as read when chat opens
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.markMessagesAsRead(widget.conversationId);
  });
  
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.sendMessage(widget.conversationId, text);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _showChatOptions() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final chatService = Provider.of<ChatService>(context, listen: false);

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
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.mutedText.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              widget.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              color: AppColors.sunglow,
            ),
            title: Text(
              widget.isPinned ? 'Unpin chat' : 'Pin chat',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.darkPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
              onTap: () {
                Navigator.pop(context);
                widget.onTogglePin?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_rounded, color: Colors.orange),
              title: Text('Clear history',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.darkPurple,
                    fontWeight: FontWeight.w500,
                  )),
              onTap: () async {
                Navigator.pop(context);
                await chatService.clearMessages(widget.conversationId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete chat',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              onTap: () async {
                Navigator.pop(context);
                await chatService.deleteConversation(widget.conversationId);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  void _showMeetingScheduler() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final titleCtrl = TextEditingController();
    final chatService = Provider.of<ChatService>(context, listen: false);

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
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
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
                      child: const Icon(Icons.calendar_month_rounded,
                          color: AppColors.wisteria, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Schedule Meeting',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkPurple)),
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
                      prefixIcon: Icon(Icons.title_rounded,
                          color: AppColors.wisteria, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final title = titleCtrl.text.trim().isEmpty
                          ? 'Meeting'
                          : titleCtrl.text.trim();
                      final dateStr =
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
                      final timeStr = selectedTime.format(context);
                      await chatService.sendMeetingInvite(
                        widget.conversationId,
                        title,
                        dateStr,
                        timeStr,
                      );
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _scrollToBottom());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sunglow,
                      foregroundColor: AppColors.darkPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Schedule Meeting',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
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
    final name = widget.otherUserName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatService = Provider.of<ChatService>(context, listen: false);

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
            _buildAppBar(context, name, initial, isDark),
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: chatService.getMessagesStream(widget.conversationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.wisteria),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return _buildEmptyState(name);
                  }

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _MessageBubble(
                      message: messages[i],
                      onStatusChange: (messageId, status) async {
                        await chatService.updateMeetingStatus(
                          widget.conversationId,
                          messageId,
                          status,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
      BuildContext context, String name, String initial, bool isDark) {
    final topPad = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(4, topPad + 4, 4, 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.72),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_rounded,
                    color: isDark ? Colors.white : AppColors.darkPurple,
                    size: 20),
              ),
              Container(
                width: 38, height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.wisteria, AppColors.splashPurple],
                  ),
                ),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkPurple,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    StreamBuilder<Map<String, dynamic>>(
                      stream: Provider.of<ChatService>(context, listen: false)
                          .getUserPresenceStream(widget.otherUserId),
                     builder: (context, snapshot) {
                        final data = snapshot.data ?? {};
                        final isOnlineRaw = data['online'] ?? false;
                        final lastSeen = data['lastSeen'];
                        // TTL check — if lastSeen > 2 minutes ago, treat as offline
                        bool isOnline = false;
                        if (isOnlineRaw && lastSeen != null) {
                          final lastSeenTime = (lastSeen as dynamic).toDate() as DateTime;
                          final diff = DateTime.now().difference(lastSeenTime);
                          isOnline = diff.inMinutes < 2;
                        }
                        String statusText = 'Offline';
                        if (isOnline) {
                          statusText = 'Online';
                        } else if (lastSeen != null) {
                          final lastSeenTime = (lastSeen as dynamic).toDate() as DateTime;
                          final now = DateTime.now();
                          final diff = now.difference(lastSeenTime);
                          if (diff.inMinutes < 1) {
                            statusText = 'Just now';
                          } else if (diff.inMinutes < 60) {
                            statusText = '${diff.inMinutes}m ago';
                          } else if (diff.inHours < 24) {
                            statusText = '${diff.inHours}h ago';
                          } else {
                            statusText = '${diff.inDays}d ago';
                          }
                        }
                        return Text(
                          statusText,
                          style: TextStyle(
                            color: isOnline ? const Color(0xFF2ECC71) : AppColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showMeetingScheduler,
                tooltip: 'Schedule meeting',
                icon: const Icon(Icons.calendar_month_rounded,
                    color: AppColors.wisteria),
              ),
              IconButton(
                onPressed: _showChatOptions,
                icon: Icon(Icons.more_vert_rounded,
                    color: isDark ? Colors.white : AppColors.darkPurple),
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
            child: const Icon(Icons.waving_hand_rounded,
                size: 36, color: AppColors.wisteria),
          ),
          const SizedBox(height: 16),
          Text('Say hi to $name!',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.darkPurple)),
          const SizedBox(height: 6),
          const Text('Send your first message',
              style: TextStyle(fontSize: 14, color: AppColors.mutedText)),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.72),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.4),
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
                  icon: const Icon(Icons.attach_file_rounded,
                      color: AppColors.wisteria, size: 22),
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        style: TextStyle(
                            color: isDark ? Colors.white : AppColors.darkPurple,
                            fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Message…',
                          hintStyle: TextStyle(
                              color: AppColors.mutedText.withOpacity(0.8),
                              fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
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

class _MessageBubble extends StatelessWidget {
  final Message message;
  final void Function(String messageId, String status) onStatusChange;

  const _MessageBubble({
    required this.message,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
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
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent)
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppColors.wisteria, AppColors.splashPurple]),
              ),
              child: const Center(
                child: Text('?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          Column(
            crossAxisAlignment:
                isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
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
                mainAxisAlignment:
                    isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(message.time,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.mutedText)),
                  if (isSent) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.readBy.length > 1
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 14,
                      color: message.readBy.length > 1
                          ? AppColors.sunglow
                          : AppColors.mutedText,
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

class _MeetingCard extends StatelessWidget {
  final Message message;
  final void Function(String messageId, String status) onStatusChange;

  const _MeetingCard({
    required this.message,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = message.isSent;
    final meeting = message.meeting!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = meeting.status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent)
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppColors.wisteria, AppColors.splashPurple]),
              ),
              child: const Center(
                child: Text('?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.wisteria, AppColors.splashPurple]),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Text('Meeting Invite',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (status == 'accepted')
                        _StatusBadge(
                            label: 'Accepted', color: const Color(0xFF2ECC71)),
                      if (status == 'declined')
                        _StatusBadge(label: 'Declined', color: Colors.red),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Text(meeting.title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.darkPurple)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.wisteria),
                      const SizedBox(width: 5),
                      Text(meeting.date,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.mutedText)),
                      const SizedBox(width: 14),
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: AppColors.wisteria),
                      const SizedBox(width: 5),
                      Text(meeting.time,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.mutedText)),
                    ],
                  ),
                ),
                if (!isSent && status == 'pending') ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onStatusChange(message.id, 'accepted'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 5),
                                  Text('Accept',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onStatusChange(message.id, 'declined'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.35)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.close_rounded,
                                      color: Colors.red, size: 16),
                                  SizedBox(width: 5),
                                  Text('Decline',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
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
                Padding(
                  padding: const EdgeInsets.only(right: 14, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(message.time,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.mutedText)),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readBy.length > 1
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: message.readBy.length > 1
                              ? AppColors.sunglow
                              : AppColors.mutedText,
                        ),
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
    child: Text(label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class _MeetingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MeetingRow(
      {required this.icon, required this.label, required this.value});

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
        Text(label,
            style: const TextStyle(color: AppColors.mutedText, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: AppColors.darkPurple,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.mutedText, size: 18),
      ],
    ),
  );
}