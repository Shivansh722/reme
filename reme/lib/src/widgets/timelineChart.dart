import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';


class ScoreChartScreen extends StatefulWidget {
  const ScoreChartScreen({super.key});

  @override
  State<ScoreChartScreen> createState() => _ScoreChartScreenState();
}

class _ScoreChartScreenState extends State<ScoreChartScreen> {
  int selectedYear = 2025;

  final List<String> allParameters = [
    'Pores',
    'Spots',
    'Redness',
    'Inflammation',
    'Sagging',
    'Firmness'
  ];

  List<String> selectedParameters = ['Redness', 'Sagging'];

  final Map<String, List<double>> dataByParameter = {
    'Redness': [35, 40, 50, 65, 65, 53],
    'Sagging': [55, 60, 70, 80, 80, 74],
    'Pores': [50, 55, 60, 70, 68, 65],
    'Spots': [45, 50, 55, 65, 62, 60],
    'Inflammation': [30, 35, 45, 55, 60, 50],
    'Firmness': [40, 45, 50, 60, 58, 56],
  };

  final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              children: [
                const Text(
                  'Score Transition',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                    onPressed: () {
                      setState(() => selectedYear--);
                    },
                    icon: const Icon(Icons.chevron_left)),
                Text('$selectedYear',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: () {
                      setState(() => selectedYear++);
                    },
                    icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 16),

            /// Dropdown
            DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                isExpanded: true,
                customButton: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    'Select Parameters',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                items: allParameters
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Row(
                            children: [
                              Icon(
                                selectedParameters.contains(item)
                                    ? Icons.check
                                    : Icons.circle_outlined,
                                color: selectedParameters.contains(item)
                                    ? Colors.pink.shade300
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(item),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    if (selectedParameters.contains(value)) {
                      selectedParameters.remove(value);
                    } else {
                      selectedParameters.add(value!);
                    }
                  });
                },
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// Chart
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          int i = value.toInt();
                          if (i < months.length) {
                            return Text(months[i],
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
                  ),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: selectedParameters.map((parameter) {
                    final data = dataByParameter[parameter] ?? [];
                    final color = _getColorForParameter(parameter);
                    return LineChartBarData(
                      isCurved: false,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                      spots: List.generate(data.length,
                          (i) => FlSpot(i.toDouble(), data[i])),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForParameter(String parameter) {
    switch (parameter) {
      case 'Redness':
        return Colors.pink.shade300;
      case 'Sagging':
        return Colors.brown.shade300;
      case 'Pores':
        return Colors.blueGrey;
      case 'Spots':
        return Colors.deepPurple;
      case 'Inflammation':
        return Colors.orange;
      case 'Firmness':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
