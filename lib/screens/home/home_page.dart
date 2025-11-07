// ignore_for_file: file_names

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart'; // Usado para Material App e widgets
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled1/firebase_options.dart';
import 'package:untitled1/main.dart';
import 'package:ntp/ntp.dart'; // Importa o pacote NTP
import 'package:untitled1/screens/power_chart/power_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
  // Referência para o LED 1
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('led_control');
  // NOVO: Referência para o LED 2
  final DatabaseReference _dbRef2 = FirebaseDatabase.instance.ref('led_control2');
  // Referência para o nó power_logs
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

  // Função para ligar/desligar o LED 1 (Original)
  void _setLedStatus(String status) async {
    try {
      await _dbRef.update({"Led_Status": status});
      debugPrint('Comando "$status" (LED 1) enviado com sucesso!'); // Identificação alterada
      
      // Opcional: Chama a função de log de potência após ligar/desligar
      // Simulamos um valor aleatório de potência quando liga/desliga
      if (status == 'on') {
        _logPowerData(150.0 + (50 * (DateTime.now().second % 5))); // Exemplo de valor simulado
      } else {
         _logPowerData(0.5); // Quase zero quando desligado
      }

    } catch (error) {
      debugPrint('ERRO ao enviar comando "$status" (LED 1): $error'); // Identificação alterada
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar comando (LED 1): $error')), // Identificação alterada
        );
      }
    }
  }

  // NOVO: Função para ligar/desligar o LED 2 (Nó: led_control2)
  void _setLedStatus2(String status) async {
    try {
      await _dbRef2.update({"Led_Status": status}); // Usa a nova referência (_dbRef2)
      debugPrint('Comando "$status" (LED 2) enviado com sucesso!'); 
      
      // Nota: A lógica de log de potência foi removida aqui, assumindo que ela é específica para o LED 1.

    } catch (error) {
      debugPrint('ERRO ao enviar comando "$status" (LED 2): $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar comando (LED 2): $error')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONTROLE ON/OFF'),
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
            // NOVO ITEM: LOGOUT
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair (Logout)'),
              onTap: () async {
                Navigator.pop(context); // Fecha o drawer
                await FirebaseAuth.instance.signOut(); // <--- CHAMA O LOGOUT DO FIREBASE
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView( // CORREÇÃO DO ERRO DE OVERFLOW
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Identificação e botões do LED 1 (Original)
                const Text( // NOVO: Título para o LED 1
                  'Controle Lâmpada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () => _setLedStatus('on'), // Usa _setLedStatus (LED 1)
                      icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                      label: const Text('Ligar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _setLedStatus('off'), // Usa _setLedStatus (LED 1)
                      label: const Text('Desligar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),

                const SizedBox(height: 40), // Espaço entre os controles

                // NOVO: Identificação e botões do LED 2
                const Text( // NOVO: Título para o LED 2
                  'Controle Tomadas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () => _setLedStatus2('on'), // NOVO: Usa _setLedStatus2
                      icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                      label: const Text('Ligar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _setLedStatus2('off'), // NOVO: Usa _setLedStatus2
                      label: const Text('Desligar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
                // FIM: NOVO CONTROLE

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
  
                // INÍCIO: CAMPO DE EXIBIÇÃO DA POTÊNCIA INSTANTÂNEA
                const SizedBox(height: 40),
                const Text(
                  'Monitoramento de Potência:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                StreamBuilder(
                  // Escuta apenas o último registro do nó 'power_logs'
                  stream: _powerLogRef.limitToLast(1).onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasError) {
                      return Text('Erro ao carregar potência: ${snapshot.error}');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Aguardando dados...', style: TextStyle(fontSize: 24));
                    }
                    
                    final dynamic data = snapshot.data?.snapshot.value;
                    double instantPower = 0.0;
                    
                    // LÓGICA CORRIGIDA: Usa apenas o 'is Map' e verifica a existência da chave
                    if (data is Map && data.isNotEmpty) {
                        // data é o mapa dos logs: {key: {timestamp: X, value: Y}}
                        final latestLog = data.values.first; // Pega o objeto interno {timestamp: X, value: Y}
                        
                        if (latestLog is Map && latestLog.containsKey('value')) { 
                            final powerValue = latestLog['value'];
                            if (powerValue is num) {
                              instantPower = powerValue.toDouble();
                            }
                        }
                    }
                    
                    // Exibe a potência instantânea, formatando para 2 casas decimais e em VA
                    return Text(
                      'Potência Total Consumida: ${instantPower.toStringAsFixed(2)} VA',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    );
                  },
                ),
                // FIM: CAMPO DE EXIBIÇÃO DA POTÊNCIA INSTANTÂNEA
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart'; // Usado para Material App e widgets
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled1/firebase_options.dart';
import 'package:untitled1/main.dart';
import 'package:ntp/ntp.dart'; // Importa o pacote NTP
import 'package:untitled1/screens/power_chart/power_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';


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
  // Referência para o nó power_logs
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
            // NOVO ITEM: LOGOUT
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair (Logout)'),
              onTap: () async {
                Navigator.pop(context); // Fecha o drawer
                await FirebaseAuth.instance.signOut(); // <--- CHAMA O LOGOUT DO FIREBASE
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView( // CORREÇÃO DO ERRO DE OVERFLOW
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
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
  
                // INÍCIO: CAMPO DE EXIBIÇÃO DA POTÊNCIA INSTANTÂNEA (LÓGICA CORRIGIDA)
                const SizedBox(height: 40),
                const Text(
                  'Monitoramento de Potência:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                StreamBuilder(
                  // Escuta apenas o último registro do nó 'power_logs'
                  stream: _powerLogRef.limitToLast(1).onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasError) {
                      return Text('Erro ao carregar potência: ${snapshot.error}');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Aguardando dados...', style: TextStyle(fontSize: 24));
                    }
                    
                    final dynamic data = snapshot.data?.snapshot.value;
                    double instantPower = 0.0;
                    
                    // LÓGICA CORRIGIDA: Usa apenas o 'is Map' e verifica a existência da chave
                    if (data is Map && data.isNotEmpty) {
                        // data é o mapa dos logs: {key: {timestamp: X, value: Y}}
                        final latestLog = data.values.first; // Pega o objeto interno {timestamp: X, value: Y}
                        
                        if (latestLog is Map && latestLog.containsKey('value')) { 
                            final powerValue = latestLog['value'];
                            if (powerValue is num) {
                              instantPower = powerValue.toDouble();
                            }
                        }
                    }
                    
                    // Exibe a potência instantânea, formatando para 2 casas decimais e em VA
                    return Text(
                      'Potência Instantânea: ${instantPower.toStringAsFixed(2)} VA',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    );
                  },
                ),
                // FIM: CAMPO DE EXIBIÇÃO DA POTÊNCIA INSTANTÂNEA
              ],
            ),
          ),
        ),
      ),
    );
  }
}*/

