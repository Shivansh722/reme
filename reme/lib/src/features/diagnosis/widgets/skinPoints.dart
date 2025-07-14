import 'package:flutter/material.dart';


class SkinCareReportApp extends StatelessWidget {
  const SkinCareReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SkinCareList(),
          ),
        ),
      ),
    );
  }
}

class SkinCareList extends StatelessWidget {
  const SkinCareList({super.key});

  final List<Map<String, dynamic>> data = const [
    {'title': 'たるみ', 'score': 82, 'color': Colors.orange},
    {'title': '毛穴', 'score': 82, 'color': Colors.orange},
    {'title': 'シミ', 'score': 82, 'color': Colors.orange},
    {'title': '赤み', 'score': 82, 'color': Colors.red},
    {'title': '炎症', 'score': 82, 'color': Colors.orange},
    {'title': 'ハリ', 'score': 82, 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: data
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SkinCareCard(
                  title: item['title'],
                  score: item['score'],
                  color: item['color'],
                ),
              ))
          .toList(),
    );
  }
}

class SkinCareCard extends StatelessWidget {
  final String title;
  final int score;
  final Color color;

  const SkinCareCard({
    super.key,
    required this.title,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.2),
              child: Text(
                '$score',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '良い調子です！このまま毎日のケアを怠らずに',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        const Text(
          'Point',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '入浴時は、お湯の温度を40度以下に設定し、10〜15分程度を目安にしましょう。長時間の入浴や熱すぎるお湯は、皮膚への負担となる可能性があります。',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
      ],
    );
  }
}
