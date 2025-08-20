import 'package:flutter/material.dart';
import 'package:agendamento_app/pages/admin/gerenciar_calendario_page.dart';
import 'package:agendamento_app/pages/admin/graficos_page.dart';

class VisualizarPage extends StatefulWidget {
  const VisualizarPage({super.key});

  @override
  State<VisualizarPage> createState() => _VisualizarPageState();
}

class _VisualizarPageState extends State<VisualizarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              color: Theme.of(context).colorScheme.surface,
            ),
            tabs: const [
              Tab(text: 'Calendário', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Gráficos', icon: Icon(Icons.bar_chart)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                GerenciarCalendarioPage(),
                GraficosPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
