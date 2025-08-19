import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficosPage extends StatefulWidget {
  const GraficosPage({super.key});

  @override
  State<GraficosPage> createState() => _GraficosPageState();
}

class _GraficosPageState extends State<GraficosPage> {
  bool _carregando = true;

  Map<String, int> statusCounts = {};
  Map<String, int> motoristaCounts = {};
  Map<String, int> veiculoCounts = {};
  Map<String, String> motoristaNomes = {}; // ID → Nome

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final agendamentosSnapshot = await FirebaseFirestore.instance
        .collection('agendamentos')
        .get();

    final tempStatusCounts = <String, int>{};
    final tempMotoristaCounts = <String, int>{};
    final tempVeiculoCounts = <String, int>{};

    for (var doc in agendamentosSnapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? 'desconhecido').toString();
      final motoristaId = (data['motoristaId'] ?? 'Sem Motorista').toString();
      final veiculoId = (data['veiculoId'] ?? 'Sem Veículo').toString();

      tempStatusCounts[status] = (tempStatusCounts[status] ?? 0) + 1;
      tempMotoristaCounts[motoristaId] =
          (tempMotoristaCounts[motoristaId] ?? 0) + 1;
      tempVeiculoCounts[veiculoId] = (tempVeiculoCounts[veiculoId] ?? 0) + 1;
    }

    final motoristasSnapshot = await FirebaseFirestore.instance
        .collection('motoristas')
        .get();
    final tempMotoristaNomes = <String, String>{};
    for (var doc in motoristasSnapshot.docs) {
      final data = doc.data();
      final nome = data['nome']?.toString() ?? 'Sem Nome';
      tempMotoristaNomes[doc.id] = nome;
    }

    setState(() {
      statusCounts = tempStatusCounts;
      motoristaCounts = tempMotoristaCounts;
      veiculoCounts = tempVeiculoCounts;
      motoristaNomes = tempMotoristaNomes;
      _carregando = false;
    });
  }

  List<Color> chartColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.cyan,
    Colors.amber,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];

  Widget _buildPieChartComLegendaLateral(
    String title,
    Map<String, int> dataMap, {
    Map<String, String>? nomeMap,
  }) {
    if (dataMap.isEmpty) {
      return Center(child: Text('Nenhum dado para $title'));
    }

    final displayMap = <String, int>{};
    dataMap.forEach((id, valor) {
      final nome = nomeMap?[id] ?? id;
      displayMap[nome] = valor;
    });

    final total = displayMap.values.fold<int>(0, (prev, val) => prev + val);
    final sections = <PieChartSectionData>[];
    final legendItems = <Widget>[];
    int colorIndex = 0;

    displayMap.forEach((nome, valor) {
      final color = chartColors[colorIndex % chartColors.length];
      final percentage = total == 0 ? 0 : (valor / total) * 100;

      sections.add(
        PieChartSectionData(
          color: color,
          value: valor.toDouble(),
          title: '',
          radius: 60,
        ),
      );

      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(width: 16, height: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$nome (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );

      colorIndex++;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: legendItems,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gráficos de Agendamentos')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPieChartComLegendaLateral(
                    'Agendamentos por Status',
                    statusCounts,
                  ),
                  _buildPieChartComLegendaLateral(
                    'Agendamentos por Motorista',
                    motoristaCounts,
                    nomeMap: motoristaNomes,
                  ),
                  _buildPieChartComLegendaLateral(
                    'Agendamentos por Veículo',
                    veiculoCounts,
                  ),
                ],
              ),
            ),
    );
  }
}