import 'dart:math';
import 'package:flutter/material.dart';

// Default test page for the radar chart
void main() => runApp(const MaterialApp(home: RadarChartPage()));

class RadarChartPage extends StatelessWidget {
  const RadarChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: CustomRadarChart(
            values: [70, 20, 50, 70, 90, 70],
          ),
        ),
      ),
    );
  }
}

class CustomRadarChart extends StatelessWidget {
  final List<int> values;
  
  const CustomRadarChart({
    super.key,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RadarChartPainter(values: values),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<String> labels = [
    'Pores',
    'Acne/Spots',
    'Redness',
    'Firmness',
    'Sagging',
    'Skin Grade'
  ];

  final List<int> values;
  final int maxValue = 100;
  final int numHexagons = 5;

  RadarChartPainter({required this.values});

  // Add your color list from innermost to outermost
  final List<Color> hexagonColors = [
    Color(0xFFD0D0D0),
    Color(0xFFDDDDDD),
    Color(0xFFE6E6E6),
    Color(0xFFEFEFEF),
    Color(0xFFF7F7F7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final angle = 2 * pi / labels.length;

    // Draw concentric hexagons with different background colors
    for (int i = numHexagons; i >= 1; i--) {
      final r = radius * i / numHexagons;
      final path = Path();
      for (int j = 0; j < labels.length; j++) {
        final x = center.dx + r * cos(angle * j - pi / 2);
        final y = center.dy + r * sin(angle * j - pi / 2);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      // Fill with color
      final fillPaint = Paint()
        ..color = hexagonColors[i - 1]
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);
    }

    // Draw data polygon
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dataPath = Path();
    for (int i = 0; i < values.length; i++) {
      final value = values[i] / maxValue;
      final r = radius * value;
      final x = center.dx + r * cos(angle * i - pi / 2);
      final y = center.dy + r * sin(angle * i - pi / 2);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Draw dots
    for (int i = 0; i < values.length; i++) {
      final value = values[i] / maxValue;
      final r = radius * value;
      final x = center.dx + r * cos(angle * i - pi / 2);
      final y = center.dy + r * sin(angle * i - pi / 2);
      final dotPaint = Paint()
        ..color = Colors.blue.shade700
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    // Draw labels with values
    for (int i = 0; i < labels.length; i++) {
      final x = center.dx + (radius + 20) * cos(angle * i - pi / 2);
      final y = center.dy + (radius + 20) * sin(angle * i - pi / 2);
      final textSpan = TextSpan(
        text: '${labels[i]}\n${values[i]}',
        style: const TextStyle(color: Colors.black87, fontSize: 12),
      );
      final textPainter =
          TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr)
            ..layout(minWidth: 0, maxWidth: 70);
            
      // Adjust text position based on angle to ensure it doesn't get cut off
      double dx = x - textPainter.width / 2;
      double dy = y - textPainter.height / 2;
      
      // Adjust for edge cases
      if (x < center.dx - radius * 0.7) dx = x - textPainter.width + 5;
      if (x > center.dx + radius * 0.7) dx = x - 5;
      if (y < center.dy - radius * 0.7) dy = y - textPainter.height;
      if (y > center.dy + radius * 0.7) dy = y;
            
      textPainter.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
