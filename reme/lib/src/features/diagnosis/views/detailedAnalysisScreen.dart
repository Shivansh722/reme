import 'dart:io';
import 'package:flutter/material.dart';
import 'package:reme/src/features/shared/radiusChart.dart';

class DetailedAnalysisScreen extends StatelessWidget {
  final File? faceImage;
  final String analysisResult;
  final Map<String, int> scores;

  const DetailedAnalysisScreen({
    super.key,
    required this.faceImage,
    required this.analysisResult,
    required this.scores,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16 ),
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Detailed Skin Analysis'),
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        // ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const Text(
              //   'Premium Analysis Report',
              //   style: TextStyle(
              //     fontSize: 28,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              const SizedBox(height: 16),
              
              // Enhanced radar chart
              Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomRadarChart(
                    values: [
                      scores['pores'] ?? 0,
                      scores['pimples'] ?? 0,
                      scores['redness'] ?? 0,
                      scores['firmness'] ?? 0,
                      scores['sagging'] ?? 0,
                      scores['skin grade'] ?? 0,
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

                Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('肌スコア'),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${scores['skin grade'] ?? 0}',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: '/100',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Container(
                  height: 60,
                  width: 1,
                  color: Colors.grey[300],
                ),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('肌年齢'),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${scores['skin age'] ?? 0}',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: '歳',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
              
              const SizedBox(height: 32),

              // Skin Points Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skin Condition Points',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...[
                    {'title': 'たるみ', 'score': scores['sagging'] ?? 82, 'color': Colors.orange},
                    {'title': '毛穴', 'score': scores['pores'] ?? 82, 'color': Colors.orange},
                    {'title': 'シミ', 'score': scores['dark spots'] ?? 82, 'color': Colors.orange},
                    {'title': '赤み', 'score': scores['redness'] ?? 82, 'color': Colors.red},
                    {'title': '炎症', 'score': scores['pimples'] ?? 82, 'color': Colors.orange},
                    {'title': 'ハリ', 'score': scores['firmness'] ?? 82, 'color': Colors.green},
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: (item['color'] as Color).withOpacity(0.2),
                              child: Text(
                                '${item['score']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: item['color'] as Color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getConditionMessage(item['score'] as int),
                          style: const TextStyle(fontSize: 14),
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
                        Text(
                          _getSkinPointMessage(item['title'] as String),
                          style: const TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),

              const SizedBox(height: 32),

              // Detailed scores breakdown
              _buildDetailedScoresSection(),
              
              const SizedBox(height: 32),
              
              // Personalized recommendations
              _buildRecommendationsSection(),
              
              const SizedBox(height: 32),
              
              // Full analysis text
              _buildFullAnalysisSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedScoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Skin Assessment',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...scores.entries.map(
          (entry) => _buildScoreRow(entry.key, entry.value),
        ).toList(),
      ],
    );
  }

  Widget _buildScoreRow(String parameter, int score) {
    Color scoreColor = _getScoreColor(score);
    String assessment = _getScoreAssessment(score);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  parameter.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$score/100',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                assessment,
                style: TextStyle(
                  fontSize: 12,
                  color: scoreColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Point section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFF9F9F9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Point",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '入浴時は、お湯の温度を40度以下に設定し、10〜15分程度を目安にしましょう。長時間の入浴や熱すぎるお湯は、皮膚への負担となる可能性があります。',
                style: const TextStyle(color: Colors.black87, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personalized Recommendations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...( _generateRecommendations().map(
          (rec) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(child: Text(rec)),
              ],
            ),
          ),
        ).toList()),
      ],
    );
  }

  Widget _buildFullAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete Analysis',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            analysisResult,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreAssessment(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }

  List<String> _generateRecommendations() {
    List<String> recommendations = [];
    
    if ((scores['pores'] ?? 0) < 60) {
      recommendations.add('Use a gentle exfoliating cleanser to minimize pore appearance');
    }
    if ((scores['pimples'] ?? 0) < 60) {
      recommendations.add('Consider salicylic acid products for acne treatment');
    }
    if ((scores['redness'] ?? 0) < 60) {
      recommendations.add('Use products with niacinamide to reduce redness');
    }
    if ((scores['firmness'] ?? 0) < 60) {
      recommendations.add('Incorporate retinol products to improve skin firmness');
    }
    if ((scores['sagging'] ?? 0) < 60) {
      recommendations.add('Consider peptide-rich products for skin tightening');
    }
    
    return recommendations;
  }

  String _getConditionMessage(int score) {
    if (score >= 80) return '良い調子です！このまま毎日のケアを怠らずに';
    if (score >= 60) return '調子は良いですが、もう少し改善できる余地があります';
    return 'このポイントに注目したケアが必要です';
  }

  String _getSkinPointMessage(String skinType) {
    switch (skinType) {
      case 'たるみ':
        return '入浴時は、お湯の温度を40度以下に設定し、10〜15分程度を目安にしましょう。長時間の入浴や熱すぎるお湯は、皮膚への負担となる可能性があります。';
      case '毛穴':
        return '毛穴の目立ちを軽減するには、優しい角質ケアと十分な保湿が重要です。洗顔後は必ず化粧水などで保湿し、皮脂分泌のバランスを整えましょう。';
      case 'シミ':
        return '日焼け止めは必須アイテムです。SPF30以上のものを選び、外出時だけでなく室内でも使用することをお勧めします。UVカット効果のある帽子や日傘も活用しましょう。';
      case '赤み':
        return '敏感肌用の低刺激な製品を選び、アルコールや香料が含まれていないものを使用してください。洗顔は力を入れず、ぬるま湯で優しく行いましょう。';
      case '炎症':
        return 'ニキビや炎症がある場合は、触らないようにしましょう。清潔な手で優しくスキンケアを行い、抗炎症成分配合の製品を使用することをお勧めします。';
      case 'ハリ':
        return 'ハリのある肌を維持するには、コラーゲンやヒアルロン酸を含む製品が効果的です。また、顔のマッサージを行うことで血行を良くし、肌の弾力を保ちましょう。';
      default:
        return '毎日の丁寧なスキンケアを継続しましょう。十分な睡眠と水分摂取も健康的な肌には欠かせません。';
    }
  }
}