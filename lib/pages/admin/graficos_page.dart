// lib/pages/admin/graficos_page.dart
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
  Map<String, int> setorCounts = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('agendamentos')
        .get();

    final tempStatusCounts = <String, int>{};
    final tempMotoristaCounts = <String, int>{};
    final tempVeiculoCounts = <String, int>{};
    final tempSetorCounts = <String, int>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? 'desconhecido').toString();
      final motoristaId = (data['motoristaId'] ?? 'Sem Motorista').toString();
      final veiculoId = (data['veiculoId'] ?? 'Sem Veículo').toString();
      final setor = (data['setor'] ?? 'Sem Setor').toString();

      tempStatusCounts[status] = (tempStatusCounts[status] ?? 0) + 1;
      tempMotoristaCounts[motoristaId] =
          (tempMotoristaCounts[motoristaId] ?? 0) + 1;
      tempVeiculoCounts[veiculoId] = (tempVeiculoCounts[veiculoId] ?? 0) + 1;
      tempSetorCounts[setor] = (tempSetorCounts[setor] ?? 0) + 1;
    }

    setState(() {
      statusCounts = tempStatusCounts;
      motoristaCounts = tempMotoristaCounts;
      veiculoCounts = tempVeiculoCounts;
      setorCounts = tempSetorCounts;
      _carregando = false;
    });
  }

  List<PieChartSectionData> _buildSections(Map<String, int> dataMap) {
    final total = dataMap.values.fold<int>(
      0,
      (previousValue, val) => previousValue + val,
    );
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
    ];

    int colorIndex = 0;
    return dataMap.entries.map((entry) {
      final value = entry.value.toDouble();
      final percentage = (value / total) * 100;
      final section = PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: value,
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      colorIndex++;
      return section;
    }).toList();
  }

  Widget _buildPieChart(String title, Map<String, int> dataMap) {
    if (dataMap.isEmpty) {
      return Center(child: Text('Nenhum dado para $title'));
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sections: _buildSections(dataMap),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _carregando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPieChart('Agendamentos por Status', statusCounts),
                _buildPieChart('Agendamentos por Setor', setorCounts),
                _buildPieChart('Agendamentos por Veículo', veiculoCounts),
              ],
            ),
          );
  }
}
