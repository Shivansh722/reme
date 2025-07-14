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
    this.maxEntries = 5,
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
        if (widget.showTitle)
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '診断履歴',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
            ],
          ),
        // Full-width history chart
        Container(
          width: double.infinity, // Takes full available width
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                columns: const [
                  DataColumn(label: Text('日付')),
                  DataColumn(label: Text('肌年齢'), numeric: true),
                ],
                rows: displayEntries.map((entry) {
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
                  
                  final formattedDate = intl.DateFormat('MM/dd').format(dateTime);
                  final scores = entry['scores'] as Map<String, dynamic>? ?? {};
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(formattedDate)),
                      DataCell(Text('${scores['skin age'] ?? '-'}歳')),
                    ],
                  );
                }).toList(),
              ),
              
              // Show expand/collapse button if we have more entries
              if (hasMoreEntries)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? '折りたたむ' : 'すべて表示 (${sortedEntries.length - widget.maxEntries}件)',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded 
                                ? Icons.keyboard_arrow_up 
                                : Icons.keyboard_arrow_down,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                        ],
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