// lib/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendário de Agendamentos')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SfCalendar(
          view: CalendarView.month,
          dataSource: _getCalendarDataSource(),
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
            color: Colors.transparent,
            border: Border.all(color: colorScheme.tertiary, width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            shape: BoxShape.rectangle,
          ),
          appointmentTextStyle: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimary,
          ),
          monthViewSettings: MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
            showAgenda: true,
            agendaStyle: AgendaStyle(
              backgroundColor: colorScheme.surface,
              appointmentTextStyle: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
              dateTextStyle: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
              dayTextStyle: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            monthCellStyle: MonthCellStyle(
              textStyle: TextStyle(color: colorScheme.onSurface),

              leadingDatesTextStyle: TextStyle(
                color: colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              ),
              trailingDatesTextStyle: TextStyle(
                color: colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _AppointmentDataSource _getCalendarDataSource() {
    final List<Appointment> appointments = <Appointment>[];

    // ADICIONE SEUS EVENTOS REAIS AQUI
    appointments.add(
      Appointment(
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        subject: 'Consulta Inicial',
        color: Colors.blue, // Pode ser ajustado para usar cores do tema
      ),
    );

    return _AppointmentDataSource(appointments);
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
