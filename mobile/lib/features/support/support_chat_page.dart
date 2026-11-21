import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kargozar_mobile/core/network/kargozar_api_client.dart';

const _chatNavy = Color(0xFF142B4A);
const _chatTeal = Color(0xFF168C83);
const _chatMuted = Color(0xFF64748B);

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key, required this.api});

  final KargozarApiClient api;

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_SupportMessage> _messages = [];

  Timer? _poller;
  int? _conversationId;
  bool _loading = true;
  bool _sending = false;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreConversation();
  }

  @override
  void dispose() {
    _poller?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _restoreConversation() async {
    try {
      final savedId = await widget.api.restoreGuestSupportConversationId();
      if (savedId != null) {
        _conversationId = savedId;
        await _loadMessages(showLoader: false);
        _startPolling();
      }
    } catch (error) {
      _error = _messageFor(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_conversationId != null && !_sending && !_refreshing) {
        _loadMessages(showLoader: false);
      }
    });
  }

  Future<void> _loadMessages({bool showLoader = true}) async {
    final id = _conversationId;
    if (id == null || _refreshing) return;

    _refreshing = true;
    if (showLoader && mounted) setState(() => _loading = true);
    try {
      final response = await widget.api.getGuestSupportMessages(id);
      final data = response['data'];
      final messages = data is List
          ? data
              .whereType<Map>()
              .map((item) => _SupportMessage.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : <_SupportMessage>[];
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _error = null;
      });
      _scrollToBottom();
    } on KargozarApiException catch (error) {
      if (error.statusCode == 401) {
        await widget.api.clearGuestSupportConversation();
        if (!mounted) return;
        _poller?.cancel();
        setState(() {
          _conversationId = null;
          _messages.clear();
          _error = 'گفت‌وگوی قبلی در دسترس نیست. پیام تازه‌ای ارسال کنید.';
        });
      } else if (mounted && showLoader) {
        setState(() => _error = error.message);
      }
    } catch (error) {
      if (mounted && showLoader) setState(() => _error = _messageFor(error));
    } finally {
      _refreshing = false;
      if (mounted && showLoader) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });
    _messageController.clear();

    try {
      if (_conversationId == null) {
        final response = await widget.api.startGuestSupportConversation(body);
        final data = response['data'];
        if (data is! Map) {
          throw const KargozarApiException(
            code: 'INVALID_SUPPORT_RESPONSE',
            message: 'پاسخ پشتیبانی معتبر نیست.',
            statusCode: 502,
          );
        }
        final id = int.tryParse(data['id']?.toString() ?? '');
        if (id == null) {
          throw const KargozarApiException(
            code: 'INVALID_SUPPORT_RESPONSE',
            message: 'شناسه گفت‌وگو از سرور دریافت نشد.',
            statusCode: 502,
          );
        }
        final rawMessages = data['messages'];
        final messages = rawMessages is List
            ? rawMessages
                .whereType<Map>()
                .map((item) => _SupportMessage.fromJson(
                      Map<String, dynamic>.from(item),
                    ))
                .toList()
            : <_SupportMessage>[];
        if (!mounted) return;
        setState(() {
          _conversationId = id;
          _messages
            ..clear()
            ..addAll(messages);
        });
        _startPolling();
        _scrollToBottom();
      } else {
        await widget.api.sendGuestSupportMessage(_conversationId!, body);
        await _loadMessages(showLoader: false);
      }
    } catch (error) {
      if (mounted) {
        _messageController.text = body;
        setState(() => _error = _messageFor(error));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _refresh() async {
    if (_conversationId == null) return;
    await _loadMessages(showLoader: true);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _messageFor(Object error) {
    if (error is KargozarApiException) return error.message;
    return 'ارتباط با پشتیبانی برقرار نشد. اتصال اینترنت را بررسی و دوباره تلاش کنید.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'گفت‌وگو با پشتیبانی',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'به‌روزرسانی پیام‌ها',
            onPressed: _conversationId == null || _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFE8F3F2),
                    child: Icon(Icons.support_agent, color: _chatTeal),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'پشتیبانی کارگزار',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'سؤالتان را بنویسید؛ پاسخ‌ها در همین گفت‌وگو نمایش داده می‌شوند.',
                          style: TextStyle(
                            color: _chatMuted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading && _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) =>
                              _MessageBubble(message: _messages[index]),
                        ),
            ),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 12,
                  ),
                ),
              ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.forum_outlined, size: 48, color: _chatMuted),
            SizedBox(height: 12),
            Text(
              'چطور می‌توانیم راهنمایی‌تان کنیم؟',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            SizedBox(height: 7),
            Text(
              'پیام اول را ارسال کنید تا گفت‌وگوی پشتیبانی آغاز شود.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _chatMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.newline,
              enabled: !_sending,
              decoration: InputDecoration(
                hintText: 'پیام خود را بنویسید...',
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            width: 48,
            child: FilledButton(
              onPressed: _sending ? null : _sendMessage,
              style: FilledButton.styleFrom(
                backgroundColor: _chatNavy,
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.senderType == 'customer';
    final label = switch (message.senderType) {
      'customer' => 'شما',
      'staff' => 'کارشناس پشتیبانی',
      _ => 'دستیار کارگزار',
    };
    final time = _formatTime(message.createdAt);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .82,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 8),
          decoration: BoxDecoration(
            color: mine ? _chatNavy : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: mine ? Colors.white70 : _chatTeal,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.body,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: mine ? Colors.white : const Color(0xFF1F2937),
                  height: 1.55,
                ),
              ),
              if (time.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    time,
                    style: TextStyle(
                      color: mine ? Colors.white60 : _chatMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return '';
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SupportMessage {
  const _SupportMessage({
    required this.id,
    required this.senderType,
    required this.body,
    this.createdAt,
  });

  final int id;
  final String senderType;
  final String body;
  final String? createdAt;

  factory _SupportMessage.fromJson(Map<String, dynamic> json) {
    return _SupportMessage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      senderType: json['sender_type']?.toString() ?? 'assistant',
      body: json['body']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }
}
