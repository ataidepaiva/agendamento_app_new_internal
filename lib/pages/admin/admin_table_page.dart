import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Data model to hold all processed data for a row, making it type-safe and easy to manage.
class AgendamentoRow {
  final Timestamp? dataViagem;
  final String solicitante;
  final String descricao;
  final String municipio;
  final String escolas;
  final String status;
  final String motorista;
  final String veiculo;

  AgendamentoRow({
    this.dataViagem,
    required this.solicitante,
    required this.descricao,
    required this.municipio,
    required this.escolas,
    required this.status,
    required this.motorista,
    required this.veiculo,
  });

  // Helper to get a value by its column name (string key)
  dynamic get(String key) {
    switch (key) {
      case 'Data Viagem': return dataViagem;
      case 'Solicitante': return solicitante;
      case 'Descrição': return descricao;
      case 'Município': return municipio;
      case 'Escolas': return escolas;
      case 'Status': return status;
      case 'Motorista': return motorista;
      case 'Veículo': return veiculo;
      default: return '';
    }
  }
}

class AdminTablePage extends StatefulWidget {
  const AdminTablePage({super.key});

  @override
  State<AdminTablePage> createState() => _AdminTablePageState();
}

class _AdminTablePageState extends State<AdminTablePage> {
  // State
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;
  List<AgendamentoRow> _allRows = [];
  List<AgendamentoRow> _filteredRows = [];

  // Filter Controllers & Values
  final Map<String, TextEditingController> _filterControllers = {
    'Data Viagem': TextEditingController(),
    'Solicitante': TextEditingController(),
    'Descrição': TextEditingController(),
    'Status': TextEditingController(),
    'Motorista': TextEditingController(),
    'Veículo': TextEditingController(),
    'Município': TextEditingController(),
    'Escolas': TextEditingController(),
  };
  String? _selectedMonth;
  int? _selectedYear;

  // Constants
  final List<String> _months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  late final List<int> _years;

  @override
  void initState() {
    super.initState();
    _years = List<int>.generate(10, (i) => DateTime.now().year - 5 + i);
    _filterControllers.forEach((_, controller) => controller.addListener(_applyFilters));
    _loadAllData();
  }

  @override
  void dispose() {
    _filterControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('agendamentos').orderBy('dataViagem', descending: true).get(),
        FirebaseFirestore.instance.collection('usuarios').get(),
        FirebaseFirestore.instance.collection('motoristas').get(),
        FirebaseFirestore.instance.collection('veiculos').get(),
      ]);

      final agendamentosSnap = results[0] as QuerySnapshot;
      final usuariosSnap = results[1] as QuerySnapshot;
      final motoristasSnap = results[2] as QuerySnapshot;
      final veiculosSnap = results[3] as QuerySnapshot;

      final usuariosMap = {for (var doc in usuariosSnap.docs) doc.id: doc.data() as Map<String, dynamic>};
      final motoristasMap = {for (var doc in motoristasSnap.docs) doc.id: doc.data() as Map<String, dynamic>};
      final veiculosMap = {for (var doc in veiculosSnap.docs) doc.id: doc.data() as Map<String, dynamic>};

      List<AgendamentoRow> allRows = [];
      for (var doc in agendamentosSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final solicitante = usuariosMap[data['solicitanteId']];
        final motorista = motoristasMap[data['motoristaId']];
        final veiculo = veiculosMap[data['veiculoId']];
        final locais = data['locais'] as List?;
        final municipioDestino = (locais?.isNotEmpty ?? false) ? locais!.last['municipio'] : 'N/A';
        final escolasDestino = (locais?.isNotEmpty ?? false) && locais!.last['escolas'] != null ? (locais.last['escolas'] as List).join(', ') : 'N/A';

        allRows.add(AgendamentoRow(
          dataViagem: data['dataViagem'] as Timestamp?,
          solicitante: solicitante?['nome'] ?? 'N/A',
          descricao: data['descricao'] ?? 'N/A',
          municipio: municipioDestino,
          escolas: escolasDestino,
          status: data['status'] ?? 'N/A',
          motorista: motorista?['nome'] ?? 'N/A',
          veiculo: veiculo?['modelo'] ?? 'N/A',
        ));
      }

      if (mounted) {
        setState(() {
          _allRows = allRows;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e, s) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar dados: ${e.toString()}\n$s';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<AgendamentoRow> filteredList = List.from(_allRows);

    if (_selectedYear != null) {
      filteredList.retainWhere((row) => row.dataViagem?.toDate().year == _selectedYear);
    }
    if (_selectedMonth != null) {
      filteredList.retainWhere((row) => row.dataViagem?.toDate().month == (_months.indexOf(_selectedMonth!) + 1));
    }

    _filterControllers.forEach((key, controller) {
      final filterText = controller.text.toLowerCase();
      if (filterText.isNotEmpty) {
        filteredList.retainWhere((row) {
          dynamic value = row.get(key);
          if (key == 'Data Viagem' && value is Timestamp) {
            return DateFormat('dd/MM/yyyy').format(value.toDate()).toLowerCase().contains(filterText);
          }
          return value.toString().toLowerCase().contains(filterText);
        });
      }
    });

    if (mounted) {
      setState(() {
        _filteredRows = filteredList;
      });
    }
  }

  Future<void> _exportToPdf() async {
    if (_filteredRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não há dados para exportar.')));
      return;
    }
    setState(() => _isExporting = true);

    final pdf = pw.Document();
    final Uint8List logoBytes = (await rootBundle.load('assets/images/logo.jpg')).buffer.asUint8List();
    final logo = pw.MemoryImage(logoBytes);

    String filterDescription = 'Filtros Aplicados: ';
    List<String> activeFilters = [];
    if (_selectedMonth != null) activeFilters.add('Mês: $_selectedMonth');
    if (_selectedYear != null) activeFilters.add('Ano: $_selectedYear');
    _filterControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) activeFilters.add('$key: ${controller.text}');
    });
    filterDescription += activeFilters.isNotEmpty ? activeFilters.join(', ') : 'Geral';

    final tableData = _filteredRows.map((row) {
        return _filterControllers.keys.map((key) {
            dynamic value = row.get(key);
            if (key == 'Data Viagem' && value is Timestamp) {
                return DateFormat('dd/MM/yyyy').format(value.toDate());
            }
            return value?.toString() ?? 'N/A';
        }).toList();
    }).toList();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      header: (context) => pw.Column(children: [
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.SizedBox(height: 60, width: 60, child: pw.Image(logo)),
          pw.SizedBox(width: 20),
          pw.Expanded(child: pw.Text('Sistema Corporativo de Agendamento de Veículos - SRE de Varginha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14), textAlign: pw.TextAlign.center)),
        ]),
        pw.Divider(height: 20),
        pw.Text('Relatório de Agendamento de Veículos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
        pw.SizedBox(height: 5),
        pw.Text(filterDescription, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 15),
      ]),
      build: (context) => [pw.Table.fromTextArray(
        headers: _filterControllers.keys.toList(),
        data: tableData,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        cellStyle: const pw.TextStyle(fontSize: 8),
        border: pw.TableBorder.all(),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellAlignments: { for (var i in Iterable.generate(8)) i : pw.Alignment.centerLeft },
      )],
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    if(mounted) setState(() => _isExporting = false);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))));
    }
    if (_allRows.isEmpty) {
      return const Center(child: Text('Nenhum agendamento encontrado no banco de dados.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: _filterControllers.keys.map((h) => DataColumn(label: Text(h))).toList(),
          rows: _filteredRows.map((rowData) {
            return DataRow(
              cells: _filterControllers.keys.map((key) {
                dynamic value = rowData.get(key);
                String text = value?.toString() ?? 'N/A';
                if (key == 'Data Viagem' && value is Timestamp) {
                  text = DateFormat('dd/MM/yyyy').format(value.toDate());
                }
                return DataCell(Text(text));
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabela de Agendamentos'),
        actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _isExporting ? null : _exportToPdf)],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: DropdownButton<String>(isExpanded: true, hint: const Text('Mês'), value: _selectedMonth, onChanged: (v) { setState(() { _selectedMonth = v; _applyFilters(); }); }, items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList())),
                      const SizedBox(width: 10),
                      Expanded(child: DropdownButton<int>(isExpanded: true, hint: const Text('Ano'), value: _selectedYear, onChanged: (v) { setState(() { _selectedYear = v; _applyFilters(); }); }, items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList())),
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _filterControllers.entries.map((entry) {
                          return SizedBox(
                            width: 180,
                            child: TextField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                labelText: entry.key,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                suffixIcon: IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          entry.value.clear();
                                          _applyFilters();
                                        },
                                      ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
          if (_isExporting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Gerando PDF...', style: TextStyle(color: Colors.white, fontSize: 16))])),
            ),
        ],
      ),
    );
  }
}