import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime currentMonth;
  final int selectedDay;
  final Function(int) onDaySelected;

  const CalendarGrid({
    super.key,
    required this.currentMonth,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;

    final firstDayOfMonth = DateTime(
      currentMonth.year,
      currentMonth.month,
      1,
    );

    final startingWeekday = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        // Headers de días
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDayHeader('Dom'),
            _buildDayHeader('Lu'),
            _buildDayHeader('Ma'),
            _buildDayHeader('Mi'),
            _buildDayHeader('Ju'),
            _buildDayHeader('Vi'),
            _buildDayHeader('Sa'),
          ],
        ),
        const SizedBox(height: 8),

        // Grid de días
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: daysInMonth + startingWeekday,
          itemBuilder: (context, index) {
            if (index < startingWeekday) {
              return const SizedBox.shrink();
            }

            final day = index - startingWeekday + 1;
            final isSelected = day == selectedDay;

            return GestureDetector(
              onTap: () => onDaySelected(day),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayHeader(String day) {
    return SizedBox(
      width: 40,
      child: Center(
        child: Text(
          day,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}