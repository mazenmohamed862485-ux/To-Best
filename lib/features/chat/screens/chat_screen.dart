// lib/features/chat/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/tb_snackbar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _rooms = ['general', 'coach', 'announcements', 'support'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _rooms.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user;

    final roomLabels = [
      l['generalChat'],
      l['coachChat'],
      l['announcements'],
      l['supportChat'],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l['chat']),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: roomLabels.map((r) => Tab(text: r)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: _rooms
            .map((room) => _RoomView(roomId: room, user: user))
            .toList(),
      ),
    );
  }
}

class _RoomView extends ConsumerStatefulWidget {
  final String roomId;
  final dynamic user;
  const _RoomView({required this.roomId, this.user});
  @override
  ConsumerState<_RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends ConsumerState<_RoomView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollTimer;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String _lastTs = '';
  Map<String, dynamic>? _pinned;
  Map<String, dynamic>? _replyTo;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    _poll();
  }

  Future<void> _loadLocal() async {
    final db = ref.read(localDbProvider);
    final msgs = await db.getMessages(widget.roomId);
    if (mounted) setState(() { _messages = msgs; _loading = false; });
  }

  void _poll() {
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _fetchNew());
    _fetchNew();
  }

  Future<void> _fetchNew() async {
    final api = ref.read(apiClientProvider);
    final db = ref.read(localDbProvider);
    final newMsgs = await api.fetchNewMessages(widget.roomId, _lastTs);
    for (final m in newMsgs) {
      await db.upsertMessage(widget.roomId, m);
      final ts = m['timestamp']?.toString() ?? '';
      if (ts.compareTo(_lastTs) > 0) _lastTs = ts;
    }
    if (newMsgs.isNotEmpty && mounted) {
      final all = await db.getMessages(widget.roomId);
      setState(() => _messages = all);
      _scrollToBottom();
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

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.user;

    return Column(
      children: [
        // Pinned message
        if (_pinned != null) _PinnedBanner(msg: _pinned!, isDark: isDark),

        // Messages list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.primaryGreen))
              : _messages.isEmpty
                  ? Center(child: Text(l['noData']))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = _messages[i];
                        final isMe = msg['senderUid'] == user?.uid;
                        return _MessageBubble(
                          msg: msg,
                          isMe: isMe,
                          isDark: isDark,
                          isAdmin: user?.isAdmin ?? false,
                          onReply: () => setState(() => _replyTo = msg),
                          onDelete: user?.isAdmin == true
                              ? () => _deleteMsg(msg['id']?.toString() ?? '')
                              : null,
                          onPin: user?.isAdmin == true
                              ? () => _pinMsg(msg)
                              : null,
                        );
                      },
                    ),
        ),

        // Reply bar
        if (_replyTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.primaryGreen.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.reply, size: 16, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        _replyTo!['text']?.toString().substring(0, 50) ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12))),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _replyTo = null),
                ),
              ],
            ),
          ),

        // Input bar
        if (user?.chatBanned != true)
          _InputBar(
            controller: _msgCtrl,
            l: l,
            isDark: isDark,
            onSend: _sendMsg,
          ),
      ],
    );
  }

  Future<void> _sendMsg() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    final user = widget.user;
    if (user == null) return;

    final msg = {
      'id': '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
      'roomId': widget.roomId,
      'senderUid': user.uid,
      'senderName': user.name,
      'senderPic': user.pictureUrl,
      'text': text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (_replyTo != null) 'replyTo': _replyTo,
    };

    // Optimistic UI
    setState(() {
      _messages.add(msg);
      _replyTo = null;
    });
    _scrollToBottom();

    // Save locally
    final db = ref.read(localDbProvider);
    await db.upsertMessage(widget.roomId, msg);

    // Send to server
    final api = ref.read(apiClientProvider);
    await api.sendMessage(widget.roomId, msg);
  }

  Future<void> _deleteMsg(String msgId) async {
    final api = ref.read(apiClientProvider);
    final ok = await api.deleteMessage(widget.roomId, msgId);
    if (ok) {
      final db = ref.read(localDbProvider);
      await db.deleteMessage(msgId);
      setState(() => _messages.removeWhere((m) => m['id'] == msgId));
    }
  }

  Future<void> _pinMsg(Map<String, dynamic> msg) async {
    final api = ref.read(apiClientProvider);
    await api.pinMessage(widget.roomId, msg);
    setState(() => _pinned = msg);
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final bool isDark;
  final bool isAdmin;
  final VoidCallback onReply;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.isDark,
    required this.isAdmin,
    required this.onReply,
    this.onDelete,
    this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final text = msg['text']?.toString() ?? '';
    final sender = msg['senderName']?.toString() ?? '';
    final ts = msg['timestamp'];
    final time = ts != null
        ? DateTime.fromMillisecondsSinceEpoch(
                int.tryParse(ts.toString()) ?? 0)
            .toLocal()
        : DateTime.now();
    final replyTo = msg['replyTo'] as Map?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
              child: Text(
                  sender.isNotEmpty ? sender[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primaryGreen
                      : (isDark
                          ? AppColors.darkCard
                          : AppColors.lightCard),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(sender,
                          style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    if (replyTo != null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          replyTo['text']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 2,
                        ),
                      ),
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : null,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white70
                            : AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () { Navigator.pop(context); onReply(); },
            ),
            if (onPin != null)
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: const Text('Pin'),
                onTap: () { Navigator.pop(context); onPin!(); },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () { Navigator.pop(context); onDelete!(); },
              ),
          ],
        ),
      ),
    );
  }
}

class _PinnedBanner extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isDark;
  const _PinnedBanner({required this.msg, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.primaryGreen.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.push_pin, size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg['text']?.toString() ?? '',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations l;
  final bool isDark;
  final VoidCallback onSend;
  const _InputBar({
    required this.controller,
    required this.l,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
            top: BorderSide(
                color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: l['typeMessage'],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
