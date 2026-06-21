import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final user = SupabaseService.currentUser;
    final userName =
        user?.userMetadata?['username']?.toString().split(' ').first ?? 'there';
    setState(() {
      _messages.add(ChatMessage(
        text:
            "Hi $userName! 👋 I'm EcoBot, your AI assistant for waste management and recycling. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '',
            isUser: false,
            timestamp: DateTime.now(),
            isQuickSuggestions: true,
          ));
        });
        _scrollToBottom();
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final msg = text.trim();
    setState(() {
      _messages.add(ChatMessage(text: msg, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();
    _saveMessageToHistory(msg, true);
    Future.delayed(const Duration(milliseconds: 800), () => _processAIResponse(msg));
  }

  void _processAIResponse(String userMessage) async {
    try {
      final response = await AIService.sendMessage(userMessage);
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
        });
        _saveMessageToHistory(response, false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: "🤖 I'm having trouble connecting. Please try again!",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    }
    _scrollToBottom();
  }

  Future<void> _saveMessageToHistory(String text, bool isUser) async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) return;
    try {
      await SupabaseService.client.from('ai_chat_history').insert({
        'user_id': uid,
        'message': text,
        'is_user': isUser,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showHistory() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _AIChatHistoryPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 16,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EcoBot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text('AI Assistant', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Online', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            tooltip: 'Chat History',
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                if (message.isQuickSuggestions) return _buildQuickSuggestions();
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      onSubmitted: _sendMessage,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Row(
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final val = (_typingAnimationController.value - delay).clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: Transform.translate(
                        offset: Offset(0, -8 * (val < 0.5 ? val * 2 : (1 - val) * 2)),
                        child: Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text('EcoBot is typing...', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      '♻️ How to sort plastic waste?',
      '🏖️ Beach cleanup schedule',
      '📱 How to report waste?',
      '📍 Find recycling centers',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Quick suggestions:', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) => GestureDetector(
              onTap: () => _sendMessage(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF4CAF50)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s, style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Chat History Page
// ─────────────────────────────────────────────
class _AIChatHistoryPage extends StatefulWidget {
  const _AIChatHistoryPage();

  @override
  State<_AIChatHistoryPage> createState() => _AIChatHistoryPageState();
}

class _AIChatHistoryPageState extends State<_AIChatHistoryPage> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final data = await SupabaseService.client
          .from('ai_chat_history')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(100);
      setState(() {
        _history = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all your chat history with EcoBot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final uid = SupabaseService.currentUser?.id;
      if (uid == null) return;
      await SupabaseService.client.from('ai_chat_history').delete().eq('user_id', uid);
      setState(() => _history = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chat History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
              tooltip: 'Clear history',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No chat history yet', style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text('Your conversations will appear here', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (_, i) {
                    final item = _history[i];
                    final isUser = item['is_user'] == true;
                    final time = DateTime.tryParse(item['created_at'] ?? '')?.toLocal();
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF4CAF50) : Colors.white,
                          borderRadius: BorderRadius.circular(14).copyWith(
                            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(14),
                            bottomLeft: isUser ? const Radius.circular(14) : const Radius.circular(4),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['message'] ?? '',
                              style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 13, height: 1.4),
                            ),
                            if (time != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: isUser ? Colors.white60 : Colors.grey[400], fontSize: 9),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isQuickSuggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isQuickSuggestions = false,
  });
}
