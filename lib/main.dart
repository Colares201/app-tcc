// main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- NOVO
import 'firebase_options.dart'; 
import 'package:flutter/material.dart'; 
import 'package:untitled1/screens/home/home_page.dart';
import 'package:untitled1/screens/auth/login_page.dart'; // <--- NOVO
import 'package:firebase_database/firebase_database.dart'; // <--- NOVO: Importar o database

// PONTO DE ENTRADA
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // AÇÃO CHAVE: Habilitar o cache offline do Firebase
  FirebaseDatabase.instance.setPersistenceEnabled(true);
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
      // AQUI USAMOS O StreamBuilder PARA GERENCIAR O ESTADO DE AUTENTICAÇÃO
      home: StreamBuilder<User?>(
        // Observa mudanças no estado de login (usuário logado/deslogado)
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot) {
          // 1. Enquanto espera, mostra o carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 2. Se o usuário estiver logado (snapshot.hasData)
          if (snapshot.hasData) {
            return const HomePage(); // Leva para a tela principal
          }
          
          // 3. Se o usuário NÃO estiver logado
          return const LoginPage(); // Leva para a tela de Login
        },
      ),
    );
  }
}