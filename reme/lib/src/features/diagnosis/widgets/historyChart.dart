import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'package:reme/src/features/shared/services/firestore_service.dart';
import 'package:reme/src/features/diagnosis/views/detailedAnalysisScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import

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
        limit: widget.maxEntries,
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

    if (_historyEntries.isEmpty) {
      return const Center(
        child: Text('診断履歴がありません', style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '診断履歴',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (widget.showViewMore)
              TextButton(
                onPressed: () {
                  // Navigate to full history view
                  // TODO: Implement navigation to full history page
                },
                child: const Text('もっと見る', style: TextStyle(color: Colors.blue)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(
                    label: Text('日付', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text('肌スコア', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('毛穴', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('炎症', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('赤み', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('ハリ', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('たるみ', style: TextStyle(fontWeight: FontWeight.bold)),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text('詳細', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
                rows: _historyEntries.map((entry) {
                  // Fixed timestamp conversion
                  DateTime dateTime;
                  final timestamp = entry['timestamp'];
                  if (timestamp is Timestamp) {
                    dateTime = timestamp.toDate();
                  } else if (timestamp is DateTime) {
                    dateTime = timestamp;
                  } else {
                    dateTime = DateTime.now(); // Fallback
                  }
                  
                  final formattedDate = intl.DateFormat('yyyy/MM/dd').format(dateTime);
                  final scores = entry['scores'] as Map<String, dynamic>? ?? {};
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(formattedDate)),
                      DataCell(Text('${scores['skin grade'] ?? '-'}')),
                      DataCell(Text('${scores['pores'] ?? '-'}')),
                      DataCell(Text('${scores['pimples'] ?? '-'}')),
                      DataCell(Text('${scores['redness'] ?? '-'}')),
                      DataCell(Text('${scores['firmness'] ?? '-'}')),
                      DataCell(Text('${scores['sagging'] ?? '-'}')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _viewAnalysisDetails(entry),
                          tooltip: '詳細を見る',
                        ),
                      ),
                    ],
                    onSelectChanged: (_) => _viewAnalysisDetails(entry),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Add a simpler version for showing in the home screen
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowHeight: 40,
            dataRowHeight: 48,
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text('日付')),
              DataColumn(label: Text('肌スコア'), numeric: true),
              DataColumn(label: Text('肌年齢'), numeric: true),
            ],
            rows: historyEntries.map((entry) {
              // Fixed timestamp conversion
              DateTime dateTime;
              final timestamp = entry['timestamp'];
              if (timestamp is Timestamp) {
                dateTime = timestamp.toDate();
              } else if (timestamp is DateTime) {
                dateTime = timestamp;
              } else {
                dateTime = DateTime.now(); // Fallback
              }
              
              final formattedDate = intl.DateFormat('MM/dd').format(dateTime);
              final scores = entry['scores'] as Map<String, dynamic>? ?? {};
              
              return DataRow(
                cells: [
                  DataCell(Text(formattedDate)),
                  DataCell(Text('${scores['skin grade'] ?? '-'}')),
                  DataCell(Text('${scores['skin age'] ?? '-'}歳')),
                ],
                onSelectChanged: (_) => onEntryTap(entry),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}