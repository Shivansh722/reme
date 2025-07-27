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
    'pores': '毛穴',
    'pimples': '炎症',
    'redness': '赤み',
    'firmness': '弾力',
    'sagging': 'たるみ',
    'dark spots': 'シミ',
    'skin grade': '総合スコア',
    'skin age': '肌年齢'
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
        limit: 20, // グラフ用により多くのデータを取得
      );

      // タイムスタンプでソート（古い順に）
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
      print('グラフ用の診断履歴読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processDataForChart() {
    // データをリセット
    dataByParameter = {};
    xAxisLabels = [];
    
    // 選択された年のデータをフィルタリング
    final yearData = _analysisData.where((entry) {
      final timestamp = entry['timestamp'] as Timestamp?;
      if (timestamp == null) return false;
      return timestamp.toDate().year == selectedYear;
    }).toList();

    // 選択された年のデータがない場合
    if (yearData.isEmpty) {
      return;
    }

    // 最初のエントリからすべてのパラメータを抽出して、利用可能なパラメータを発見
    final firstEntry = yearData.first;
    final scores = firstEntry['scores'] as Map<String, dynamic>?;
    final availableParameters = scores?.keys.toList() ?? [];

    // 利用可能なパラメータがあるが、選択されたパラメータがない場合、デフォルトで最初の2つを選択
    if (selectedParameters.isEmpty && availableParameters.length >= 2) {
      selectedParameters = [
        availableParameters[0],
        availableParameters[1]
      ];
    }

    // X軸ラベルを作成し、データ構造を初期化
    for (int i = 0; i < yearData.length; i++) {
      final entry = yearData[i];
      final timestamp = entry['timestamp'] as Timestamp?;
      
      if (timestamp != null) {
        final date = timestamp.toDate();
        // 月の省略形でフォーマット
        final monthLabel = intl.DateFormat('M月').format(date);
        xAxisLabels.add(monthLabel);
        
        // 各パラメータのスコアを処理
        final scores = entry['scores'] as Map<String, dynamic>?;
        if (scores != null) {
          scores.forEach((parameter, value) {
            if (!dataByParameter.containsKey(parameter)) {
              dataByParameter[parameter] = [];
            }
            
            // 値をdoubleに変換
            double scoreValue = 0;
            if (value is int) {
              scoreValue = value.toDouble();
            } else if (value is double) {
              scoreValue = value;
            } else if (value is num) {
              scoreValue = value.toDouble();
            }
            
            // データポイントを追加
            dataByParameter[parameter]!.add(FlSpot(i.toDouble(), scoreValue));
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 処理されたデータからすべての利用可能なパラメータを取得
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
                  /// ヘッダー
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 左側のタイトルと年の選択
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'スコア推移',
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
                                '$selectedYear年',
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
                      
                      // 右側のドロップダウン
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
                                'パラメータ選択',
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
                                          // 利用可能であれば表示名を使用
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

                  /// チャート
                  if (_analysisData.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          '選択した年のデータはありません',
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
                          
                          // 選択されたパラメータの凡例 - Columnの内側に移動
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
                                          // Use the Japanese name from parameterMapping
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
        // パラメータ名に基づいて一貫した色を生成
        final hash = parameter.hashCode;
        return Colors.primaries[hash % Colors.primaries.length];
    }
  }
}
