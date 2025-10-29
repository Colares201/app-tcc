import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Necessário para formatar a data (adicione ao pubspec.yaml se não tiver: intl: ^[versão])
import 'package:untitled1/model/power_date.dart';
// ... PowerData class (mencionado acima) ...

class PowerChartPage extends StatelessWidget {
  const PowerChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference powerRef = FirebaseDatabase.instance.ref('power_logs');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfico de Potência'),
      ),
      body: StreamBuilder(
        stream: powerRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final data = snapshot.data!.snapshot.value;
          final List<PowerData> chartData = [];

          if (data is Map) {
            // Converte os dados do Firebase para a lista de PowerData
            data.forEach((key, value) {
              if (value is Map && value.containsKey('timestamp') && value.containsKey('value')) {
                try {
                  final timestamp = value['timestamp'] as int;
                  final powerValue = (value['value'] as num).toDouble();
                  chartData.add(
                    PowerData(
                      DateTime.fromMillisecondsSinceEpoch(timestamp),
                      powerValue,
                    ),
                  );
                } catch (e) {
                  debugPrint('Erro ao processar log: $e');
                }
              }
            });
            // Ordena por tempo para garantir a visualização correta
            chartData.sort((a, b) => a.time.compareTo(b.time));
          }

          if (chartData.isEmpty) {
            return const Center(child: Text('Nenhum dado de potência disponível.'));
          }

          // Filtra para exibir apenas os últimos 10 ou 20 pontos, se a lista for grande.
          final displayData = chartData.length > 20 ? chartData.sublist(chartData.length - 20) : chartData;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                minX: displayData.first.time.millisecondsSinceEpoch.toDouble(),
                maxX: displayData.last.time.millisecondsSinceEpoch.toDouble(),
                minY: 0, 
                maxY: displayData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.1, // 10% a mais do valor máximo
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('Potência (W)'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 50, // Ajuste o intervalo conforme a escala da sua potência
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Tempo'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 60000, // Intervalo de 1 minuto em milissegundos
                      getTitlesWidget: (value, meta) {
                        // Converte o timestamp para DateTime e formata para exibição
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return SideTitleWidget(
                          //axisSide: meta.axisSide,
                          space: 8.0,
                          meta: meta,
                          child: Text(
                            DateFormat('HH:mm:ss').format(date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: displayData.map((data) {
                      return FlSpot(data.time.millisecondsSinceEpoch.toDouble(), data.value);
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}