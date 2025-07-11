import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/diagnosis/widgets/circularProg.dart';
import 'package:reme/src/features/shared/radiusChart.dart';
import 'package:reme/src/features/shared/services/firestore_service.dart';
import 'package:reme/src/features/diagnosis/widgets/historyChart.dart';
import 'package:reme/src/features/diagnosis/views/detailedAnalysisScreen.dart';

class HistoryAnalysisScreen extends StatefulWidget {
  final String? analysisResult;
  final Map<String, int>? scores;

  const HistoryAnalysisScreen({
    super.key,
    this.analysisResult,
    this.scores,
  });

  @override
  State<HistoryAnalysisScreen> createState() => _HistoryAnalysisScreenState();
}

class _HistoryAnalysisScreenState extends State<HistoryAnalysisScreen> {
  bool _isLoading = false;
  String? _loadedAnalysisResult;
  Map<String, int>? _loadedScores;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    // If we don't have scores passed directly, try to load from Firestore
    if (widget.scores == null) {
      _loadDataFromFirestore();
    }
  }

  Future<void> _loadDataFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'ログインが必要です';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final firestoreService = FirestoreService();
      final analysisData = await firestoreService.getLatestAnalysis(user.uid);
      
      if (analysisData == null) {
        setState(() {
          _errorMessage = '分析データが見つかりません。新しい肌診断を受けてください！';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _loadedAnalysisResult = analysisData['analysisResult'] as String?;
        
        // Extract scores from the saved data
        final Map<String, dynamic> savedScores = analysisData['scores'] as Map<String, dynamic>;
        _loadedScores = savedScores.map((key, value) => 
            MapEntry(key, value is int ? value : (value as num).toInt()));
            
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'データの読み込みエラー: $e';
        _isLoading = false;
      });
      print('Error loading analysis data: $e');
    }
  }
  
  void _viewSpecificAnalysisDetails(Map<String, dynamic> analysis) {
    // Convert stored scores to the expected Map<String, int> format
    final Map<String, dynamic> rawScores = analysis['scores'] as Map<String, dynamic>;
    final Map<String, int> scores = rawScores.map(
      (key, value) => MapEntry(key, value is int ? value : (value as num).toInt()),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailedAnalysisScreen(
          analysisResult: analysis['analysisResult'] as String? ?? '',
          scores: scores,
        ),
      ),
    );
  }
  
  // Get the effective data to display (either from props or loaded data)
  String get analysisResult => widget.analysisResult ?? _loadedAnalysisResult ?? '';
  Map<String, int> get scores => widget.scores ?? _loadedScores ?? {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('肌分析結果'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _loadDataFromFirestore(),
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show history chart at the top
                        SizedBox(
                          height: 350, // Adjust height as needed
                          child: SkinHistoryChart(
                            showViewMore: true,
                            maxEntries: 5,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Current score summary
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('肌スコア'),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${scores['skin grade'] ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const TextSpan(
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
                                  const Text('肌年齢'),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${scores['skin age'] ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const TextSpan(
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
                        
                        // General advice
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Point",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '入浴時は、お湯の温度を40度以下に設定し、10〜15分程度を目安にしましょう。長時間の入浴や熱すぎるお湯は、皮膚への負担となる可能性があります。',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        
                        // Skin condition points
                        const Text(
                          '肌の状態分析',
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      CustomCircularProgress(
                                        progress: (item['score'] as int).toDouble(),
                                        color: item['color'] as Color,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _getConditionMessage(item['score'] as int),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                     
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Point',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getSkinPointMessage(item['title'] as String).join('\n'),
                                      style: const TextStyle(fontSize: 14, height: 1.6),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),

                        const SizedBox(height: 32),
                        
                        // Recommendations
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

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'おすすめアドバイス',
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
          '総合分析',
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

  String _getConditionMessage(int score) {
    if (score >= 80) return '良い調子です！このまま毎日のケアを怠らずに';
    if (score >= 60) return '調子は良いですが、もう少し改善できる余地があります';
    return 'このポイントに注目したケアが必要です';
  }

  List<String> _getSkinPointMessage(String skinType) {
    switch (skinType) {
      case 'たるみ':
        return ['入浴時は、お湯の温度を40度以下に設定し、10〜15分程度を目安にしましょう。', '長時間の入浴や熱すぎるお湯は、皮膚への負担となる可能性があります。'];
      case '毛穴':
        return ['毛穴の目立ちを軽減するには、優しい角質ケアと十分な保湿が重要です。', '洗顔後は必ず化粧水などで保湿し、皮脂分泌のバランスを整えましょう。'];
      case 'シミ':
        return ['日焼け止めは必須アイテムです。SPF30以上のものを選び、外出時だけでなく室内でも使用することをお勧めします。', 'UVカット効果のある帽子や日傘も活用しましょう。'];
      case '赤み':
        return ['敏感肌用の低刺激な製品を選び、アルコールや香料が含まれていないものを使用してください。', '洗顔は力を入れず、ぬるま湯で優しく行いましょう。'];
      case '炎症':
        return ['ニキビや炎症がある場合は、触らないようにしましょう。', '清潔な手で優しくスキンケアを行い、抗炎症成分配合の製品を使用することをお勧めします。'];
      case 'ハリ':
        return ['ハリのある肌を維持するには、コラーゲンやヒアルロン酸を含む製品が効果的です。', '顔のマッサージを行うことで血行を良くし、肌の弾力を保ちましょう。'];
      default:
        return ['毎日の丁寧なスキンケアを継続しましょう。', '十分な睡眠と水分摂取も健康的な肌には欠かせません。'];
    }
  }

  List<String> _generateRecommendations() {
    List<String> recommendations = [];
    
    if ((scores['pores'] ?? 0) < 60) {
      recommendations.add('毛穴の目立ちを軽減するには、優しい角質ケアと十分な保湿を心がけましょう');
    }
    if ((scores['pimples'] ?? 0) < 60) {
      recommendations.add('サリチル酸配合の製品を使用して、炎症を抑える効果が期待できます');
    }
    if ((scores['redness'] ?? 0) < 60) {
      recommendations.add('ナイアシンアミド配合の製品を使用して、赤みを軽減しましょう');
    }
    if ((scores['firmness'] ?? 0) < 60) {
      recommendations.add('レチノール配合の製品を取り入れて、肌のハリを改善しましょう');
    }
    if ((scores['sagging'] ?? 0) < 60) {
      recommendations.add('ペプチド配合の製品を使用して、肌のたるみを引き締める効果が期待できます');
    }
    
    return recommendations.isEmpty 
      ? ['現在の肌の状態は良好です。引き続き現在のスキンケアルーティンを続けてください。'] 
      : recommendations;
  }
}