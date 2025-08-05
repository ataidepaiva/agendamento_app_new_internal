import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GerenciarPage extends StatelessWidget {
  const GerenciarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildManagementCard(
                context,
                icon: Icons.person,
                title: 'Gerenciar Usuários',
                onTap: () => context.push('/admin/users'),
              ),
              const SizedBox(height: 16.0),
              _buildManagementCard(
                context,
                icon: Icons.drive_eta,
                title: 'Gerenciar Motoristas',
                onTap: () => context.push('/admin/drivers'),
              ),
              const SizedBox(height: 16.0),
              _buildManagementCard(
                context,
                icon: Icons.school,
                title: 'Gerenciar Escolas',
                onTap: () => context.push('/admin/schools'),
              ),
              const SizedBox(height: 16.0),
              _buildManagementCard(
                context,
                icon: Icons.directions_car,
                title: 'Gerenciar Veículos',
                onTap: () => context.push('/admin/vehicles'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, size: 50.0, color: Theme.of(context).primaryColor),
              const SizedBox(height: 10.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
