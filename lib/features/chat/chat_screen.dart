import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';
import '../../shared/widgets/avatar.dart';

/// One-on-one conversation screen (seeker <-> warden).
///
/// Loads the real message history from the backend on open, polls every
/// few seconds for new messages, and posts sends back through the API.
/// The UI structure (maroon gradient header, sent/received bubbles, date
/// pills, delivery ticks) is unchanged from the original mock version.
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String name;
  final String subtitle;
  final bool online;
  final String? avatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.name,
    required this.subtitle,
    required this.online,
    this.avatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const maroon = Color(0xFF800020);
  static const maroonDark = Color(0xFF5C0017);

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatService = ChatService();

  bool _canSend = false;
  bool _loading = true;
  bool _sending = false;
  String? _errorText;
  String? _myUserId;

  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 4);

  /// Messages in the order they should render (oldest first).
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(() {
      final has = _inputCtrl.text.trim().isNotEmpty;
      if (has != _canSend) setState(() => _canSend = has);
    });
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _myUserId = await AuthService().getUserId();
    await _loadMessages(showSpinner: true);
    if (!mounted) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _loadMessages());
  }

  /// Fetches the conversation's messages. On first call shows the
  /// loading spinner; subsequent calls are silent background refreshes
  /// so the user doesn't see flicker every 4 seconds.
  Future<void> _loadMessages({bool showSpinner = false}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _errorText = null;
      });
    }

    try {
      final msgs = await _chatService.listMessages(widget.conversationId);
      if (!mounted) return;

      final changed = _messagesChanged(msgs);
      setState(() {
        _messages = msgs;
        _loading = false;
        _errorText = null;
      });

      if (showSpinner || changed) _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Cheap comparison: length + last message id. Enough to decide whether
  /// we need to re-render and re-scroll. Avoids rebuilding on every poll
  /// when nothing has changed.
  bool _messagesChanged(List<Map<String, dynamic>> incoming) {
    if (incoming.length != _messages.length) return true;
    if (incoming.isEmpty) return false;
    final a = incoming.last['id'];
    final b = _messages.last['id'];
    return a != b;
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    // Optimistically clear the input so it feels instant.
    _inputCtrl.clear();
    setState(() => _canSend = false);

    try {
      final msg = await _chatService.sendMessage(widget.conversationId, text);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, msg];
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Formatting helpers ────────────────────────────────────────────

  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "Today" / "Yesterday" / "12 Sep" / "12 Sep 2025".
  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (local.year == now.year) {
      return '${local.day} ${_monthsShort[local.month - 1]}';
    }
    return '${local.day} ${_monthsShort[local.month - 1]} ${local.year}';
  }

  /// "10:42 AM".
  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m ${local.hour >= 12 ? 'PM' : 'AM'}';
  }

  /// Maps raw API message into the shape _MessageBubble already expects.
  Map<String, dynamic> _renderModel(Map<String, dynamic> raw) {
    final createdAt = DateTime.tryParse(raw['createdAt'] as String? ?? '') ??
        DateTime.now();
    final readAt = raw['readAt'] as String?;
    return {
      'id': raw['id'],
      'text': raw['text'] as String? ?? '',
      'isMe': raw['senderId'] == _myUserId,
      'date': _dateLabel(createdAt),
      'time': _timeLabel(createdAt),
      // 'sent' | 'delivered' | 'read' — we only have readAt from the API,
      // so anything read is 'read', anything else is 'sent'. Delivered
      // would require a separate delivery receipt.
      'status': readAt != null ? 'read' : 'sent',
    };
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final cardColor = isDark ? const Color(0xFF262B33) : Colors.white;

    final rendered = _messages.map(_renderModel).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(child: _buildBody(rendered, isDark, cardColor)),
                    _buildInputBar(isDark, cardColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      List<Map<String, dynamic>> rendered,
      bool isDark,
      Color cardColor,
      ) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(maroon),
        ),
      );
    }
    if (_errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: maroon.withValues(alpha: 0.6), size: 36),
              const SizedBox(height: 12),
              Text(
                _errorText!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: maroon.withValues(alpha: 0.75), fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _loadMessages(showSpinner: true),
                child: const Text('Retry',
                    style: TextStyle(color: maroon)),
              ),
            ],
          ),
        ),
      );
    }
    if (rendered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Say hi to start the conversation.',
            style: TextStyle(
                fontSize: 13, color: maroon.withValues(alpha: 0.55)),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: rendered.length,
      itemBuilder: (context, i) {
        final m = rendered[i];
        final showDatePill =
            i == 0 || rendered[i - 1]['date'] != m['date'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDatePill) _DatePill(label: m['date'] as String),
            _MessageBubble(
              text: m['text'] as String,
              isMe: m['isMe'] as bool,
              time: m['time'] as String,
              status: m['status'] as String?,
              isDark: isDark,
              cardColor: cardColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(8, topInset + 10, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [maroon, maroonDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Avatar(
                name: widget.name,
                imageUrl: widget.avatarUrl,
                size: 40,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                borderColor: Colors.white.withValues(alpha: 0.6),
              ),
              if (widget.online)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      border: Border.all(color: maroonDark, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  widget.online ? 'Online' : widget.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: navigate to hostel/profile detail
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, Color cardColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: attach image / file
                    },
                    icon: Icon(
                      Icons.attach_file,
                      size: 20,
                      color: maroon.withValues(alpha: 0.55),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: maroon.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _canSend && !_sending ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _canSend && !_sending
                      ? const [maroon, maroonDark]
                      : [
                    maroon.withValues(alpha: 0.35),
                    maroonDark.withValues(alpha: 0.35),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: _canSend && !_sending
                    ? [
                  BoxShadow(
                    color: maroon.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: _sending
                  ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}


// ── Date Pill ────────────────────────────────────────────────────────────
class _DatePill extends StatelessWidget {
  final String label;

  const _DatePill({required this.label});

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: maroon.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: maroon.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

// ── Message Bubble ──────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final String? status;
  final bool isDark;
  final Color cardColor;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.status,
    required this.isDark,
    required this.cardColor,
  });

  IconData get _statusIcon {
    switch (status) {
      case 'read':
        return Icons.done_all;
      case 'delivered':
        return Icons.done_all;
      default:
        return Icons.done;
    }
  }

  Color _statusColor(Color base) {
    if (status == 'read') return Colors.lightBlueAccent.shade100;
    return base;
  }

  @override
  Widget build(BuildContext context) {
    const maroon = Color(0xFF800020);
    const maroonDark = Color(0xFF5C0017);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [maroon, maroonDark],
          )
              : null,
          color: isMe ? null : cardColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: isMe ? Colors.white : maroon,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : maroon.withValues(alpha: 0.45),
                  ),
                ),
                if (isMe && status != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _statusIcon,
                    size: 13,
                    color:
                    _statusColor(Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}