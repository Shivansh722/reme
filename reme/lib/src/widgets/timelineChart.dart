import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reme/src/features/shared/services/firestore_service.dart';
import 'package:intl/intl.dart' as intl;

class ScoreChartScreen extends StatefulWidget {
  const ScoreChartScreen({super.key});

  @override
  State<ScoreChartScreen> createState() => _ScoreChartScreenState();
}

class _ScoreChartScreenState extends State<ScoreChartScreen> {
  int selectedYear = DateTime.now().year;
  bool _isLoading = true;
  List<Map<String, dynamic>> _analysisData = [];

  // Parameter names mapping (API names to display names)
  final Map<String, String> parameterMapping = {
    'pores': 'Pores',
    'pimples': 'Inflammation',
    'redness': 'Redness',
    'firmness': 'Firmness',
    'sagging': 'Sagging',
    'dark spots': 'Spots',
    'skin grade': 'Overall Score',
    'skin age': 'Skin Age'
  };

  // Default selected parameters
  List<String> selectedParameters = ['redness', 'sagging'];

  // Data organized by parameter
  Map<String, List<FlSpot>> dataByParameter = {};
  
  // X-axis labels (months)
  List<String> xAxisLabels = [];

  @override
  void initState() {
    super.initState();
    _loadAnalysisData();
  }

  Future<void> _loadAnalysisData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final firestoreService = FirestoreService();
      final analysisHistory = await firestoreService.getAnalysisHistory(
        user.uid,
        limit: 20, // Get more data for the chart
      );

      // Sort by timestamp (oldest to newest)
      analysisHistory.sort((a, b) {
        final aTimestamp = a['timestamp'] as Timestamp?;
        final bTimestamp = b['timestamp'] as Timestamp?;
        if (aTimestamp == null || bTimestamp == null) return 0;
        return aTimestamp.compareTo(bTimestamp);
      });

      setState(() {
        _analysisData = analysisHistory;
        _processDataForChart();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analysis history for chart: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processDataForChart() {
    // Reset data
    dataByParameter = {};
    xAxisLabels = [];
    
    // Filter data for selected year
    final yearData = _analysisData.where((entry) {
      final timestamp = entry['timestamp'] as Timestamp?;
      if (timestamp == null) return false;
      return timestamp.toDate().year == selectedYear;
    }).toList();

    // No data for selected year
    if (yearData.isEmpty) {
      return;
    }

    // Extract all parameters from the first entry to discover available parameters
    final firstEntry = yearData.first;
    final scores = firstEntry['scores'] as Map<String, dynamic>?;
    final availableParameters = scores?.keys.toList() ?? [];

    // If we have available parameters but none selected, select first two by default
    if (selectedParameters.isEmpty && availableParameters.length >= 2) {
      selectedParameters = [
        availableParameters[0],
        availableParameters[1]
      ];
    }

    // Create x-axis labels and initialize data structure
    for (int i = 0; i < yearData.length; i++) {
      final entry = yearData[i];
      final timestamp = entry['timestamp'] as Timestamp?;
      
      if (timestamp != null) {
        final date = timestamp.toDate();
        // Format as month abbreviation
        final monthLabel = intl.DateFormat('MMM').format(date);
        xAxisLabels.add(monthLabel);
        
        // Process scores for each parameter
        final scores = entry['scores'] as Map<String, dynamic>?;
        if (scores != null) {
          scores.forEach((parameter, value) {
            if (!dataByParameter.containsKey(parameter)) {
              dataByParameter[parameter] = [];
            }
            
            // Convert value to double
            double scoreValue = 0;
            if (value is int) {
              scoreValue = value.toDouble();
            } else if (value is double) {
              scoreValue = value;
            } else if (value is num) {
              scoreValue = value.toDouble();
            }
            
            // Add data point
            dataByParameter[parameter]!.add(FlSpot(i.toDouble(), scoreValue));
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all available parameters from the processed data
    final allParameters = dataByParameter.keys.toList();

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left column with title and year selector
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Score Transition',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedYear--;
                                    _processDataForChart();
                                  });
                                },
                                icon: const Icon(Icons.chevron_left, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(
                                '$selectedYear',
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold
                                )
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedYear++;
                                    _processDataForChart();
                                  });
                                },
                                icon: const Icon(Icons.chevron_right, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Right side dropdown
                      if (allParameters.isNotEmpty)
                        DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            isExpanded: true,
                            customButton: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Select Parameters',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            items: allParameters
                                .map((param) => DropdownMenuItem<String>(
                                      value: param,
                                      child: Row(
                                        children: [
                                          Icon(
                                            selectedParameters.contains(param)
                                                ? Icons.check
                                                : Icons.circle_outlined,
                                            color: selectedParameters.contains(param)
                                                ? Colors.pink.shade300
                                                : Colors.grey,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          // Use display name if available
                                          Text(
                                            parameterMapping[param] ?? param,
                                            style: const TextStyle(fontSize: 13)
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                if (selectedParameters.contains(value)) {
                                  selectedParameters.remove(value);
                                } else {
                                  selectedParameters.add(value);
                                }
                              });
                            },
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 300,
                              width: 150,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  /// Chart
                  if (_analysisData.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No analysis data available for selected year',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawHorizontalLine: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 25,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                    );
                                  },
                                  getDrawingVerticalLine: (value) {
                                    return FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, _) {
                                        int i = value.toInt();
                                        if (i < xAxisLabels.length) {
                                          return Text(xAxisLabels[i],
                                              style: const TextStyle(fontSize: 12));
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 28,
                                      interval: 25,
                                      getTitlesWidget: (value, _) =>
                                          Text(value.toInt().toString()),
                                    ),
                                  ),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                minY: 0,
                                maxY: 100,
                                lineBarsData: selectedParameters
                                    .where((param) => dataByParameter.containsKey(param))
                                    .map((parameter) {
                                      final spots = dataByParameter[parameter] ?? [];
                                      final color = _getColorForParameter(parameter);
                                      return LineChartBarData(
                                        isCurved: true,
                                        color: color,
                                        barWidth: 3,
                                        dotData: FlDotData(show: true),
                                        belowBarData: BarAreaData(show: false),
                                        spots: spots,
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                          
                          // Legend for selected parameters - moved inside the Column
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: selectedParameters
                                  .where((param) => dataByParameter.containsKey(param))
                                  .map((param) {
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getColorForParameter(param),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          parameterMapping[param] ?? param,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
  }

  Color _getColorForParameter(String parameter) {
    switch (parameter) {
      case 'redness':
        return Colors.pink.shade300;
      case 'sagging':
        return Colors.brown.shade300;
      case 'pores':
        return Colors.blueGrey;
      case 'dark spots':
        return Colors.deepPurple;
      case 'pimples':
        return Colors.orange;
      case 'firmness':
        return Colors.green;
      case 'skin grade':
        return Colors.blue;
      case 'skin age':
        return Colors.red;
      default:
        // Generate a consistent color based on parameter name
        final hash = parameter.hashCode;
        return Colors.primaries[hash % Colors.primaries.length];
    }
  }
}
