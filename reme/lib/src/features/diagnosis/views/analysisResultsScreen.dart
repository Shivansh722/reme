import 'dart:convert';
import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/diagnosis/views/detailedAnalysisScreen.dart';
import 'package:reme/src/features/home/views/homeView.dart';
import 'package:reme/src/features/home/widgets/recommendedCard.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:reme/src/features/shared/radiusChart.dart';
import 'package:reme/src/features/auth/Views/authGate.dart';


class AnalysisResultsScreen extends StatelessWidget {
  final File? faceImage;
  final String analysisResult;

  const AnalysisResultsScreen({
    super.key,
    required this.faceImage,
    required this.analysisResult,
  });

  // Extract scores from the analysis result using regex
  Map<String, int> _extractScores() {
    final Map<String, int> scores = {};

    // Try to extract the JSON block from the Gemini response
    final jsonRegex = RegExp(r'\{[\s\S]*?\}');
    final jsonMatch = jsonRegex.firstMatch(analysisResult);
    if (jsonMatch != null) {
      final jsonString = jsonMatch.group(0);
      try {
        final Map<String, dynamic> jsonScores = jsonDecode(jsonString!);
        // Map the JSON keys to your UI keys if needed
        scores['pimples'] = jsonScores['pimples_acne_spots'] ?? 0;
        scores['pores'] = jsonScores['pores'] ?? 0;
        scores['redness'] = jsonScores['redness'] ?? 0;
        scores['firmness'] = jsonScores['firmness'] ?? 0;
        scores['sagging'] = jsonScores['sagging'] ?? 0;
        scores['skin grade'] = jsonScores['skin_grade'] ?? 0;
        scores['skin age'] = jsonScores['skin_age'] ?? 0;
      } catch (e) {
        print('Error decoding JSON: $e');
      }
    } else {
      print('No JSON block found in analysis result.');
    }

    print('Final scores: $scores');
    return scores;
  }

  @override
  Widget build(BuildContext context) {
    final scores = _extractScores();

    return Scaffold(
      appBar: AppBar(
       
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Replace the image with the radar chart
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
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
            
            const SizedBox(height: 40),

            // Add the debug section right here, after the radar chart and before the summary
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

            const SizedBox(height: 40),

          

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

            const Text(
              '肌の状態',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

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

            const SizedBox(height: 16),

            Custombutton(
              text: 'もっと詳しく診断する',
              onTap: () {
                // Check if user is logged in
                final User? currentUser = FirebaseAuth.instance.currentUser;
                
                if (currentUser == null) {
                  // User is not logged in, navigate to AuthGate with analysis data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Authgate(
                        // Pass the analysis data to be used after login
                        pendingAnalysisData: {
                          'faceImage': faceImage,
                          'analysisResult': analysisResult,
                          'scores': _extractScores(),
                        },
                      ),
                    ),
                  );
                } else {
                  // User is logged in, navigate to detailed analysis page
                 Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => HomeviewMain(
      initialTab: 3,
      faceImage: faceImage,
      analysisResult: analysisResult,
      scores: _extractScores(),
    ),
  ),
);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCircle(
      String label, int score, Color color, {double size = 50, bool isAge = false}) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              isAge ? '$score' : '$score',
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}