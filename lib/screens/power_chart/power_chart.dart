import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/model/power_date.dart';

class PowerChartPage extends StatelessWidget {
  const PowerChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Referência para o nó do Firebase que contém os dados de potência (JSON)
    final DatabaseReference powerRef = FirebaseDatabase.instance.ref('power_logs');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfico de Potência'),
      ),
      body: StreamBuilder(
        // ATUALIZAÇÃO CHAVE: Limitar a consulta aos últimos 100 logs
        stream: powerRef.limitToLast(100).onValue, // Altere aqui!
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        // O Stream lê os dados JSON em tempo real
        //stream: powerRef.onValue,
        //builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final data = snapshot.data!.snapshot.value;
          final List<PowerData> chartData = [];

          // Processa os dados recebidos (formato Map/JSON)
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map && value.containsKey('timestamp') && value.containsKey('value')) {
                try {
                  final dynamic rawTimestamp = value['timestamp'];
                  final dynamic rawPowerValue = value['value'];
                  
                  // 1. Parsing ultrasseguro do Timestamp (baseado em NTP)
                  int? timestamp;
                  if (rawTimestamp is num) {
                      timestamp = rawTimestamp.toInt();
                  } else if (rawTimestamp != null) {
                      timestamp = int.tryParse(rawTimestamp.toString());
                  }

                  // 2. Parsing ultrasseguro do Valor de Potência
                  double? powerValue;
                  if (rawPowerValue is num) {
                      powerValue = rawPowerValue.toDouble();
                  } else if (rawPowerValue != null) {
                      powerValue = num.tryParse(rawPowerValue.toString())?.toDouble();
                  }

                  // 3. Validação dos dados
                  if (timestamp == null || timestamp == 0 || powerValue == null) {
                      debugPrint('Erro: Timestamp ou Valor de Potência inválido. Pulando log.');
                      return; 
                  }
                  
                  // 4. Adiciona ao modelo de dados
                  chartData.add(
                    PowerData(
                      DateTime.fromMillisecondsSinceEpoch(timestamp),
                      powerValue,
                    ),
                  );
                } catch (e) {
                  debugPrint('Erro fatal ao processar item do log: $e. Pulando.');
                }
              }
            });
            // Ordena os dados por tempo
            chartData.sort((a, b) => a.time.compareTo(b.time));
          }

          if (chartData.isEmpty) {
            return const Center(child: Text('Nenhum dado de potência disponível.'));
          }

          // Filtra para exibir apenas os últimos 20 pontos
          final displayData = chartData.length > 20 ? chartData.sublist(chartData.length - 20) : chartData;

          // ***************************************************************
          // PREPARAÇÃO DOS SPOTS (Coordenadas X e Y)
          // ***************************************************************
          final List<FlSpot> rawSpots = displayData.map((data) {
              // Conversão de W/VA para kVA (data.value / 1000)
              return FlSpot(data.time.millisecondsSinceEpoch.toDouble(), data.value / 1000); 
          }).toList();
          
          // FILTRO DE SEGURANÇA: Remove pontos com valores NaN ou Infinity, 
          // que causam o travamento do fl_chart.
          final List<FlSpot> spots = rawSpots.where((spot) {
            return spot.x.isFinite && spot.y.isFinite;
          }).toList();
          
          if (spots.isEmpty) {
             return const Center(child: Text('Nenhum dado válido para o gráfico após a filtragem.'));
          }

          // ***************************************************************
          // CÁLCULO DINÂMICO DOS LIMITES DO GRÁFICO
          // ***************************************************************
          
          // 1. Limites do Eixo X (Tempo)
          final double minTimeMs = spots.first.x;
          double chartMaxX = spots.last.x;
          if (minTimeMs == chartMaxX) {
              chartMaxX += 60000; // Garante um range de tempo mínimo
          }

          // 2. Limites do Eixo Y (Potência em kVA)
          double maxSpotValue = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
          final double requiredMinY = 0.9;
          final double dynamicMaxY = maxSpotValue * 1.1; // Adiciona 10% de margem
          final double finalMaxY = (dynamicMaxY > requiredMinY) ? dynamicMaxY : requiredMinY; 
          
          // ***************************************************************

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 400,
              width: 250,
            child: LineChart(
              LineChartData(
                minX: minTimeMs,
                maxX: chartMaxX,
                minY: 0, 
                maxY: finalMaxY, 
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text('Potência (kVA)'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 70,
                      interval: 0.1,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Tempo'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60, 
                      interval: 300000 , 
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return SideTitleWidget(
                          space: 8.0,
                          meta: meta,
                          angle: 45, // Rotação para tempo (NTP)
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
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

