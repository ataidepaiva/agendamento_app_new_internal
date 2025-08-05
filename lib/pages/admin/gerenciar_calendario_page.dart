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
          if (dataViagemTimestamp == null) continue; // Pula se dataViagem for nula
          final dataViagem = dataViagemTimestamp.toDate();
          final diaUtc = DateTime.utc(
            dataViagem.year,
            dataViagem.month,
            dataViagem.day,
          );

          if (agendamentos[diaUtc] == null) {
            agendamentos[diaUtc] = [];
          }
          agendamentos[diaUtc]!.add(data);
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
    return TableCalendar(
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
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isNotEmpty) {
              return Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '${events.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      );
  }
}