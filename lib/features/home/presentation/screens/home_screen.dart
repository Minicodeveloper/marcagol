import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../widgets/sport_category.dart';
import '../widgets/match_card.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categorías de deportes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SportCategory(icon: Icons.sports_soccer, label: 'Fútbol'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Partidos destacados
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeader(title: AppStrings.featuredMatches),
            ),

            const SizedBox(height: 16),

            // Lista de partidos
            const MatchCard(
              league: 'Liga 1 - Perú',
              team1: 'Deportivo Llacuabamba',
              team2: 'Cultural Santa Rosa',
              odd1: '2.40',
              oddDraw: '3.20',
              odd2: '2.80',
              time: 'HOY 19:00',
              isLive: false,
            ),
            const MatchCard(
              league: 'Copa Libertadores',
              team1: 'Juan Aurich',
              team2: 'Unión Comercio',
              odd1: '3.50',
              oddDraw: '3.10',
              odd2: '2.10',
              time: 'EN VIVO',
              isLive: true,
              score: '1-0',
            ),
            const MatchCard(
              league: 'Premier League',
              team1: 'Carlos Mannucci',
              team2: 'Atlético Grau',
              odd1: '1.95',
              oddDraw: '3.60',
              odd2: '3.40',
              time: 'MAÑANA 15:00',
              isLive: false,
            ),
            const MatchCard(
              league: 'La Liga',
              team1: 'Academia Cantolao',
              team2: 'José Gálvez',
              odd1: '2.20',
              oddDraw: '3.30',
              odd2: '3.00',
              time: 'DOM 20:00',
              isLive: false,
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}