
/*// colares201/app-tcc/app-tcc-2b1f1eecf93b415acda52ec0d45c7f0a1100d26e/lib/screens/power_chart/power_chart.dart

import 'dart:async'; // 1. Importar o 'async' para usar o Timer
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/model/power_date.dart';

// 2. Converter para StatefulWidget
class PowerChartPage extends StatefulWidget {
  const PowerChartPage({super.key});

  @override
  State<PowerChartPage> createState() => _PowerChartPageState();
}

class _PowerChartPageState extends State<PowerChartPage> {
  // 3. Variáveis de estado para guardar os dados do gráfico
  List<FlSpot> _spots = [];
  double _minTimeMs = DateTime.now().millisecondsSinceEpoch.toDouble();
  double _chartMaxX = DateTime.now().millisecondsSinceEpoch.toDouble() + 60000;
  double _finalMaxY = 0.9; // Um valor mínimo inicial
  bool _isLoading = true;

  // 4. Referências para o Firebase e para o "listener"
  final DatabaseReference _powerRef =
      FirebaseDatabase.instance.ref('power_logs');
  StreamSubscription<DatabaseEvent>? _powerSubscription;
  Timer? _throttle;

  @override
  void initState() {
    super.initState();
    _activateListener();
  }

  @override
  void dispose() {
    // 5. Cancelar o listener e o timer ao sair da tela (MUITO IMPORTANTE)
    _powerSubscription?.cancel();
    _throttle?.cancel();
    super.dispose();
  }

  void _activateListener() {
    // 6. Iniciar o "listener" do Firebase
    _powerSubscription = _powerRef.limitToLast(20).onValue.listen(
      (DatabaseEvent event) {
        // 7. Quando os dados chegam, processá-los
        final processedData = _processData(event.snapshot.value);
        
        // 8. LÓGICA DO "THROTTLE" (O PULO DO GATO)
        // Se o timer estiver ativo, não faz nada (espera o timer rodar)
        if (_throttle?.isActive ?? false) return;

        // Se não há timer ativo, cria um
        _throttle = Timer(const Duration(milliseconds: 500), () {
          // 9. O timer rodou! Agora sim, atualizamos a tela (setState)
          if (mounted) { // Garante que a tela ainda existe
            setState(() {
              _spots = processedData['spots'] ?? [];
              _minTimeMs = processedData['minTimeMs'] ?? _minTimeMs;
              _chartMaxX = processedData['chartMaxX'] ?? _chartMaxX;
              _finalMaxY = processedData['finalMaxY'] ?? _finalMaxY;
              _isLoading = false;
            });
          }
        });
      },
      onError: (Object error) {
        debugPrint('Erro no Stream: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  // 10. Movi toda a lógica de processamento para uma função separada
  Map<String, dynamic> _processData(dynamic data) {
    final List<PowerData> chartData = [];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map &&
            value.containsKey('timestamp') &&
            value.containsKey('value')) {
          try {
            final dynamic rawTimestamp = value['timestamp'];
            final dynamic rawPowerValue = value['value'];
            
            int? timestamp = (rawTimestamp is num)
                ? rawTimestamp.toInt()
                : int.tryParse(rawTimestamp.toString());
                
            double? powerValue = (rawPowerValue is num)
                ? rawPowerValue.toDouble()
                : num.tryParse(rawPowerValue.toString())?.toDouble();

            if (timestamp == null || timestamp == 0 || powerValue == null) {
              return;
            }
            
            chartData.add(
              PowerData(
                DateTime.fromMillisecondsSinceEpoch(timestamp),
                powerValue,
              ),
            );
          } catch (e) {
            debugPrint('Erro ao processar item do log: $e. Pulando.');
          }
        }
      });
      chartData.sort((a, b) => a.time.compareTo(b.time));
    }

    if (chartData.isEmpty) {
      return {'spots': <FlSpot>[]};
    }

    // (Não precisamos mais da 'sublist' pois já limitamos para 20 no Firebase)
    final List<FlSpot> rawSpots = chartData.map((data) {
      return FlSpot(
          data.time.millisecondsSinceEpoch.toDouble(), data.value / 1000);
    }).toList();
    
    final List<FlSpot> spots = rawSpots.where((spot) {
      return spot.x.isFinite && spot.y.isFinite;
    }).toList();
    
    if (spots.isEmpty) {
      return {'spots': <FlSpot>[]};
    }

    // Cálculos dos limites
    final double minTimeMs = spots.first.x;
    double chartMaxX = spots.last.x;
    if (minTimeMs == chartMaxX) {
      chartMaxX += 60000;
    }

    double maxSpotValue =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    const double requiredMinY = 0.9;
    final double dynamicMaxY = maxSpotValue * 1.1;
    final double finalMaxY =
        (dynamicMaxY > requiredMinY) ? dynamicMaxY : requiredMinY;
        
    // 11. Retorna os dados processados
    return {
      'spots': spots,
      'minTimeMs': minTimeMs,
      'chartMaxX': chartMaxX,
      'finalMaxY': finalMaxY,
    };
  }

  @override
  Widget build(BuildContext context) {
    // 12. O 'build' agora é muito mais simples
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfico de Potência'),
      ),
      body: Center( // Adicionado Center para centralizar o conteúdo
        child: _buildChart(),
      ),
    );
  }

  // 13. Widget de construção do gráfico
  Widget _buildChart() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    
    if (_spots.isEmpty) {
      return const Text('Nenhum dado válido para o gráfico.');
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 400,
        width: 250, // Você pode ajustar ou remover essa largura
        child: LineChart(
          LineChartData(
            // 14. Usa as variáveis de estado
            minX: _minTimeMs,
            maxX: _chartMaxX,
            minY: 0,
            maxY: _finalMaxY,
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  interval: 300000,
                  getTitlesWidget: (value, meta) {
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return SideTitleWidget(
                      space: 8.0,
                      meta: meta,
                      angle: 45,
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
                spots: _spots, // 15. Usa os 'spots' do estado
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
  }
}*/
import 'dart:async'; 
import 'dart:math'; // NOVO: Import necessário para cálculos de log e pow
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:untitled1/model/power_date.dart';

class PowerChartPage extends StatefulWidget {
  const PowerChartPage({super.key});

  @override
  State<PowerChartPage> createState() => _PowerChartPageState();
}

class _PowerChartPageState extends State<PowerChartPage> {
  // 3. Variáveis de estado
  List<FlSpot> _spots = [];
  double _minTimeMs = DateTime.now().millisecondsSinceEpoch.toDouble();
  double _chartMaxX = DateTime.now().millisecondsSinceEpoch.toDouble() + 60000;
  double _finalMaxY = 0.9; // Limite superior dinâmico do eixo Y
  double _dynamicIntervalY = 0.1; // NOVO: Intervalo dinâmico dos rótulos do eixo Y
  bool _isLoading = true;

  // 4. Referências
  final DatabaseReference _powerRef =
      FirebaseDatabase.instance.ref('power_logs');
  StreamSubscription<DatabaseEvent>? _powerSubscription;
  Timer? _throttle;

  @override
  void initState() {
    super.initState();
    _activateListener();
  }

  @override
  void dispose() {
    _powerSubscription?.cancel();
    _throttle?.cancel();
    super.dispose();
  }

  void _activateListener() {
    _powerSubscription = _powerRef.limitToLast(20).onValue.listen(
      (DatabaseEvent event) {
        final processedData = _processData(event.snapshot.value);
        
        if (_throttle?.isActive ?? false) return;

        _throttle = Timer(const Duration(milliseconds: 500), () {
          if (mounted) { 
            setState(() {
              _spots = processedData['spots'] ?? [];
              _minTimeMs = processedData['minTimeMs'] ?? _minTimeMs;
              _chartMaxX = processedData['chartMaxX'] ?? _chartMaxX;
              _finalMaxY = processedData['finalMaxY'] ?? _finalMaxY;
              _dynamicIntervalY = processedData['dynamicIntervalY'] ?? 0.1; // NOVO: Atualiza o intervalo
              _isLoading = false;
            });
          }
        });
      },
      onError: (Object error) {
        debugPrint('Erro no Stream: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  // NOVO: Função para calcular um intervalo 'agradável' para os marcadores
  double _calculateNiceInterval(double range, int targetTicks) {
    if (range <= 0) return 0.1; 
    
    final double unroundedInterval = range / targetTicks;
    
    // Encontra a potência de 10 mais próxima
    final double exponent = (log(unroundedInterval) / log(10)).floorToDouble();
    final double factor = unroundedInterval / pow(10, exponent);
    
    double niceFactor;
    // Arredonda para 1, 2, ou 5
    if (factor < 1.0) niceFactor = 1.0;
    else if (factor < 2.0) niceFactor = 2.0;
    else if (factor < 5.0) niceFactor = 5.0;
    else niceFactor = 10.0;
    
    return niceFactor * pow(10, exponent);
  }

  Map<String, dynamic> _processData(dynamic data) {
    final List<PowerData> chartData = [];
    if (data is Map) {
      data.forEach((key, value) {
        if (value is Map &&
            value.containsKey('timestamp') &&
            value.containsKey('value')) {
          try {
            final dynamic rawTimestamp = value['timestamp'];
            final dynamic rawPowerValue = value['value'];
            
            // Tratamento de timestamp para garantir leitura de double/int de 64-bit
            int? timestamp = (rawTimestamp is num)
                ? rawTimestamp.toInt()
                : int.tryParse(rawTimestamp.toString());
                
            double? powerValue = (rawPowerValue is num)
                ? rawPowerValue.toDouble()
                : num.tryParse(rawPowerValue.toString())?.toDouble();

            if (timestamp == null || timestamp == 0 || powerValue == null) {
              return;
            }
            
            chartData.add(
              PowerData(
                DateTime.fromMillisecondsSinceEpoch(timestamp),
                powerValue,
              ),
            );
          } catch (e) {
            debugPrint('Erro ao processar item do log: $e. Pulando.');
          }
        }
      });
      chartData.sort((a, b) => a.time.compareTo(b.time));
    }

    if (chartData.isEmpty) {
      return {'spots': <FlSpot>[]};
    }

    final List<FlSpot> rawSpots = chartData.map((data) {
      return FlSpot(
          data.time.millisecondsSinceEpoch.toDouble(), data.value / 1000);
    }).toList();
    
    final List<FlSpot> spots = rawSpots.where((spot) {
      return spot.x.isFinite && spot.y.isFinite;
    }).toList();
    
    if (spots.isEmpty) {
      return {'spots': <FlSpot>[]};
    }

    // Cálculos dos limites X
    final double minTimeMs = spots.first.x;
    double chartMaxX = spots.last.x;
    if (minTimeMs == chartMaxX) {
      chartMaxX += 60000;
    }

    // Cálculos dos limites Y (Máximo Dinâmico)
    double maxSpotValue =
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    const double requiredMinY = 0.9;
    final double dynamicMaxY = maxSpotValue * 1.1;
    final double finalMaxY =
        (dynamicMaxY > requiredMinY) ? dynamicMaxY : requiredMinY;
        
    // NOVO: Cálculo do intervalo dinâmico
    final double dynamicIntervalY = _calculateNiceInterval(finalMaxY, 5);
        
    // 11. Retorna os dados processados
    return {
      'spots': spots,
      'minTimeMs': minTimeMs,
      'chartMaxX': chartMaxX,
      'finalMaxY': finalMaxY,
      'dynamicIntervalY': dynamicIntervalY, // NOVO VALOR RETORNADO
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfico de Potência'),
      ),
      body: Center( 
        child: _buildChart(),
      ),
    );
  }

  Widget _buildChart() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    
    if (_spots.isEmpty) {
      return const Text('Nenhum dado válido para o gráfico.');
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 400,
        width: 250, 
        child: LineChart(
          LineChartData(
            minX: _minTimeMs,
            maxX: _chartMaxX,
            minY: 0,
            maxY: _finalMaxY, // Limite Máximo Dinâmico
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                axisNameWidget: const Text('Potência (kVA)'),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 70,
                  interval: _dynamicIntervalY, // NOVO: Intervalo Dinâmico
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Text('Tempo'),
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: 300000,
                  getTitlesWidget: (value, meta) {
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return SideTitleWidget(
                      space: 8.0,
                      meta: meta,
                      angle: 45,
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
                spots: _spots, 
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
  }
}
