import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class GerenciarCalendarioPage extends StatefulWidget {
  const GerenciarCalendarioPage({super.key});

  @override
  GerenciarCalendarioPageState createState() => GerenciarCalendarioPageState();
}

class GerenciarCalendarioPageState extends State<GerenciarCalendarioPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _agendamentosPorDia = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _carregarAgendamentos();
  }

  void _carregarAgendamentos() {
    FirebaseFirestore.instance.collection('agendamentos').snapshots().listen((
      snapshot,
    ) {
      final Map<DateTime, List<Map<String, dynamic>>> agendamentos = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toLowerCase();
        if (status == 'confirmado' || status == 'concluido') {
          final dataViagemTimestamp = data['dataViagem'] as Timestamp?;
          if (dataViagemTimestamp == null) continue;

          final dataViagem = dataViagemTimestamp.toDate();
          final diaUtc = DateTime.utc(
            dataViagem.year,
            dataViagem.month,
            dataViagem.day,
          );

          if (agendamentos[diaUtc] == null) {
            agendamentos[diaUtc] = [];
          }

          agendamentos[diaUtc]!.add({...data, 'id': doc.id});
        }
      }

      setState(() {
        _agendamentosPorDia = agendamentos;
      });
    });
  }

  List<Map<String, dynamic>> _getAgendamentosParaDia(DateTime day) {
    return _agendamentosPorDia[DateTime.utc(day.year, day.month, day.day)] ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário de Agendamentos')),
      body: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2026, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        eventLoader: _getAgendamentosParaDia,
        calendarStyle: const CalendarStyle(outsideDaysVisible: false),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final agendamentos = _getAgendamentosParaDia(day);

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(4),
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.day}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...agendamentos.map((agendamento) {
                    return GestureDetector(
                      onTap: () {
                        _mostrarDetalhesAgendamento(context, agendamento);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _corPorStatus(agendamento['status']),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          agendamento['descricao'] ?? 'Agendamento',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  })
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Retorna cor diferente por status
  Color _corPorStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'concluido':
        return Colors.green;
      case 'confirmado':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  /// Mostra modal com mais detalhes do agendamento
  void _mostrarDetalhesAgendamento(
    BuildContext context,
    Map<String, dynamic> agendamento,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detalhes do Agendamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Descrição: ${agendamento['descricao'] ?? 'N/A'}"),
              const SizedBox(height: 8),
              Text("Usuário: ${agendamento['usuario'] ?? 'N/A'}"),
              const SizedBox(height: 8),
              Text("Status: ${agendamento['status'] ?? 'N/A'}"),
              const SizedBox(height: 8),
              Text("Destino: ${agendamento['destino'] ?? 'N/A'}"),
              const SizedBox(height: 8),
              Text("Data: ${_formatarData(agendamento['dataViagem'])}"),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return 'Sem data';
    final data = timestamp.toDate();
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
