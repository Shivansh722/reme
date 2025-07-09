import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/shared/services/firestore_service.dart';
import 'package:reme/src/features/diagnosis/views/detailedAnalysisScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _analysisHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    if (_isLoading) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'You need to be logged in to view history';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      if (refresh) {
        _analysisHistory = [];
        _lastDocument = null;
        _hasMoreData = true;
      }
    });

    try {
      final history = await _firestoreService.getPaginatedAnalysisHistory(
        user.uid,
        startAfter: refresh ? null : _lastDocument,
      );
      
      if (history.isEmpty) {
        setState(() {
          _hasMoreData = false;
        });
      } else {
        setState(() async {
          _analysisHistory.addAll(history);
          _lastDocument = history.isNotEmpty 
              ? await _firestoreService.getUserDocument(user.uid)
                  .collection('skinAnalysis')
                  .doc(history.last['id'] as String)
                  .get()
              : null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading history: $e';
      });
      print('Error loading history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    
    return 'Invalid date';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadHistory(refresh: true),
          ),
        ],
      ),
      body: _errorMessage != null 
          ? Center(
              child: Text(_errorMessage!),
            )
          : _analysisHistory.isEmpty && !_isLoading
              ? const Center(
                  child: Text('No analysis history found'),
                )
              : ListView.builder(
                  itemCount: _analysisHistory.length + (_hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _analysisHistory.length) {
                      if (_isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else {
                        return TextButton(
                          onPressed: _loadHistory,
                          child: const Text('Load More'),
                        );
                      }
                    }
                    
                    final analysis = _analysisHistory[index];
                    final Map<String, dynamic> scores = analysis['scores'];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          'Analysis from ${_formatDate(analysis['timestamp'])}',
                        ),
                        subtitle: Text(
                          'Skin Grade: ${scores['skin grade'] ?? 'N/A'}, '
                          'Skin Age: ${scores['skin age'] ?? 'N/A'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailedAnalysisScreen(
                                analysisResult: analysis['analysisResult'],
                                scores: Map<String, int>.from(scores),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}