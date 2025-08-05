import 'package:flutter/material.dart';
import 'package:agendamento_app/pages/admin/gerenciar_calendario_page.dart';
import 'package:agendamento_app/pages/admin/graficos_page.dart';

class VisualizarPage extends StatefulWidget {
  const VisualizarPage({super.key});

  @override
  State<VisualizarPage> createState() => _VisualizarPageState();
}

class _VisualizarPageState extends State<VisualizarPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Número de abas (Calendário e Gráficos)
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Visualizar'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Calendário', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Gráficos', icon: Icon(Icons.bar_chart)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GerenciarCalendarioPage(),
            GraficosPage(),
          ],
        ),
      ),
    );
  }
}
