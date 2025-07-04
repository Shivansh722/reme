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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Skin Analysis'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Analysis Report',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    
    return Container(
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
}