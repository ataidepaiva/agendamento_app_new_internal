import 'package:agendamento_app/pages/admin/admin_table_page.dart';
import 'package:flutter/material.dart';
import 'package:agendamento_app/pages/admin/admin_home_content_page.dart';
import 'package:agendamento_app/pages/admin/gerenciar_page.dart';
import 'package:agendamento_app/pages/admin/visualizar_page.dart';
import 'package:agendamento_app/pages/admin/gerenciar_agendamentos_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const AdminHomeContentPage(),
    const GerenciarAgendamentosPage(),
    const AdminTablePage(),
    const VisualizarPage(),
    const GerenciarPage(),
  ];

  static const List<String> _widgetTitles = <String>[
    'Painel Administrativo',
    'Gerenciar Agendamentos',
    'Tabela de Agendamentos',
    'Visualizar',
    'Gerenciar',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetTitles.elementAt(_selectedIndex)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Agendamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'Tabela',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility),
            label: 'Visualizar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: 'Gerenciar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
