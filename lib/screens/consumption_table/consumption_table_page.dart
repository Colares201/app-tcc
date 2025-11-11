// 
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:untitled1/model/power_date.dart'; // Importa o modelo PowerData

class ConsumptionTablePage extends StatelessWidget {
  const ConsumptionTablePage({super.key});

  // Função auxiliar para formatar o timestamp
  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Referência para os logs de potência, limitada aos últimos 15
    final DatabaseReference powerLogRef = FirebaseDatabase.instance.ref('power_logs');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabela de Consumo (Últimos 15)'),
      ),
      body: StreamBuilder(
        // Escuta os últimos 15 registros
        stream: powerLogRef.orderByChild('timestamp').limitToLast(15).onValue,//stream: powerLogRef.limitToLast(15).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<PowerData> logs = [];
          final data = snapshot.data?.snapshot.value;

          if (data is Map) {
            // Processa o mapa de logs
            (data).forEach((key, value) {
              if (value is Map && value.containsKey('timestamp') && value.containsKey('value')) {
                final int timestamp = value['timestamp'];
                final num powerValue = value['value'];
                
                // Cria o objeto PowerData
                logs.add(PowerData(
                  DateTime.fromMillisecondsSinceEpoch(timestamp), 
                  powerValue.toDouble(),
                ));
              }
            });
            // Inverte a lista para mostrar os mais recentes no topo
            logs = logs.reversed.toList();
          }

          if (logs.isEmpty) {
            return const Center(child: Text('Nenhum dado de consumo encontrado.'));
          }

          // Exibe os dados em uma tabela
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Data/Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Potência (VA)', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                ],
                rows: logs.map((log) => DataRow(cells: [
                  DataCell(Text(_formatDateTime(log.time))),
                  DataCell(Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      log.value.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )),
                ])).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}