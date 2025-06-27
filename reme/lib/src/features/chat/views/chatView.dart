import 'package:flutter/material.dart';


class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 60, left: 8, right: 8, bottom: 16),
        child: Column(
          children: [
           
            
            const Expanded(child: ChatMessages()),
            const ChatInputField(),
          ],
        ),
      ),
    );
  }
}

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: const [
        ChatBubble(
          message:
              '質問テキストが入ります質問テキストが入ります質問テキストが入ります',
          isSender: false,
        ),
        ChatBubble(
          message: '質問テキストが入ります。\nテキストリンクなど',
          isSender: false,
          hasLink: true,
        ),
        RadioOption(text: '選択項目表示'),
        RadioOption(text: '選択項目表示'),
        RadioOption(text: '選択項目表示'),
        RadioOption(text: '選択項目表示'),
        ChatBubble(
          message: '自分の質問テキストが入ります。\nテキストリンクなど',
          isSender: true,
          hasLink: true,
        ),
        ChatBubble(
          message: '自分の質問テキスト',
          isSender: true,
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isSender;
  final bool hasLink;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isSender,
    this.hasLink = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isSender ? const Color(0xFFFEEBEE) : const Color(0xFFF7F8FA);
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
        Container(
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
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    children: [
                      TextSpan(text: message.replaceAll('テキストリンクなど', '')),
                      const TextSpan(
                        text: 'テキストリンクなど',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                )
              : Text(message, style: const TextStyle(fontSize: 14)),
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
  const ChatInputField({super.key});

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
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
