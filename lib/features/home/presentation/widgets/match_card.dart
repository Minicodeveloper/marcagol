import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'odd_button.dart';
import 'odd_chip.dart';

class MatchCard extends StatelessWidget {
  final String league;
  final String team1;
  final String team2;
  final String odd1;
  final String oddDraw;
  final String odd2;
  final String time;
  final bool isLive;
  final String? score;

  const MatchCard({
    super.key,
    required this.league,
    required this.team1,
    required this.team2,
    required this.odd1,
    required this.oddDraw,
    required this.odd2,
    required this.time,
    this.isLive = false,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isLive
            ? Border.all(color: AppColors.liveRed, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                league,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'EN VIVO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (score != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    score!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Column(
                children: [
                  OddButton(odd: odd1, label: '1'),
                  const SizedBox(height: 8),
                  OddButton(odd: odd2, label: '2'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OddChip(label: '1', odd: odd1),
              OddChip(label: 'X', odd: oddDraw),
              OddChip(label: '2', odd: odd2),
            ],
          ),
        ],
      ),
    );
  }
}