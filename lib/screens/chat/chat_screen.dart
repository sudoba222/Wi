// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _hasText = ValueNotifier<bool>(false);
  int _prevMessageCount = 0;
  Message? _replyingTo;
  // Cache stream so rebuilds don't create new Firestore subscriptions
  late final Stream<List<Message>> _messageStream;

  // Scroll-to-bottom button
  bool _showScrollDown = false;
  int _unreadWhileScrolled = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    final chatService = Provider.of<ChatService>(context, listen: false);
    _messageStream = chatService.getMessagesStream(widget.conversationId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      chatService.markMessagesAsRead(widget.conversationId);
    });
  }

  void _onTextChanged() {
    _hasText.value = _controller.text.trim().isNotEmpty;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // With reverse:true, pixel 0 is the visual bottom (newest messages)
    final atBottom = _scrollController.position.pixels <= 80;
    if (atBottom && _showScrollDown) {
      setState(() {
        _showScrollDown = false;
        _unreadWhileScrolled = 0;
      });
    } else if (!atBottom && !_showScrollDown) {
      setState(() => _showScrollDown = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    _hasText.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // With reverse:true, 0 is the visual bottom (newest messages)
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final reply = _replyingTo;
    setState(() => _replyingTo = null);

    // Detect @mention of the other user
    String? mentionedUserId;
    final mentionRe = RegExp(r'@(\w+)', caseSensitive: false);
    for (final m in mentionRe.allMatches(text)) {
      final word = (m.group(1) ?? '').toLowerCase();
      if (widget.otherUserName.toLowerCase().split(' ').any((p) => p.startsWith(word))) {
        mentionedUserId = widget.otherUserId;
        break;
      }
    }

    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.sendMessage(
      widget.conversationId,
      text,
      replyToId: reply?.id,
      replyToText: reply?.text,
      replyToSenderName: reply == null
          ? null
          : (reply.isSent ? 'You' : widget.otherUserName),
      mentionedUserId: mentionedUserId,
      otherUserName: widget.otherUserName,
    );
    if (_showScrollDown) _scrollToBottom();
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
                      if (_showScrollDown) _scrollToBottom();
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
              child: Stack(
                children: [
                  StreamBuilder<List<Message>>(
                stream: _messageStream,
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

                  if (messages.length > _prevMessageCount) {
                    final newCount = messages.length - _prevMessageCount;
                    _prevMessageCount = messages.length;
                    // With reverse:true, new messages appear at visual bottom automatically.
                    // Only show badge if user has scrolled away from the bottom.
                    if (_showScrollDown) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _unreadWhileScrolled += newCount);
                        }
                      });
                    }
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[messages.length - 1 - i];
                      return _MessageBubble(
                        message: msg,
                        currentUserId: chatService.currentUserId,
                        otherUserName: widget.otherUserName,
                        onStatusChange: (messageId, status) async {
                          await chatService.updateMeetingStatus(
                            widget.conversationId,
                            messageId,
                            status,
                          );
                        },
                        onReact: (emoji) => chatService.toggleReaction(
                          widget.conversationId,
                          msg.id,
                          emoji,
                        ),
                        onReply: () => setState(() => _replyingTo = msg),
                        onDelete: () => chatService.deleteMessage(
                          widget.conversationId,
                          msg.id,
                        ),
                      );
                    },
                  );
                },
              ),
                  // Scroll-to-bottom floating button
                  if (_showScrollDown)
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showScrollDown = false;
                            _unreadWhileScrolled = 0;
                          });
                          _scrollToBottom();
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : AppColors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.wisteria
                                        .withOpacity(0.35)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.darkPurple
                                        .withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.wisteria, size: 24),
                            ),
                            if (_unreadWhileScrolled > 0)
                              Positioned(
                                top: -4, right: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.wisteria,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _unreadWhileScrolled > 99
                                        ? '99+'
                                        : '$_unreadWhileScrolled',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                      stream: Provider.of<ChatService>(context,
                              listen: false)
                          .getUserPresenceStream(widget.otherUserId),
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? {};
                        final isOnlineRaw = data['online'] ?? false;
                        final lastSeen = data['lastSeen'];
                        bool isOnline = false;
                        if (isOnlineRaw && lastSeen != null) {
                          final lastSeenTime =
                              (lastSeen as dynamic).toDate() as DateTime;
                          isOnline = DateTime.now()
                                  .difference(lastSeenTime)
                                  .inMinutes <
                              2;
                        }
                        String statusText = 'Offline';
                        if (isOnline) {
                          statusText = 'Online';
                        } else if (lastSeen != null) {
                          final lastSeenTime =
                              (lastSeen as dynamic).toDate() as DateTime;
                          final diff =
                              DateTime.now().difference(lastSeenTime);
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
                            color: isOnline
                                ? const Color(0xFF2ECC71)
                                : AppColors.mutedText,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply preview bar
                if (_replyingTo != null)
                  _ReplyBar(
                    isDark: isDark,
                    senderName: _replyingTo!.isSent
                        ? 'You'
                        : widget.otherUserName,
                    text: _replyingTo!.text,
                    onCancel: () => setState(() => _replyingTo = null),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.attach_file_rounded,
                            color: AppColors.wisteria, size: 22),
                      ),
                      Expanded(
                        child: Container(
                          constraints:
                              const BoxConstraints(maxHeight: 120),
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
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.darkPurple,
                                  fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Message…',
                                hintStyle: TextStyle(
                                    color: AppColors.mutedText
                                        .withOpacity(0.8),
                                    fontSize: 15),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _hasText,
                        builder: (_, hasText, __) => GestureDetector(
                          onTap: hasText ? _sendMessage : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: hasText
                                  ? AppColors.sunglow
                                  : AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              hasText
                                  ? Icons.send_rounded
                                  : Icons.mic_rounded,
                              color: hasText
                                  ? AppColors.darkPurple
                                  : AppColors.mutedText,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
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
  final String currentUserId;
  final String otherUserName;
  final void Function(String messageId, String status) onStatusChange;
  final void Function(String emoji) onReact;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.currentUserId,
    required this.otherUserName,
    required this.onStatusChange,
    required this.onReact,
    required this.onReply,
    required this.onDelete,
  });

  void _showOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myReaction = message.reactions[currentUserId];
    const emojis = ['❤️', '👍', '😂', '😮', '😢', '🔥'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.mutedText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Emoji reaction picker ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: emojis.map((e) {
                    final selected = myReaction == e;
                    return _EmojiPickerBtn(
                      emoji: e,
                      selected: selected,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        onReact(e);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Divider(height: 1, color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06)),
            const SizedBox(height: 4),
            ListTile(
              leading: Icon(Icons.reply_rounded,
                  color: AppColors.wisteria),
              title: Text('Reply',
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.darkPurple,
                      fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (message.text.isNotEmpty)
              ListTile(
                leading: Icon(Icons.copy_rounded,
                    color: AppColors.mutedText),
                title: Text('Copy',
                    style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.darkPurple,
                        fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _copyText(context);
                },
              ),
            if (message.isSent)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: const Text('Delete',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _copyText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.meeting != null) {
      return GestureDetector(
        onLongPress: () => _showOptions(context),
        child: _MeetingCard(
          message: message,
          onStatusChange: onStatusChange,
        ),
      );
    }

    final isSent = message.isSent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receivedColor = isDark ? AppColors.darkCard : AppColors.white;
    final receivedTextColor = isDark ? Colors.white : AppColors.darkPurple;
    final grouped = message.groupedReactions;

    return _SwipeToReply(
      isSent: message.isSent,
      onReply: onReply,
      child: GestureDetector(
        onLongPress: () => _showOptions(context),
        onDoubleTap: () => onReact('❤️'),
        child: Padding(
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
                child: Center(
                  child: Text(
                    otherUserName.isNotEmpty
                        ? otherUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment:
                  isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: isSent ? AppColors.sunglow : receivedColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isSent ? 18 : 4),
                      bottomRight: Radius.circular(isSent ? 4 : 18),
                    ),
                    border: (!isSent && isDark)
                        ? Border.all(
                            color: Colors.white.withOpacity(0.1), width: 1)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkPurple.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reply preview inside bubble
                      if (message.replyToText != null)
                        _InlineReplyPreview(
                          senderName: message.replyToSenderName ?? '',
                          text: message.replyToText!,
                          isSent: isSent,
                          isDark: isDark,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: isSent
                                ? AppColors.darkPurple
                                : receivedTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Reactions row — overlaps bubble bottom by 6px (Telegram style)
                if (grouped.isNotEmpty)
                  Transform.translate(
                    offset: const Offset(0, -6),
                    child: _ReactionsRow(
                      grouped: grouped,
                      myReaction: message.reactions[currentUserId],
                      isSent: isSent,
                      isDark: isDark,
                      onTap: (emoji) => onReact(emoji),
                    ),
                  ),
                if (grouped.isEmpty) const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: isSent
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
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
      ),
      ),    // GestureDetector
    );      // _SwipeToReply
  }
}

// ── Swipe-to-reply wrapper ────────────────────────────────────────────────────

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final bool isSent;
  final VoidCallback onReply;

  const _SwipeToReply({
    required this.child,
    required this.isSent,
    required this.onReply,
  });

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  bool _triggered = false;
  late AnimationController _returnCtrl;

  @override
  void initState() {
    super.initState();
    _returnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _returnCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    // Only allow right swipe for received, left swipe for sent
    final delta = widget.isSent ? d.delta.dx.clamp(-60.0, 0.0) : d.delta.dx.clamp(0.0, 60.0);
    setState(() {
      _dragX = (_dragX + delta).clamp(widget.isSent ? -60.0 : 0.0, widget.isSent ? 0.0 : 60.0);
      if (!_triggered && _dragX.abs() >= 50) {
        _triggered = true;
        HapticFeedback.lightImpact();
      }
    });
  }

  void _onDragEnd(DragEndDetails _) {
    if (_triggered) widget.onReply();
    _triggered = false;
    setState(() => _dragX = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        alignment: widget.isSent ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          if (_dragX.abs() > 10)
            Positioned(
              left: widget.isSent ? null : 4,
              right: widget.isSent ? 4 : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: (_dragX.abs() / 50).clamp(0.0, 1.0),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.wisteria.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.reply_rounded,
                      color: AppColors.wisteria, size: 18),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragX, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}


// ── Reply bar above text input ────────────────────────────────────────────────

class _ReplyBar extends StatelessWidget {
  final bool isDark;
  final String senderName;
  final String text;
  final VoidCallback onCancel;

  const _ReplyBar({
    required this.isDark,
    required this.senderName,
    required this.text,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // Reply icon
          Icon(Icons.reply_rounded, color: AppColors.wisteria, size: 20),
          const SizedBox(width: 8),
          // Left accent bar
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.wisteria,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wisteria,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white60
                        : AppColors.darkPurple.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Inline reply preview inside a bubble ─────────────────────────────────────

class _InlineReplyPreview extends StatelessWidget {
  final String senderName;
  final String text;
  final bool isSent;
  final bool isDark;

  const _InlineReplyPreview({
    required this.senderName,
    required this.text,
    required this.isSent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSent
        ? Colors.black.withOpacity(0.15)
        : (isDark
            ? Colors.white.withOpacity(0.1)
            : AppColors.wisteria.withOpacity(0.09));
    final accentColor = isSent
        ? (isDark ? Colors.white70 : AppColors.darkPurple.withOpacity(0.5))
        : AppColors.wisteria;
    final nameColor = accentColor;
    final textColor = isSent
        ? AppColors.darkPurple.withOpacity(0.65)
        : (isDark ? Colors.white60 : AppColors.darkPurple.withOpacity(0.55));

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: nameColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reactions row below a bubble ──────────────────────────────────────────────

class _ReactionsRow extends StatelessWidget {
  final Map<String, int> grouped;
  final String? myReaction;
  final bool isSent;
  final bool isDark;
  final void Function(String emoji) onTap;

  const _ReactionsRow({
    required this.grouped,
    required this.myReaction,
    required this.isSent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: grouped.entries.map((e) => _ReactionPill(
        emoji: e.key,
        count: e.value,
        isOwn: myReaction == e.key,
        isDark: isDark,
        onTap: () => onTap(e.key),
      )).toList(),
    );
  }
}

class _ReactionPill extends StatefulWidget {
  final String emoji;
  final int count;
  final bool isOwn;
  final bool isDark;
  final VoidCallback onTap;

  const _ReactionPill({
    required this.emoji,
    required this.count,
    required this.isOwn,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ReactionPill> createState() => _ReactionPillState();
}

class _ReactionPillState extends State<_ReactionPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.88), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = widget.isOwn;
    final isDark = widget.isDark;

    final bgColor = isOwn
        ? AppColors.wisteria.withOpacity(isDark ? 0.32 : 0.15)
        : (isDark ? const Color(0xFF2C2C3E) : Colors.white);

    final borderColor = isOwn
        ? AppColors.wisteria.withOpacity(0.65)
        : (isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.07));

    final countColor = isOwn
        ? AppColors.wisteria
        : (isDark ? Colors.white70 : AppColors.darkPurple.withOpacity(0.65));

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji,
                  style: const TextStyle(fontSize: 16, height: 1.2)),
              const SizedBox(width: 4),
              Text(
                '${widget.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: countColor,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Emoji picker button (in bottom sheet) ─────────────────────────────────────

class _EmojiPickerBtn extends StatefulWidget {
  final String emoji;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _EmojiPickerBtn({
    required this.emoji,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_EmojiPickerBtn> createState() => _EmojiPickerBtnState();
}

class _EmojiPickerBtnState extends State<_EmojiPickerBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _ctrl.forward(from: 0).then((_) => widget.onTap());
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.selected
                ? AppColors.wisteria.withOpacity(0.18)
                : Colors.transparent,
            border: widget.selected
                ? Border.all(color: AppColors.wisteria, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(widget.emoji,
                style: const TextStyle(fontSize: 26)),
          ),
        ),
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