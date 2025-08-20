import 'package:agendamento_app/pages/admin/admin_table_page.dart';
import 'package:flutter/material.dart';
import 'package:agendamento_app/pages/admin/admin_home_content_page.dart';
import 'package:agendamento_app/pages/admin/gerenciar_page.dart';
import 'package:agendamento_app/pages/admin/visualizar_page.dart';
import 'package:agendamento_app/pages/admin/gerenciar_agendamentos_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final List<Widget> _widgetOptions = <Widget>[
    const AdminHomeContentPage(),
    const GerenciarAgendamentosPage(),
    const AdminTablePage(),
    const VisualizarPage(),
    const GerenciarPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _widgetOptions.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Administrativo'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Sair', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final router = GoRouter.of(context);
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  router.go('/login');
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red, // Highlight with red background
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.home),
                text: 'Home',
              ),
              Tab(
                icon: Icon(Icons.list_alt),
                text: 'Agendamentos',
              ),
              Tab(
                icon: Icon(Icons.table_chart),
                text: 'Tabela',
              ),
              Tab(
                icon: Icon(Icons.visibility),
                text: 'Visualizar',
              ),
              Tab(
                icon: Icon(Icons.manage_accounts),
                text: 'Gerenciar',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: _widgetOptions,
        ),
      ),
    );
  }
}
