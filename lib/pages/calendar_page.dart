import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Stream<List<Appointment>> _getAppointmentsStream() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]); // Retorna um stream vazio se o usuário não estiver logado
    }

    return FirebaseFirestore.instance
        .collection('agendamentos')
        .where('email', isEqualTo: user.email)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      final List<Appointment> appointments = [];
      for (QueryDocumentSnapshot<Object?> doc in snapshot.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final Timestamp? dataViagemTimestamp = data['dataViagem'] as Timestamp?;
        if (dataViagemTimestamp != null) {
          final DateTime startTime = dataViagemTimestamp.toDate();
          // Define um endTime padrão de 2 horas após o startTime se não houver um campo específico
          final DateTime endTime = data['endTime'] != null
              ? (data['endTime'] as Timestamp).toDate()
              : startTime.add(const Duration(hours: 2));

          appointments.add(
            Appointment(
              startTime: startTime,
              endTime: endTime,
              subject: data['descricao'] ?? 'Sem descrição',
              color: _getColorForStatus(data['status']),
            ),
          );
        }
      }
      return appointments;
    });
  }

  Color _getColorForStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmado':
        return Colors.amber.shade700;
      case 'concluido':
        return Colors.green;
      case 'pendente':
        return Colors.blue;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Agendamentos')),
      body: StreamBuilder<List<Appointment>>(
        stream: _getAppointmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum agendamento encontrado.'));
          }

          final List<Appointment> appointments = snapshot.data!;
          final _AppointmentDataSource dataSource = _AppointmentDataSource(appointments);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: SfCalendar(
              
              view: CalendarView.month,
              dataSource: dataSource,
              headerStyle: CalendarHeaderStyle(
                backgroundColor: colorScheme.primary,
                textStyle: TextStyle(
                  fontSize: 20,
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              viewHeaderStyle: ViewHeaderStyle(
                backgroundColor: colorScheme.secondaryContainer,
                dayTextStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
                dateTextStyle: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              todayHighlightColor: colorScheme.tertiary,
              selectionDecoration: BoxDecoration(
                color: colorScheme.tertiary.withAlpha((255 * 0.3).round()),
                border: Border.all(color: colorScheme.tertiary, width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                shape: BoxShape.rectangle,
              ),
              appointmentTextStyle: TextStyle(
                fontSize: 12,
                color: colorScheme.onPrimary,
              ),
              monthViewSettings: const MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                showAgenda: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}