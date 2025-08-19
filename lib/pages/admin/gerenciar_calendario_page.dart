import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class GerenciarCalendarioPage extends StatefulWidget {
  const GerenciarCalendarioPage({super.key});

  @override
  State<GerenciarCalendarioPage> createState() =>
      _GerenciarCalendarioPageState();
}

class _GerenciarCalendarioPageState extends State<GerenciarCalendarioPage> {
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

          agendamentos.putIfAbsent(diaUtc, () => []);
          agendamentos[diaUtc]!.add({...data, 'id': doc.id});
        }
      }

      for (var dia in agendamentos.keys) {
        agendamentos[dia]!.sort((a, b) {
          final horaA = (a['dataViagem'] as Timestamp).toDate();
          final horaB = (b['dataViagem'] as Timestamp).toDate();
          return horaA.compareTo(horaB);
        });
      }

      if (mounted) {
        setState(() {
          _agendamentosPorDia = agendamentos;
        });
      }
    });
  }

  List<Map<String, dynamic>> _getAgendamentosParaDia(DateTime day) {
    return _agendamentosPorDia[DateTime.utc(day.year, day.month, day.day)] ??
        [];
  }

  

  String _formatarDataHora(Timestamp? timestamp) {
    if (timestamp == null) return 'Sem data';
    final data = timestamp.toDate();
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  void _mostrarListaDetalhes(
    BuildContext context,
    List<Map<String, dynamic>> agendamentos,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agendamentos do Dia'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: agendamentos.map((a) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📝 ${a['descricao'] ?? 'N/A'}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("👤 Usuário: ${a['usuario'] ?? 'N/A'}"),
                        Text("📍 Destino: ${a['destino'] ?? 'N/A'}"),
                        Text("📅 Data: ${_formatarDataHora(a['dataViagem'])}"),
                        Text("📌 Status: ${a['status'] ?? 'N/A'}"),
                        const Divider(),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
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
          final agendamentos = _getAgendamentosParaDia(selectedDay);
          if (agendamentos.isNotEmpty) {
            _mostrarListaDetalhes(context, agendamentos);
          }
        },
        eventLoader: _getAgendamentosParaDia,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          markerDecoration: BoxDecoration(
            color: Color(0xFFFFCDD2),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }
}
