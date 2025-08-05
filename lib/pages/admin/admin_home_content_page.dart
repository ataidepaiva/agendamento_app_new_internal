import 'package:flutter/material.dart';

class AdminHomeContentPage extends StatelessWidget {
  const AdminHomeContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 100,
            color: Colors.blueGrey,
          ),
          SizedBox(height: 20),
          Text(
            'Bem-vindo ao Painel Administrativo!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Use a navegação abaixo para gerenciar o sistema.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
