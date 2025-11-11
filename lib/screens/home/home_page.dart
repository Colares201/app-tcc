// ignore_for_file: file_names

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart'; // Usado para Material App e widgets
import 'package:firebase_core/firebase_core.dart';
// Removido: 'package:ntp/ntp.dart'; // Não é mais necessário no app
import 'package:untitled1/firebase_options.dart';
import 'package:untitled1/main.dart';
import 'package:untitled1/screens/power_chart/power_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ADICIONAR NOVA IMPORTAÇÃO
import 'package:untitled1/screens/consumption_table/consumption_table_page.dart';


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
  // Referência para o LED 2
  final DatabaseReference _dbRef2 = FirebaseDatabase.instance.ref('led_control2');
  // Referência para o nó power_logs (agora usado APENAS para leitura)
  final DatabaseReference _powerLogRef = FirebaseDatabase.instance.ref('power_logs');
  
  // -----------------------------------------------------------------
  // FUNÇÃO _getNtpTime() REMOVIDA
  // Não é mais necessária, pois o app não envia mais logs de tempo.
  // -----------------------------------------------------------------

  // -----------------------------------------------------------------
  // FUNÇÃO _logPowerData() REMOVIDA
  // Não é mais necessária. A placa ESP é a única fonte de logs.
  // -----------------------------------------------------------------

  // Função para ligar/desligar o LED 1 (Original)
  void _setLedStatus(String status) async {
    try {
      await _dbRef.update({"Led_Status": status});
      debugPrint('Comando "$status" (LED 1) enviado com sucesso!'); // Identificação alterada
      
      // -----------------------------------------------------------------
      // BLOCO DE LOG DE POTÊNCIA REMOVIDO DAQUI
      // A placa ESP fará a medição de mudança de consumo automaticamente.
      // -----------------------------------------------------------------

    } catch (error) {
      debugPrint('ERRO ao enviar comando "$status" (LED 1): $error'); // Identificação alterada
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar comando (LED 1): $error')), // Identificação alterada
        );
      }
    }
  }

  // Função para ligar/desligar o LED 2 (Nó: led_control2)
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
              title: const Text('Controle ON/OFF'),
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
            // NOVO ITEM: TABELA DE CONSUMO
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Tabela de Consumo'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConsumptionTablePage()),
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
                const Text( // Título para o LED 1
                  'Controle Lâmpada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // INÍCIO: CAMPO DE EXIBIÇÃO DE STATUS DA LÂMPADA
                StreamBuilder(
                  stream: _dbRef.onValue, // Escuta o nó 'led_control'
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      // O valor é um Map<dynamic, dynamic> que contém o Led_Status
                      final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      final String rawStatus = data['Led_Status']?.toString() ?? 'off';
                      final status = rawStatus == 'on' ? 'LIGADO' : 'DESLIGADO';
                      final color = rawStatus == 'on' ? Colors.green : Colors.red;
                      return Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      );
                    }
                    return const Text('Status: Desconhecido');
                  },
                ),
                const SizedBox(height: 15), // Espaço adicionado para separar status dos botões
                // FIM: CAMPO DE EXIBIÇÃO DE STATUS DA LÂMPADA
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

                // Identificação e botões do LED 2
                const Text( // Título para o LED 2
                  'Controle Tomadas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // INÍCIO: CAMPO DE EXIBIÇÃO DE STATUS DAS TOMADAS
                StreamBuilder(
                  stream: _dbRef2.onValue, // Escuta o nó 'led_control2'
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      // O valor é um Map<dynamic, dynamic> que contém o Led_Status
                      final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      final String rawStatus = data['Led_Status']?.toString() ?? 'off';
                      final status = rawStatus == 'on' ? 'LIGADO' : 'DESLIGADO';
                      final color = rawStatus == 'on' ? Colors.green : Colors.red;
                      return Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      );
                    }
                    return const Text('Status: Desconhecido');
                  },
                ),
                const SizedBox(height: 15), // Espaço adicionado para separar status dos botões
                // FIM: CAMPO DE EXIBIÇÃO DE STATUS DAS TOMADAS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () => _setLedStatus2('on'), // Usa _setLedStatus2
                      icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                      label: const Text('Ligar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _setLedStatus2('off'), // Usa _setLedStatus2
                      label: const Text('Desligar', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
                // FIM: NOVO CONTROLE

                // O botão de log manual foi completamente removido.
  
                // INÍCIO: CAMPO DE EXIBIÇÃO DA POTÊNCIA INSTANTÂNEA E CUSTO
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
                    
                    if (data is Map && data.isNotEmpty) {
                        final latestLog = data.values.first;
                        
                        if (latestLog is Map && latestLog.containsKey('value')) { 
                            final powerValue = latestLog['value'];
                            if (powerValue is num) {
                              instantPower = powerValue.toDouble();
                            }
                        }
                    }
                    
                    // Cálculo do custo estimado (Potência * 0.8)
                    final double estimatedCost = instantPower * 0.8;
                    
                    // Retorna um Column para exibir dois textos
                    return Column(
                      children: [
                        // Exibe a potência instantânea
                        Text(
                          'Potência Total Consumida: ${instantPower.toStringAsFixed(2)} VA',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Exibe o custo estimado em R$
                        Text(
                          'Custo Estimado (R\$): R\$ ${estimatedCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 176, 39, 39), // Cor diferente para destaque
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // FIM: CAMPO DE EXIBIÇÃO DA POTÊNCIA INSTANTÂNEA E CUSTO
              ],
            ),
          ),
        ),
      ),
    );
  }
} //neste codigo a tensao gerada pelo botao liga/desliga nao é enviada deixando o app como leitor e controlador
/*// ignore_for_file: file_names

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart'; // Usado para Material App e widgets
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled1/consumption_table/consumption_table_page.dart';
import 'package:untitled1/firebase_options.dart';
import 'package:untitled1/main.dart';
import 'package:ntp/ntp.dart'; // Importa o pacote NTP
import 'package:untitled1/screens/power_chart/power_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled1/screens/consumption_table/consumption_table_page.dart';


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
            // NOVO ITEM: TABELA DE CONSUMO
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Tabela de Consumo'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConsumptionTablePage()),
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
                // INÍCIO: CAMPO DE EXIBIÇÃO DE STATUS DA LÂMPADA
                StreamBuilder(
                  stream: _dbRef.onValue, // Escuta o nó 'led_control'
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      // O valor é um Map<dynamic, dynamic> que contém o Led_Status
                      final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      final String rawStatus = data['Led_Status']?.toString() ?? 'off';
                      final status = rawStatus == 'on' ? 'LIGADO' : 'DESLIGADO';
                      final color = rawStatus == 'on' ? Colors.green : Colors.red;
                      return Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      );
                    }
                    return const Text('Status: Desconhecido');
                  },
                ),
                const SizedBox(height: 15), // Espaço adicionado para separar status dos botões
                // FIM: CAMPO DE EXIBIÇÃO DE STATUS DA LÂMPADA
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
                // INÍCIO: CAMPO DE EXIBIÇÃO DE STATUS DAS TOMADAS
                StreamBuilder(
                  stream: _dbRef2.onValue, // Escuta o nó 'led_control2'
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      // O valor é um Map<dynamic, dynamic> que contém o Led_Status
                      final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                      final String rawStatus = data['Led_Status']?.toString() ?? 'off';
                      final status = rawStatus == 'on' ? 'LIGADO' : 'DESLIGADO';
                      final color = rawStatus == 'on' ? Colors.green : Colors.red;
                      return Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      );
                    }
                    return const Text('Status: Desconhecido');
                  },
                ),
                const SizedBox(height: 15), // Espaço adicionado para separar status dos botões
                // FIM: CAMPO DE EXIBIÇÃO DE STATUS DAS TOMADAS
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

                // Código para o botão "Logar Potência Manualmente" (COMENTADO)
                /*
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
                */
  
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
}*/

