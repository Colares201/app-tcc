// ignore_for_file: file_names

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart'; // Usado para Material App e widgets
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled1/firebase_options.dart';
import 'package:untitled1/main.dart';
import 'package:ntp/ntp.dart'; // Importa o pacote NTP
import 'package:untitled1/screens/power_chart/power_chart.dart';






// 1. PONTO DE ENTRADA E INICIALIZAÇÃO ASSÍNCRONA
void main() async {
  // Garante que o Flutter esteja pronto para usar plugins
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LedControlApp());
  
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState(); 
}
  
class _HomePageState extends State<HomePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('led_control');
  final DatabaseReference _powerLogRef = FirebaseDatabase.instance.ref('power_logs');
  
  // Função que usa NTP para obter tempo preciso
  Future<DateTime> _getNtpTime() async {
    try {
      // Obtém o tempo preciso do servidor NTP
      return await NTP.now();
    } catch (e) {
      debugPrint('Erro ao obter tempo NTP: $e. Usando tempo local.');
      // Retorna o tempo local como fallback
      return DateTime.now();
    }
  }

  // Função para simular o log de dados de potência com tempo NTP
  void _logPowerData(double powerValue) async {
    final accurateTime = await _getNtpTime();
    
    // Envia o log para o Firebase
    await _powerLogRef.push().set({
      'timestamp': accurateTime.millisecondsSinceEpoch,
      'value': powerValue,
    }).then((_) {
      debugPrint('Log de potência (${powerValue}W) enviado com sucesso.');
    }).catchError((e) {
      debugPrint('Erro ao logar potência: $e');
    });
  }

  // Função para ligar/desligar o LED (mantida do código original)
  void _setLedStatus(String status) async {
    try {
      await _dbRef.update({"Led_Status": status});
      debugPrint('Comando "$status" enviado com sucesso!');
      
      // Opcional: Chama a função de log de potência após ligar/desligar
      // Simulamos um valor aleatório de potência quando liga/desliga
      if (status == 'on') {
        _logPowerData(150.0 + (50 * (DateTime.now().second % 5))); // Exemplo de valor simulado
      } else {
         _logPowerData(0.5); // Quase zero quando desligado
      }

    } catch (error) {
      debugPrint('ERRO ao enviar comando "$status": $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar comando: $error')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Led'),
      ),
      // IMPLEMENTAÇÃO DO DRAWER
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu Principal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb),
              title: const Text('Controle do LED'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('Ver Gráfico de Potência'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PowerChartPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column( // Alterado para Column para logar um dado manualmente
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: () => _setLedStatus('on'), 
                    icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                    label: const Text('Ligar', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _setLedStatus('off'),
                   // icon: const Icon(Icons.lightbulb_off_outlined, color: Colors.white),
                    label: const Text('Desligar', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Botão para simular um novo log (apenas para testes)
              ElevatedButton.icon(
                onPressed: () {
                   // Loga um valor simulado de potência aleatória
                   _logPowerData(100.0 + (50 * (DateTime.now().minute % 5))); 
                }, 
                icon: const Icon(Icons.add_chart),
                label: const Text('Logar Potência Manualmente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}