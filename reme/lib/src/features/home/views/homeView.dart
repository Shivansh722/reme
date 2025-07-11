import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/home/widgets/recommendedCard.dart';
import 'package:reme/src/features/shared/Widgets/bottom_nav_bar.dart';
import 'package:reme/src/features/diagnosis/views/custom_camera_screen.dart';
import 'package:reme/src/features/chat/views/chatView.dart';
import 'package:reme/src/features/profile/view/profileView.dart';
import 'package:reme/src/features/diagnosis/views/detailedAnalysisScreen.dart';
import 'package:reme/src/features/diagnosis/widgets/historyChart.dart';
import 'package:reme/src/features/shared/services/firestore_service.dart';

class HomeviewMain extends StatefulWidget {
  final int initialTab;
  final File? faceImage;
  final String? analysisResult;
  final Map<String, int>? scores;

  const HomeviewMain({
    super.key,
    this.initialTab = 0,
    this.faceImage,
    this.analysisResult,
    this.scores,
  });

  @override
  State<HomeviewMain> createState() => _HomeviewMainState();
}

class _HomeviewMainState extends State<HomeviewMain> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _getBody() {
    if (_currentIndex == 3 && widget.scores == null) {
      return DetailedAnalysisScreen(); // No params, will load from Firestore
    }
    switch (_currentIndex) {
      case 0:
        return DiagnosisScreen();
      case 1:
        return CustomCameraScreen();
      case 2:
        return const ChatScreen();
      case 3:
        // If analysis data is provided, use it; otherwise, use default
        return DetailedAnalysisScreen(
          faceImage: widget.faceImage,
          analysisResult: widget.analysisResult ??
              "Your skin analysis shows good overall health with some areas for improvement. The analysis indicates moderate pore visibility and slight redness in certain areas. Your skin firmness is within normal range, and there are minimal signs of sagging. Continue with your current skincare routine while focusing on the recommended improvements below.",
          scores: widget.scores ??
              {
                'pores': 75,
                'pimples': 85,
                'redness': 65,
                'firmness': 80,
                'sagging': 88,
                'skin grade': 78,
              },
        );
      case 4:
        return const MyPageScreen();
      default:
        return DiagnosisScreen();
    }
  }
}

class DiagnosisScreen extends StatefulWidget {
  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyEntries = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalysisHistory();
  }

  Future<void> _loadAnalysisHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final firestoreService = FirestoreService();
      final analysisHistory = await firestoreService.getAnalysisHistory(
        user.uid,
        limit: 3, // Just show the most recent 3 entries
      );

      setState(() {
        _historyEntries = analysisHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading analysis history: $e');
    }
  }

  void _viewAnalysisDetails(Map<String, dynamic> analysis) {
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

  Widget checklistItem(bool checked, String text) => CheckboxListTile(
        value: checked,
        onChanged: (_) {},
        title: Text(text,
            style: TextStyle(
              color: Colors.black87,
            )),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add padding at the top to compensate for status bar
          SizedBox(height: MediaQuery.of(context).padding.top),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('最新の診断結果',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),

                  Text('もっと見る',
                      style: TextStyle(color: Colors.blue)),
                ],
              ),
              SizedBox(height: 16),
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
                            text: '86',
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
                                text: '42',
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
              SizedBox(height: 24),

              // Add history chart here
              // _isLoading 
              //   ? Center(child: CircularProgressIndicator())
              //   : _historyEntries.isEmpty
              //     ? Center(
              //         child: Text('診断履歴がありません', style: TextStyle(fontSize: 14)),
              //       )
              //     : Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Row(
              //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //             children: [
              //               Text('診断履歴',
              //                   style: TextStyle(
              //                       fontWeight: FontWeight.bold, fontSize: 16)),
              //               GestureDetector(
              //                 onTap: () {
              //                   // Navigate to full history
              //                 },
              //                 child: Text('もっと見る',
              //                     style: TextStyle(color: Colors.blue)),
              //               ),
              //             ],
              //           ),
              //           SizedBox(height: 12),
              //           SimpleSkinHistoryChart(
              //             historyEntries: _historyEntries,
              //             onEntryTap: _viewAnalysisDetails,
              //           ),
              //         ],
              //       ),
              
              SizedBox(height: 24),

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
              SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('前回の診断日\n2025/05/12'),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  Text('次回の診断目安\n2025/08/16'),
                ],
              ),
              SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(300, 48),
                      foregroundColor: Colors.pink,
                      side: BorderSide(color: Colors.pink)),
                  child: Text('再診断する'),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.pink[50]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text('理想の肌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),

                SizedBox(height: 8),

                Text('乾燥肌を改善したい', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

                SizedBox(height: 2),

                Text(
                  '洗顔・入浴後すぐに保湿（3分以内が理想）\nセラミド、ヒアルロン酸、グリセリン配合の保湿剤を選ぶ\nオイルやバームで蓋をして水分を逃がさない',
                ),

                SizedBox(height: 2),
                Divider(height: 24, color: Colors.grey[300]),

                SizedBox(height: 2),

                Text('やることリスト', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),

                checklistItem(false, '目標に対するタスクが入ります。目標に対するタスクがあります。'),
                checklistItem(true, '目標に対するタスクが入ります。目標に対するタスクがあります。'),
                checklistItem(false, '目標に対するタスクが入ります。目標に対するタスクがあります。'),
              ],
            ),
          ),

          SizedBox(height: 24),

          Text('おすすめ商品',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 16),
           Row(
             children: [
               ProductCard(
                 title: '母袋有機農場シリーズ...',
                 description: '栄養豊富なヘチマ水がすっと浸透、繊細な肌を包み込み',
                 price: '¥1,234(税込)',
               ),
              SizedBox(width: 8),
              ProductCard(
                title: '母袋有機農場シリーズ...',
                description: '栄養豊富なヘチマ水がすっと浸透、繊細な肌を包み込み',
                price: '¥1,234(税込)',
              ),
             ],
           ),

          SizedBox(height: 24),
        ],
      ),
    );
  }
}