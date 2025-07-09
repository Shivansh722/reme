import 'package:flutter/material.dart';
import 'package:reme/src/features/chat/services/geminiService.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'message': '質問テキストが入ります質問テキストが入ります質問テキストが入ります',
      'isSender': false,
      'hasLink': false,
    },
    {
      'message': '質問テキストが入ります。\nテキストリンクなど',
      'isSender': false,
      'hasLink': true,
    },
    {
      'message': '自分の質問テキストが入ります。\nテキストリンクなど',
      'isSender': true,
      'hasLink': true,
    },
    {
      'message': '自分の質問テキスト',
      'isSender': true,
      'hasLink': false,
    },
  ];

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late GeminiService _geminiService;
  bool _isWaitingForResponse = false;

  @override
  void initState() {
    super.initState();
    // Use the same API key from .env file instead of hardcoding
    _geminiService = GeminiService(apiKey: dotenv.env['GEMINI_API_KEY'] ?? '');
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'message': text,
        'isSender': true,
        'hasLink': false,
        'isAnimating': true,
      });
      _isWaitingForResponse = true;
    });

    _textController.clear();

    // Scroll to bottom after message is added
    _scrollToBottom();

    // Remove animation flag after animation completes
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.last['isAnimating'] = false;
      });
    });

    // Get response from Gemini
    try {
      final response = await _geminiService.generateContent(text);
      setState(() {
        _messages.add({
          'message': response,
          'isSender': false,
          'hasLink': false,
          'showOptions': false, // By default don't show options
          // Only add options when needed based on your app logic
          // 'options': ['Option 1', 'Option 2', 'Option 3'], // Uncomment when needed
        });
        _isWaitingForResponse = false;
      });
      // Scroll to show the response
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'message': 'Sorry, I encountered an error: $e',
          'isSender': false,
          'hasLink': false,
        });
        _isWaitingForResponse = false;
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
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 60, left: 8, right: 8, bottom: 16),
        child: Column(
          children: [
            Expanded(
              child: ChatMessages(
                messages: _messages,
                scrollController: _scrollController,
              ),
            ),
            if (_isWaitingForResponse)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ),
              ),
            ChatInputField(
              controller: _textController,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessages extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;

  const ChatMessages({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: messages.length, // Remove the +4 to show only messages
      itemBuilder: (context, index) {
        final message = messages[index];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChatBubble(
              message: message['message'],
              isSender: message['isSender'],
              hasLink: message['hasLink'] ?? false,
              isAnimating: message['isAnimating'] ?? false,
            ),
            // Only show options for received messages (AI responses)
            if (!message['isSender'] && message['showOptions'] == true)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: message['options']?.map<Widget>((option) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RadioOption(text: option),
                    )
                  )?.toList() ?? [],
                ),
              ),
          ],
        );
      },
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSender;
  final bool hasLink;
  final bool isAnimating;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSender,
    this.hasLink = false,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isSender
        ? isAnimating
            ? Colors.pinkAccent
            : const Color(0xFFFEEBEE)
        : const Color(0xFFF7F8FA);

    final textColor = isSender && isAnimating ? Colors.white : Colors.black87;
    final align = isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = isSender
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Column(
      crossAxisAlignment: align,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
          ),
          child: hasLink
              ? RichText(
                  text: TextSpan(
                    style: TextStyle(color: textColor, fontSize: 14),
                    children: [
                      TextSpan(text: message.replaceAll('テキストリンクなど', '')),
                      TextSpan(
                        text: 'テキストリンクなど',
                        style: TextStyle(color: isAnimating ? Colors.white : Colors.blue),
                      ),
                    ],
                  ),
                )
              : Text(
                  message,
                  style: TextStyle(fontSize: 14, color: textColor),
                ),
        ),
      ],
    );
  }
}

class RadioOption extends StatelessWidget {
  final String text;
  const RadioOption({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        const Icon(Icons.radio_button_unchecked, size: 20),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '質問を入力してください',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.pinkAccent),
            onPressed: () {
              onSend(controller.text);
            },
          ),
        ],
      ),
    );
  }
}
