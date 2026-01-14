import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MoodChart extends StatelessWidget {
  final List<double> scores;
  const MoodChart({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    // Préparation sécurisée des données (7 jours par défaut)
    List<double> chartData = scores.isNotEmpty ? List.from(scores) : [3, 2, 4, 1, 3, 5, 2];
    
    while (chartData.length < 7) {
      chartData.add(0.0);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FF), // Fond clair du screen
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- EN-TÊTE DU GRAPHIQUE ---
          const Text(
            "Last 7 Days",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                "Stable",
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "+20%",
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // --- LE GRAPHIQUE ---
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: _bottomTitles),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true, // Courbe de Bézier lisse
                    curveSmoothness: 0.35,
                    color: const Color(0xFF8B5CF6),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF8B5CF6).withOpacity(0.2),
                          const Color(0xFF8B5CF6).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          
          // Tableau des jours pour la correspondance
          const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
          
          // Calcul de la date réelle pour ce point du graphique
          // L'index 0 est J-6, l'index 6 est aujourd'hui (J-0)
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          
          // date.weekday renvoie 1 pour Lundi, 7 pour Dimanche
          final String label = dayNames[date.weekday - 1];

          if (index >= 0 && index < 7) {
            return Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );
}