// main.dart

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:flutter/material.dart'; 
import 'package:untitled1/screens/home/home_page.dart';
// Mude para o caminho correto se necessário

/*void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LedControlApp()); 
}

// 2. CLASSE RAIZ (Nomenclatura Corrigida)
class LedControlApp extends StatelessWidget {
  const LedControlApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de LED Firebase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}*/
 
// PONTO DE ENTRADA
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LedControlApp());
}

class LedControlApp extends StatelessWidget {
  const LedControlApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de LED Firebase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // AQUI IMPORTAMOS E USAMOS O WIDGET DE TELA SEPARADO
      home: const HomePage(), 
    );
  }
}