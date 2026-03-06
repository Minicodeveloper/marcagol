import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../calendar/presentation/widgets/calendar_grid.dart';
import '../../../calendar/presentation/widgets/upcoming_event_card.dart';

class CalendarTabContent extends StatefulWidget {
  const CalendarTabContent({super.key});

  @override
  State<CalendarTabContent> createState() => _CalendarTabContentState();
}

class _CalendarTabContentState extends State<CalendarTabContent> {
  DateTime _currentMonth = DateTime(2026, 12); // Diciembre 2026
  int _selectedDay = 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con mes/año y navegación
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Column(
                children: [
                  Text(
                    _getMonthName(_currentMonth.month).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${_currentMonth.year}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
        ),

        // Calendario
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CalendarGrid(
            currentMonth: _currentMonth,
            selectedDay: _selectedDay,
            onDaySelected: (day) {
              setState(() {
                _selectedDay = day;
              });
            },
          ),
        ),

        // Eventos Próximos
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Eventos Próximos',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                const UpcomingEventCard(
                  title: 'UEFA Champions League',
                  time: 'Hoy, 9:00 am',
                  timeUntil: 'en 2 minutos',
                ),
                const UpcomingEventCard(
                  title: 'Encuentros',
                  time: 'Ju, 2:30 am',
                  timeUntil: 'en 4 horas',
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month];
  }
}