import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'main.dart'; // To access navigatorKey

// ==========================================
// 1. THE DRAGGABLE BUTTON OVERLAY
// ==========================================
class AIAssistantOverlay extends StatefulWidget {
  final Widget child;
  const AIAssistantOverlay({super.key, required this.child});

  @override
  State<AIAssistantOverlay> createState() => _AIAssistantOverlayState();
}

class _AIAssistantOverlayState extends State<AIAssistantOverlay> {
  Offset _position = const Offset(300, 600);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size;
    _position = Offset(size.width - 80, size.height - 150);
  }

  void _showAIModal() {
    showModalBottomSheet(
      context: navigatorKey.currentContext!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allows the modal to be taller for chat
      builder: (context) {
        return Padding(
          // This pushes the chat up when the phone keyboard opens
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: const AIChatModal(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                double newX = _position.dx + details.delta.dx;
                double newY = _position.dy + details.delta.dy;
                newX = newX.clamp(0.0, size.width - 60.0);
                newY = newY.clamp(0.0, size.height - 100.0);
                _position = Offset(newX, newY);
              });
            },
            onTap: _showAIModal,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C9A7), Color(0xFF005C97)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF005C97).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 2. THE CHAT WINDOW (BOTTOM SHEET)
// ==========================================
class AIChatModal extends StatefulWidget {
  const AIChatModal({super.key});

  @override
  State<AIChatModal> createState() => _AIChatModalState();
}

class _AIChatModalState extends State<AIChatModal> {
  late ChatSession _chatSession;
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startChatAndGetInitialSummary();
  }

  Future<void> _startChatAndGetInitialSummary() async {
    setState(() => _isLoading = true);

    try {
      // ⚠️ DON'T FORGET TO PASTE YOUR KEY HERE AGAIN!
      const apiKey = 'AIzaSyC6_Z2a3t0K6e4F5obREgGKgMMwE04N_OA'; 
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey); 
      
      // We start a "Session" instead of a one-off request
      _chatSession = model.startChat();

      const turbidity = 0.5;
      const tds = 150;
      const temp = 24.5;

      final prompt = '''
        You are a smart water quality assistant for the SmartPure app. 
        The current water readings are:
        - Turbidity: $turbidity NTU
        - TDS: $tds ppm
        - Temperature: $temp °C
        
        Write a friendly, 2-to-3 sentence summary explaining if their water is safe. 
        Do not use complex jargon. End by offering to answer any follow-up questions.
      ''';

      final response = await _chatSession.sendMessage(Content.text(prompt));
      
      setState(() {
        _messages.add({'role': 'ai', 'text': response.text ?? "Summary failed."});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': "Network error. Please check your API key."});
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _chatSession.sendMessage(Content.text(text));
      setState(() {
        _messages.add({'role': 'ai', 'text': response.text ?? "Error getting response."});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': "Error: Could not send message."});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85, 
      ),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Little drag handle at the top
          Container(
            width: 40, height: 5,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 15),
          
          // Header
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF00C9A7), size: 28),
              SizedBox(width: 12),
              Text(
                'Smart Insights',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          const Divider(height: 20),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF005C97) : const Color(0xFF00C9A7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                        bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(fontSize: 15, height: 1.4, color: isUser ? Colors.white : const Color(0xFF1A1A1A)),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading Indicator for replies
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            ),

          // The Text Input Box at the bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: "Ask a follow-up question...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(), // Send when hitting enter
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF005C97)),
                  onPressed: _sendMessage, // Send when clicking the icon
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}