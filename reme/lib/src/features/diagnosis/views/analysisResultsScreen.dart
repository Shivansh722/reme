import 'dart:convert';
import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:reme/src/features/shared/radiusChart.dart'; // Import the radar chart

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
        title: const Text('Skin Analysis Results'),
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
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
            ),
            
            const SizedBox(height: 24),

            // Add the debug section right here, after the radar chart and before the summary
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEBUG: Raw Response',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysisResult,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Summary section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Overall metrics in larger format
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreCircle(
                        'Skin Grade',
                        scores['skin grade'] ?? 0,
                        Colors.blue,
                      ),
                      _buildScoreCircle(
                        'Skin Age',
                        scores['skin age'] ?? 0,
                        Colors.purple,
                        isAge: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Detailed metrics in smaller circles
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      _buildScoreCircle('Acne/Spots',
                          scores['spots'] ?? scores['acne'] ?? scores['pimples'] ?? 0, Colors.red),
                      _buildScoreCircle('Pores', scores['pores'] ?? 0, Colors.orange),
                      _buildScoreCircle('Redness', scores['redness'] ?? 0, Colors.pinkAccent),
                      _buildScoreCircle('Firmness', scores['firmness'] ?? 0, Colors.green),
                      _buildScoreCircle('Sagging', scores['sagging'] ?? 0, Colors.teal),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Detailed Analysis',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              analysisResult,
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 32),

            Custombutton(
              text: 'Back to Home',
              onTap: () {
                Navigator.of(context).pop();
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