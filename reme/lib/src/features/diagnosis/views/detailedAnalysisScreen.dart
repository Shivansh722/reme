import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reme/src/features/diagnosis/widgets/circularProg.dart';
import 'package:reme/src/features/diagnosis/widgets/historyChart.dart';
import 'package:reme/src/features/diagnosis/widgets/skinAgeHistoryChart.dart'; // Add this import
import 'package:reme/src/features/home/widgets/recommendedCard.dart';
import 'package:reme/src/features/shared/radiusChart.dart';
import 'package:reme/src/features/shared/services/firestore_service.dart';
import 'package:intl/intl.dart' as intl;
import 'package:reme/src/widgets/timelineChart.dart';

class DetailedAnalysisScreen extends StatefulWidget {
  final File? faceImage;
  final String? analysisResult;
  final Map<String, int>? scores;

  const DetailedAnalysisScreen({
    super.key,
    this.faceImage,
    this.analysisResult,
    this.scores,
  });

  @override
  State<DetailedAnalysisScreen> createState() => _DetailedAnalysisScreenState();
}

class _DetailedAnalysisScreenState extends State<DetailedAnalysisScreen> {
  bool _isLoading = false;
  String? _loadedAnalysisResult;
  Map<String, int>? _loadedScores;
  String? _errorMessage;
  List<Map<String, dynamic>> _historyEntries = []; // Add this line
  
  @override
  void initState() {
    super.initState();
    
    // If we don't have scores passed directly, try to load from Firestore
    if (widget.scores == null) {
      _loadDataFromFirestore();
    }
    
    // Load history data for logged-in users
    _loadHistoryData();
  }

  // Add this method to load history data
  Future<void> _loadHistoryData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return; // Not logged in, no need to load history
    }
    
    try {
      final firestoreService = FirestoreService();
      final analysisHistory = await firestoreService.getAnalysisHistory(
        user.uid,
        limit: 5, // Show the latest 5 entries
      );
      
      setState(() {
        _historyEntries = analysisHistory;
      });
    } catch (e) {
      print('Error loading analysis history: $e');
    }
  }

  Future<void> _loadDataFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'You need to be logged in to view analysis history';
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
          _errorMessage = 'No analysis data found. Take a new skin test!';
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
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
      print('Error loading analysis data: $e');
    }
  }
  
  // Get the effective data to display (either from props or loaded data)
  String get analysisResult => widget.analysisResult ?? _loadedAnalysisResult ?? '';
  Map<String, int> get scores => widget.scores ?? _loadedScores ?? {};
  
  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    
    return Scaffold(
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
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                
                          // Display either history chart or radar chart based on login status
                          if (isLoggedIn && _historyEntries.isNotEmpty) 
                            SkinAgeHistoryChart(
                              historyEntries: _historyEntries,
                              showTitle: true,
                              maxEntries: 3,  // Changed from
                            )
                          // For first-time users or non-logged in users, show radar chart
                          else
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
                                            // Change this line to subtract from 100
                                            text: '${100 - (scores['skin age'] ?? 0)}',
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

                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFF9F9F9),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Point"),
                                SizedBox(height: 8),
                                Text(
                                  '入浴時は、お湯の温度を40度以下に設定し、10〜15分程度を目安にしましょう。長時間の入浴や熱すぎるお湯は、皮膚への負担となる可能性があります。',
                                  style: TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
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
                            ],
                          ),

                          // Add timeline chart at the bottom, only when history chart is shown
                          if (isLoggedIn && _historyEntries.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                SizedBox(
                                  height: 350, // Increased height for better visibility
                                  child: ScoreChartScreen(),
                                ),
                              ],
                            ),
        
                          const SizedBox(height: 32),
                
                          // Personalized recommendations
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                              'おすすめ製品',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Row(
                              children: [
                                Expanded(
                                child: ProductCard(
                                  title: '母袋有機農場シリーズ...',
                                  description: '栄養豊富なヘチマ水がすっと浸透、繊細な肌を包み込み',
                                  price: '¥1,234(税込)',
                                ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                child: ProductCard(
                                  title: '母袋有機農場シリーズ...',
                                  description: '栄養豊富なヘチマ水がすっと浸透、繊細な肌を包み込み',
                                  price: '¥1,234(税込)',
                                ),
                                ),
                              ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                              children: [
                                Expanded(
                                child: ProductCard(
                                  title: '保湿美容液...',
                                  description: 'セラミド配合で乾燥肌を集中的にケア、バリア機能を強化',
                                  price: '¥2,980(税込)',
                                ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                child: ProductCard(
                                  title: 'ビタミンC美容液...',
                                  description: '高濃度ビタミンCがくすみを改善し、明るい肌へ導きます',
                                  price: '¥3,500(税込)',
                                ),
                                ),
                              ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                
                          // Full analysis text
                          // _buildFullAnalysisSection(),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // Widget _buildFullAnalysisSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Complete Analysis',
  //         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //       ),
  //       const SizedBox(height: 16),
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Colors.grey[50],
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(color: Colors.grey[200]!),
  //         ),
  //         child: Text(
  //           analysisResult,
  //           style: const TextStyle(fontSize: 16, height: 1.5),
  //         ),
  //       ),
  //     ],
  //   );
  // }

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

  // Add this new method to get specific advice based on the parameter
  String _getPointAdvice(String parameter) {
    // Convert parameter to lowercase for easier comparison
    String param = parameter.toLowerCase();
    
     
    if (param.contains('pore') || param.contains('毛穴')) {
      return '毛穴の目立ちを軽減するには、優しい角質ケアと十分な保湿が重要です。洗顔後は必ず化粧水などで保湿し、皮脂分泌のバランスを整えましょう。';
    } else if (param.contains('redness') || param.contains('赤み')) {
      return '敏感肌用の低刺激な製品を選び、アルコールや香料が含まれていないものを使用してください。洗顔は力を入れず、ぬるま湯で優しく行いましょう。';
    } else if (param.contains('pimple') || param.contains('炎症') || param.contains('acne')) {
      return 'ニキビや炎症がある場合は、触らないようにしましょう。清潔な手で優しくスキンケアを行い、抗炎症成分配合の製品を使用することをお勧めします。';
    } else if (param.contains('firm') || param.contains('ハリ')) {
      return 'ハリのある肌を維持するには、コラーゲンやヒアルロン酸を含む製品が効果的です。また、顔のマッサージを行うことで血行を良くし、肌の弾力を保ちましょう。';
    } else if (param.contains('sag') || param.contains('たるみ')) {
      return '入浴時は、お湯の温度を40度以下に設定し、10〜15分程度を目安にしましょう。長時間の入浴や熱すぎるお湯は、皮膚への負担となる可能性があります。';
    } else if (param.contains('dark') || param.contains('シミ') || param.contains('spot')) {
      return '日焼け止めは必須アイテムです。SPF30以上のものを選び、外出時だけでなく室内でも使用することをお勧めします。UVカット効果のある帽子や日傘も活用しましょう。';
    } else {
      return '毎日の丁寧なスキンケアを継続しましょう。十分な睡眠と水分摂取も健康的な肌には欠かせません。';
    }
  }
}