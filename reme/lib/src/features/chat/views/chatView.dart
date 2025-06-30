import 'package:flutter/material.dart';

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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'message': text,
        'isSender': true,
        'hasLink': false,
        'isAnimating': true,
      });
    });

    _textController.clear();

    // Scroll to bottom after message is added
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Remove animation flag after animation completes
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.last['isAnimating'] = false;
      });
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
      itemCount: messages.length + 4, // Adding space for radio options
      itemBuilder: (context, index) {
        if (index < messages.length) {
          return ChatBubble(
            message: messages[index]['message'],
            isSender: messages[index]['isSender'],
            hasLink: messages[index]['hasLink'] ?? false,
            isAnimating: messages[index]['isAnimating'] ?? false,
          );
        } else if (index == messages.length) {
          // Adding radio options after messages
          return const RadioOption(text: '選択項目表示');
        } else if (index == messages.length + 1) {
          return const RadioOption(text: '選択項目表示');
        } else if (index == messages.length + 2) {
          return const RadioOption(text: '選択項目表示');
        } else {
          return const RadioOption(text: '選択項目表示');
        }
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
