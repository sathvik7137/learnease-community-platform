import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<_Message> _messages = [];
  AIService? _aiService;
  bool _loading = false;

  static const _storageKey = 'chat_messages_v1';

  @override
  void initState() {
    super.initState();
    // Defer AIService creation to avoid accessing dotenv before it's loaded on web.
    // We'll create it lazily when the user sends the first message.
    // If creation fails, we'll show a user-friendly error message instead of crashing.
    try {
      // attempt a safe creation; this may still use safeEnv which doesn't throw
      _aiService = AIService.fromEnv();
    } catch (_) {
      // Leave uninitialized — we'll handle this when sending messages.
    }
    _loadMessages();
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Message(text, isUser: true));
      _controller.clear();
      _loading = true;
    });

    try {
      // Ensure AIService exists; create lazily if needed.
      _aiService ??= AIService.fromEnv();
      final reply = await _aiService!.sendMessage(text);
      setState(() {
        _messages.add(_Message(reply, isUser: false));
      });
      await _saveMessages();
    } catch (e) {
      setState(() {
        // Provide more helpful guidance if dotenv wasn't initialized.
        final msg = e.toString();
        if (msg.contains('NotInitializedError') || msg.contains('Could not load .env')) {
          _messages.add(_Message('AI not configured for web. The app expects a server-side Gemini proxy (see project docs).', isUser: false));
        } else {
          // If API returned HTTP error (proxy/Gemini), show a friendly fallback
          final err = e.toString();
          if (err.contains('Proxy AI error') || err.contains('ClientException') || err.contains('GEMINI_API_KEY')) {
            _messages.add(_Message("Sorry, I couldn't reach the AI service.\nFallback reply: I can still help with basic tips — try asking about Java basics or DBMS concepts.", isUser: false));
          } else {
            _messages.add(_Message('Error: ${e.toString()}', isUser: false));
          }
        }
      });
      await _saveMessages();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _messages.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(_storageKey, list);
    } catch (_) {
      // ignore save errors
    }
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey) ?? [];
      final restored = list.map((s) {
        try {
          final map = jsonDecode(s) as Map<String, dynamic>;
          return _Message.fromJson(map);
        } catch (_) {
          return null;
        }
      }).whereType<_Message>().toList();
      if (restored.isNotEmpty) {
        setState(() {
          _messages.clear();
          _messages.addAll(restored);
        });
      }
    } catch (_) {
      // ignore load errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: m.isUser ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m.text,
                      style: TextStyle(color: m.isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _send,
                    child: const Icon(Icons.send),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  _Message(this.text, {this.isUser = false});

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
      };

  static _Message fromJson(Map<String, dynamic> m) {
    return _Message(m['text']?.toString() ?? '', isUser: m['isUser'] == true);
  }
}
