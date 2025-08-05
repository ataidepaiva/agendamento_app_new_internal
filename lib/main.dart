import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agendamento_app/core/router/app_router.dart'; // Importando o arquivo de rotas
import 'package:agendamento_app/firebase_options.dart'; // Certifique-se de que esse arquivo está correto
import 'package:agendamento_app/core/theme/app_theme.dart'; // Importando o tema centralizado

void main() async {
  // Inicialização do Flutter e Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Inicializa o Firebase
  runApp(const MyApp()); // Inicia o aplicativo
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig:
          router, // Passando a configuração do GoRouter para o MaterialApp.router
      title: 'Agendamento de Veículos', // Título do App
      debugShowCheckedModeBanner: false, // Desativa o banner de debug
      theme: appTheme, // Usando o tema centralizado
    );
  }
}
