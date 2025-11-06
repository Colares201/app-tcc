import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/model/power_date.dart';

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
            data.forEach((key, value) {
              if (value is Map && value.containsKey('timestamp') && value.containsKey('value')) {
                try {
                  final timestamp = int.tryParse(value['timestamp'].toString()); 
                  final powerValue = (value['value'] as num).toDouble();

                  if (timestamp == null || timestamp == 0) {
                      debugPrint('Erro: Timestamp inválido ou ausente. Pulando log.');
                      return; 
                  }
                  
                  chartData.add(
                    PowerData(
                      DateTime.fromMillisecondsSinceEpoch(timestamp),
                      powerValue,
                    ),
                  );
                } catch (e) {
                  debugPrint('Erro fatal ao processar item do log: ${e}. Pulando.');
                }
              }
            });
            chartData.sort((a, b) => a.time.compareTo(b.time));
          }

          if (chartData.isEmpty) {
            return const Center(child: Text('Nenhum dado de potência disponível.'));
          }

          final displayData = chartData.length > 20 ? chartData.sublist(chartData.length - 20) : chartData;

          // ******* CONFIGURAÇÕES DO EIXO Y (kVA) *******
          final double fixedMaxY = 0.9;
          final double yInterval = 0.1;
          
          final double minTimeMs = displayData.first.time.millisecondsSinceEpoch.toDouble();
          double chartMaxX = displayData.last.time.millisecondsSinceEpoch.toDouble();
          
          if (minTimeMs == chartMaxX) {
              chartMaxX += 60000;
          }


          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                minX: minTimeMs,
                maxX: chartMaxX,
                // --- Requisito: Iniciar em 0 ---
                minY: 0, 
                // --- Requisito: Chegar a 0.9 ---
                maxY: fixedMaxY, 
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    // --- Requisito: Unidade kVA ---
                    axisNameWidget: const Text('Potência (kVA)'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      // --- Requisito: Intervalo de 0.1 ---
                      interval: yInterval,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Tempo'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60, // Aumenta o espaço para acomodar a rotação
                      // Tentativa de 5 marcadores (intervalo de 5 minutos)
                      interval: 60000 * 5, 
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return SideTitleWidget(
                          space: 8.0,
                          meta: meta,
                          // --- Requisito: Rotação de 90 graus (vertical) ---
                          angle: 90, 
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
                      // --- Requisito: Conversão de W/VA para kVA ---
                      return FlSpot(data.time.millisecondsSinceEpoch.toDouble(), data.value / 1000); 
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
/*import 'package:fl_chart/fl_chart.dart';
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
                  // O timestamp deve ser lido como int (64-bit) para milissegundos
                  final timestamp = value['timestamp'] as int; 
                  final powerValue = (value['value'] as num).toDouble();
                  chartData.add(
                    PowerData(
                      DateTime.fromMillisecondsSinceEpoch(timestamp),
                      powerValue,
                    ),
                  );
                } catch (e) {
                  // Se a conversão falhar (dados corrompidos ou tipo errado) o erro é logado e o item é ignorado.
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

          // **********************************************
          // INÍCIO DA CORREÇÃO: CÁLCULO SEGURO DO MAX Y
          // **********************************************
          final double maxPowerValue = displayData
              .map((e) => e.value)
              .reduce((a, b) => a > b ? a : b);
          
          // Define o maxY: 110% do valor máximo, mas garante que seja de pelo menos 5.0 (ou outro valor pequeno)
          // para dar margem de renderização ao gráfico, evitando travar se o valor for 0 ou muito pequeno.
          final double maxYValue = (maxPowerValue * 1.1); 
          final double safeMaxY = maxYValue > 5.0 ? maxYValue : 5.0;
          // **********************************************
          // FIM DA CORREÇÃO
          // **********************************************


          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                minX: displayData.first.time.millisecondsSinceEpoch.toDouble(),
                maxX: displayData.last.time.millisecondsSinceEpoch.toDouble(),
                minY: 0, 
                // Usa o valor seguro calculado acima
                maxY: safeMaxY, 
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
}*/
