import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/network/kargozar_api_client.dart';

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key, required this.api});
  final KargozarApiClient api;

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  Timer? _poller;
  int? _conversationId;
  bool _loading = true;
  bool _sending = false;
  bool _polling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreConversation();
    _poller = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _poller?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _restoreConversation() async {
    try {
      final id = await widget.api.restoreGuestSupportConversationId();
      if (id != null) {
        _conversationId = id;
        await _refresh();
      }
    } on KargozarApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'بازیابی گفت‌وگو انجام نشد.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _readMessages(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> _refresh() async {
    final id = _conversationId;
    if (id == null || _polling || _sending) return;
    _polling = true;
    try {
      final response = await widget.api.getGuestSupportMessages(id);
      final data = response['data'];
      final messages = _readMessages(data);
      if (!mounted) return;
      final changed = messages.length != _messages.length ||
          (messages.isNotEmpty && _messages.isNotEmpty &&
              messages.last['id'] != _messages.last['id']);
      if (changed) {
        setState(() {
          _messages
            ..clear()
            ..addAll(messages);
          _error = null;
        });
        _scrollToBottom();
      }
    } on KargozarApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 404) {
        await widget.api.clearGuestSupportConversation();
        _conversationId = null;
        if (mounted) setState(() => _messages.clear());
      } else if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'دریافت پیام‌های جدید ممکن نشد.');
    } finally {
      _polling = false;
    }
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    _composer.clear();
    try {
      Map<String, dynamic> response;
      if (_conversationId == null) {
        response = await widget.api.startGuestSupportConversation(body);
        final data = response['data'];
        if (data is Map) {
          final id = int.tryParse(data['id']?.toString() ?? '');
          if (id != null) _conversationId = id;
          _messages
            ..clear()
            ..addAll(_readMessages(data['messages']));
        }
      } else {
        await widget.api.sendGuestSupportMessage(_conversationId!, body);
        response = await widget.api.getGuestSupportMessages(_conversationId!);
        _messages
          ..clear()
          ..addAll(_readMessages(response['data']));
      }
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    } on KargozarApiException catch (e) {
      if (mounted) {
        _composer.text = body;
        _composer.selection = TextSelection.collapsed(offset: body.length);
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        _composer.text = body;
        _composer.selection = TextSelection.collapsed(offset: body.length);
        setState(() => _error = 'ارسال پیام انجام نشد. اتصال اینترنت را بررسی کنید.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گفت‌وگوی آنلاین کارگزار'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFFF1F1),
            child: const Text(
              'بدون نیاز به ورود یا کد تأیید پیام بفرستید. دستیار پاسخ می‌دهد و در صورت نیاز، گفت‌وگو برای کارشناس قابل پیگیری است.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, height: 1.7, color: Color(0xFF7F1D1D)),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(28),
                          child: Text(
                            'سلام. سؤال یا موضوعی را که درباره خدمات کارگزار دارید بنویسید تا راهنمایی‌تان کنیم.',
                            textAlign: TextAlign.center,
                            style: TextStyle(height: 1.9, color: Color(0xFF64748B)),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(14),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final sender = message['sender_type']?.toString();
                          final mine = sender == 'customer';
                          final assistant = sender == 'assistant';
                          return Align(
                            alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                              decoration: BoxDecoration(
                                color: mine
                                    ? const Color(0xFFE30613)
                                    : assistant
                                        ? const Color(0xFFF1F5F9)
                                        : const Color(0xFFE8F5F2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mine ? 'شما' : assistant ? 'دستیار هوشمند کارگزار' : 'کارشناس کارگزار',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: mine ? Colors.white70 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    message['body']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.8,
                                      color: mine ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'پیام خود را بنویسید...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    tooltip: 'ارسال پیام',
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
