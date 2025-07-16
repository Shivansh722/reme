import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;

class SkinAgeHistoryChart extends StatefulWidget {
  final List<Map<String, dynamic>> historyEntries;
  final bool showTitle;
  final int maxEntries;

  const SkinAgeHistoryChart({
    super.key,
    required this.historyEntries,
    this.showTitle = true,
    this.maxEntries = 3,
  });

  @override
  State<SkinAgeHistoryChart> createState() => _SkinAgeHistoryChartState();
}

class _SkinAgeHistoryChartState extends State<SkinAgeHistoryChart> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.historyEntries.isEmpty) {
      return const SizedBox(); // Return empty widget if no data
    }

    // Sort entries by date (newest first)
    final sortedEntries = List<Map<String, dynamic>>.from(widget.historyEntries);
    sortedEntries.sort((a, b) {
      final aTimestamp = a['timestamp'] as Timestamp?;
      final bTimestamp = b['timestamp'] as Timestamp?;
      if (aTimestamp == null || bTimestamp == null) return 0;
      return bTimestamp.compareTo(aTimestamp); // Newest first
    });

    // Determine if we have more entries than the default display limit
    final hasMoreEntries = sortedEntries.length > widget.maxEntries;
    
    // Get the entries to display based on expanded state
    final displayEntries = _isExpanded 
        ? sortedEntries 
        : sortedEntries.take(widget.maxEntries).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title above the chart
        if (widget.showTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Center(
              child: Text(
                'マイカルテ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        
        // Chart card
        Card(
          elevation: 0,
          color: Colors.grey.shade100,
         
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and expand button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    if (hasMoreEntries)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Score list directly in the light grey background
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: displayEntries.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                itemBuilder: (context, index) {
                  final entry = displayEntries[index];
                  
                  // Convert timestamp
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
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${scores['skin grade'] ?? 0}点',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}