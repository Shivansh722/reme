import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reme/src/features/shared/services/firestore_service.dart';
import 'package:reme/src/features/diagnosis/views/detailedAnalysisScreen.dart';

class SkinHistoryChart extends StatefulWidget {
  final bool showViewMore;
  final int maxEntries;

  const SkinHistoryChart({
    Key? key,
    this.showViewMore = true,
    this.maxEntries = 5,
  }) : super(key: key);

  @override
  State<SkinHistoryChart> createState() => _SkinHistoryChartState();
}

class _SkinHistoryChartState extends State<SkinHistoryChart> {
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
        _errorMessage = 'ログインが必要です';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firestoreService = FirestoreService();
      final analysisHistory = await firestoreService.getAnalysisHistory(
        user.uid,
        limit: widget.maxEntries * 3,
      );

      setState(() {
        _historyEntries = analysisHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'データの読み込みに失敗しました';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalysisHistory,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    // Display only last 3 entries
    final displayEntries = _historyEntries.isEmpty
        ? [
            {'date': '2024/04/04', 'score': 96},
            {'date': '2024/08/14', 'score': 91},
            {'date': '2024/12/04', 'score': 88},
          ]
        : _historyEntries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title bar
        Container(
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text(
              'マイカルテ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // History section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with right arrow
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '診断履歴：肌スコア',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (widget.showViewMore)
                      GestureDetector(
                        onTap: () {
                          // Navigate to full history view
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FullHistoryScreen(),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
              
              // History entries - each with date and score
              ...displayEntries.map((entry) => GestureDetector(
                onTap: () {
                  if (_historyEntries.isNotEmpty) {
                    _viewAnalysisDetails(entry);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry['date'] is Timestamp 
                            ? intl.DateFormat('yyyy/MM/dd').format((entry['date'] as Timestamp).toDate())
                            : entry['date'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '${entry['score']}点',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
              
              // Expand button
              if (widget.showViewMore && _historyEntries.length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        // Navigate to full history view
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FullHistoryScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'すべての履歴を見る',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// You'll need to create a FullHistoryScreen class or modify an existing one
// This is a simple placeholder if you don't have one yet
class FullHistoryScreen extends StatelessWidget {
  const FullHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('診断履歴'),
      ),
      body: const SkinHistoryChart(
        showViewMore: false,
        maxEntries: 20, // Show more entries on this screen
      ),
    );
  }
}

// Simple version for home screen
class SimpleSkinHistoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> historyEntries;
  final Function(Map<String, dynamic>) onEntryTap;

  const SimpleSkinHistoryChart({
    Key? key,
    required this.historyEntries,
    required this.onEntryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock data to match the image exactly
    final mockEntries = [
      {'date': '2024/04/04', 'score': 96},
      {'date': '2024/08/14', 'score': 91},
      {'date': '2024/12/04', 'score': 88},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '診断履歴：肌スコア',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
          
          // History entries - each with date and score
          ...mockEntries.map((entry) => InkWell(
            onTap: () {
              // Navigate to details when tapped
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry['date'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '${entry['score']}点',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}