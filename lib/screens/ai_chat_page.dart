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
    final userName = user?.userMetadata?['username']?.toString().split(' ').first ?? 'there';
    
    setState(() {
      _messages.add(ChatMessage(
        text: "Hi $userName! 👋 I'm EcoBot, your AI assistant for waste management and recycling. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _showQuickSuggestions();
  }

  void _showQuickSuggestions() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "",
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

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI processing delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      _processAIResponse(text);
    });
  }

  void _processAIResponse(String userMessage) async {
    try {
      // Use real AI API - this will now handle fallbacks internally
      final response = await AIService.sendMessage(userMessage);
      
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      // Final fallback if everything fails
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "🤖 I'm having trouble connecting right now. Please check your internet connection and try again!",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
    
    _scrollToBottom();
  }

  String _getAIResponse(String message) {
    // Waste Sorting Questions
    if (message.contains('plastic') || message.contains('bottle') || message.contains('bag')) {
      return "🔵 **Plastic Waste Guidelines:**\n\n• Clean all plastic containers before recycling\n• Remove caps and labels when possible\n• Plastic bottles: Rinse and crush to save space\n• Plastic bags: Take to special collection points\n• Avoid: Dirty or food-contaminated plastics\n\n📍 **Nearest Center:** EcoRecycle Cameroon - Douala\n📞 Contact: +237 6XX XXX XXX";
    }
    
    if (message.contains('organic') || message.contains('food') || message.contains('compost')) {
      return "🟢 **Organic Waste Management:**\n\n• Fruit peels, vegetable scraps ✅\n• Coffee grounds, tea bags ✅\n• Garden waste, leaves ✅\n• Avoid: Meat, dairy, oily foods ❌\n\n🏠 **Home Composting:**\n• Layer green (nitrogen) + brown (carbon) materials\n• Keep moist but not waterlogged\n• Turn every 2-3 weeks\n• Ready in 3-6 months!";
    }

    if (message.contains('electronic') || message.contains('phone') || message.contains('computer') || message.contains('battery')) {
      return "⚡ **Electronic Waste (E-Waste):**\n\n• Never throw in regular trash! ⚠️\n• Contains valuable metals for recycling\n• May contain hazardous materials\n\n📱 **Accepted Items:**\n• Phones, tablets, computers\n• Batteries (all types)\n• Cables and chargers\n\n🏢 **Specialist Center:** Green Future Ltd - Yaoundé\n📞 +237 6XX XXX XXX";
    }

    if (message.contains('hazardous') || message.contains('chemical') || message.contains('paint') || message.contains('dangerous')) {
      return "⚠️ **Hazardous Waste - Special Handling Required:**\n\n🚫 **Never mix or dispose in regular trash!**\n\n• Paint, solvents, chemicals\n• Medical waste, syringes\n• Car batteries, motor oil\n• Pesticides, cleaning products\n\n🏥 **Safety First:**\n• Wear gloves and protection\n• Keep in original containers\n• Contact local authorities for disposal\n• Store away from children/pets";
    }

    // App Usage Questions
    if (message.contains('report') || message.contains('post') || message.contains('waste issue')) {
      return "📱 **How to Report Waste Issues:**\n\n1️⃣ Tap 'Post' tab in bottom navigation\n2️⃣ Select 'Post a Request'\n3️⃣ Choose location on map\n4️⃣ Enter your phone number\n5️⃣ Set date/time of issue\n6️⃣ Describe the problem\n7️⃣ Submit and track status\n\n💡 **Pro Tip:** Be specific in descriptions for faster response!";
    }

    if (message.contains('dashboard') || message.contains('volunteer') || message.contains('campaign')) {
      return "🎯 **Accessing Your Dashboard:**\n\n👤 **For Volunteers/Organizations:**\n• Go to Profile → Dashboard\n• Create campaigns, manage volunteers\n• Track environmental impact\n\n🏛️ **For Government/Hysacam:**\n• Access specialized dashboard\n• Monitor waste reports by location\n• Schedule patrol routes\n\n📊 **Features:** Real-time data, analytics, team coordination";
    }

    if (message.contains('beach') || message.contains('limbe') || message.contains('cleanup')) {
      return "🏖️ **Limbe Beach Cleanup Info:**\n\n📅 **Schedule:**\n• Every Saturday at 6:00 AM\n• Meet at Mile 1 main entrance\n• Special events during World Environment Day\n\n🎒 **What to Bring:**\n• Closed-toe shoes (no sandals!)\n• Sun hat and sunscreen\n• Reusable water bottle\n• Gloves (provided if needed)\n\n🌊 **Impact:** Help protect marine life and keep our beaches beautiful!";
    }

    // Recycling Centers
    if (message.contains('center') || message.contains('location') || message.contains('where') || message.contains('recycle')) {
      return "📍 **Recycling Centers in Cameroon:**\n\n🏭 **EcoRecycle Cameroon - Douala**\n• Plastic & Metal recycling\n• 📞 +237 6XX XXX XXX\n\n💻 **Green Future Ltd - Yaoundé**\n• Electronic waste specialist\n• 📞 +237 6XX XXX XXX\n\n📄 **Douala Recycling Co**\n• Paper & Cardboard\n• 📞 +237 6XX XXX XXX\n\n💡 **Tip:** Call ahead to confirm hours and accepted materials!";
    }

    // Environmental Tips
    if (message.contains('tip') || message.contains('help environment') || message.contains('reduce waste')) {
      return "🌱 **Daily Eco Tips:**\n\n♻️ **Reduce:**\n• Use reusable bags and bottles\n• Buy products with less packaging\n• Choose quality items that last longer\n\n🔄 **Reuse:**\n• Repurpose containers for storage\n• Donate items instead of throwing away\n• Repair instead of replacing\n\n🌍 **Recycle:**\n• Sort waste properly\n• Clean containers before recycling\n• Learn your local recycling rules\n\n💚 **Small actions, big impact!**";
    }

    // Profile and Settings
    if (message.contains('profile') || message.contains('account') || message.contains('settings')) {
      return "👤 **Profile & Settings Help:**\n\n📝 **Edit Profile:**\n• Tap profile picture to change photo\n• Update username and contact info\n• Set role (User/Volunteer/Government)\n\n🔔 **Notifications:**\n• Enable for waste report updates\n• Get campaign notifications\n• Beach cleanup reminders\n\n⚙️ **Settings:** Access through Profile → Settings\n• Privacy controls, language, dark mode";
    }

    // General Help
    if (message.contains('help') || message.contains('support') || message.contains('problem')) {
      return "🆘 **Need Help?**\n\n📧 **Contact Support:**\n• Email: support@keepitclean.cm\n• Phone: +237 6XX XXX XXX\n• WhatsApp: +237 6XX XXX XXX\n\n🔧 **Common Issues:**\n• App crashes → Update to latest version\n• Can't upload photos → Feature coming soon\n• Wrong location → Double-tap location field\n\n💬 **I'm here 24/7 to help with waste management questions!**";
    }

    // Default response with suggestions
    return "🤔 I'd love to help! I can assist you with:\n\n♻️ **Waste Sorting** - How to properly sort different materials\n📱 **App Features** - Navigate and use all app functions\n🏖️ **Beach Cleanups** - Limbe cleanup schedules and info\n📍 **Recycling Centers** - Find nearby facilities\n🌱 **Eco Tips** - Daily environmental advice\n\nWhat would you like to know more about?";
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EcoBot AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Waste Management Expert', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Online', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
        ),

        // Messages List
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
              if (message.isQuickSuggestions) {
                return _buildQuickSuggestions();
              }
              
              return _buildMessageBubble(message);
            },
          ),
        ),

        // Input Area
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
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
                    decoration: InputDecoration(
                      hintText: AIService.isConfigured() 
                      ? 'Ask me anything about waste, environment, or general questions...'
                      : 'Ask about waste sorting, recycling...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintStyle: const TextStyle(color: Colors.grey),
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
          color: message.isUser ? const Color(0xFF4CAF50) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
          ),
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
              _formatTime(message.timestamp),
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
          color: Colors.grey[100],
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
                    final animationValue = (_typingAnimationController.value - delay).clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: Transform.translate(
                        offset: Offset(0, -10 * (animationValue < 0.5 ? animationValue * 2 : (1 - animationValue) * 2)),
                        child: Container(
                          width: 6,
                          height: 6,
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
            children: suggestions.map((suggestion) => GestureDetector(
              onTap: () => _sendMessage(suggestion),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4CAF50)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  suggestion,
                  style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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