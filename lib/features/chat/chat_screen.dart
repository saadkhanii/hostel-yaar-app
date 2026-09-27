import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One-on-one conversation screen (seeker <-> warden).
///
/// Follows the same visual language as SeekerDashboard / AppBottomNav:
/// maroon gradient header with rounded bottom corners, cream/dark
/// background, sent bubbles in the maroon gradient, received bubbles
/// in the card color.
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String name;
  final String subtitle;
  final bool online;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.name,
    required this.subtitle,
    required this.online,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const maroon = Color(0xFF800020);
  static const maroonDark = Color(0xFF5C0017);

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _canSend = false;

  // TODO: replace with ChatService().streamMessages(widget.conversationId)
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hi! I saw your hostel listing — is a single room still available?',
      'isMe': true,
      'time': '9:58 AM',
      'date': 'Today',
      'status': 'read',
    },
    {
      'text': 'Yes, we have one single room open on the 2nd floor.',
      'isMe': false,
      'time': '10:02 AM',
      'date': 'Today',
    },
    {
      'text': 'Great, what\'s the monthly rent and is it inclusive of utilities?',
      'isMe': true,
      'time': '10:05 AM',
      'date': 'Today',
      'status': 'read',
    },
    {
      'text': 'Rs. 18,000/month, and yes — electricity and water are included. WiFi too.',
      'isMe': false,
      'time': '10:07 AM',
      'date': 'Today',
    },
    {
      'text': 'Sounds good. Can I come see the room this weekend?',
      'isMe': true,
      'time': '10:31 AM',
      'date': 'Today',
      'status': 'delivered',
    },
    {
      'text': 'Your booking request has been approved! Feel free to visit anytime Sat–Sun, 10am to 6pm.',
      'isMe': false,
      'time': '10:42 AM',
      'date': 'Today',
    },
  ];

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(() {
      final has = _inputCtrl.text.trim().isNotEmpty;
      if (has != _canSend) setState(() => _canSend = has);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': _nowLabel(),
        'date': 'Today',
        'status': 'sent',
      });
      _inputCtrl.clear();
      _canSend = false;
    });
    // TODO: ChatService().sendMessage(widget.conversationId, text)
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

  String _nowLabel() {
    final now = TimeOfDay.now();
    final h = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m ${now.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1D2128) : const Color(0xFFF3E6D5);
    final cardColor = isDark ? const Color(0xFF262B33) : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: true,
        // Header is full-bleed to the very top (it paints its own status-bar
        // background), everything else respects the safe area normally.
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final showDatePill = i == 0 ||
                              _messages[i - 1]['date'] != m['date'];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDatePill)
                                _DatePill(label: m['date'] as String),
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
                      ),
                    ),
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
              _HeaderAvatar(name: widget.name, size: 40),
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
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
            onTap: _canSend ? _send : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _canSend
                      ? const [maroon, maroonDark]
                      : [
                    maroon.withValues(alpha: 0.35),
                    maroonDark.withValues(alpha: 0.35),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: _canSend
                    ? [
                  BoxShadow(
                    color: maroon.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Avatar ────────────────────────────────────────────────────────
/// Local stand-in for the app's UserAvatar widget on the maroon header
/// (whose full API wasn't available here). Swap for UserAvatar directly
/// if it supports rendering initials on a translucent background.
class _HeaderAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _HeaderAvatar({required this.name, required this.size});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
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
                    color: _statusColor(Colors.white.withValues(alpha: 0.7)),
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