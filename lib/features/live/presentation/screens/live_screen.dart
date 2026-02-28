import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/live_match_card.dart';
import 'live_match_detail_screen.dart';

/// Pantalla de partidos en vivo
/// TODO: Conectar con Firestore para obtener partidos en tiempo real
class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('En Vivo'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TODO: Reemplazar con StreamBuilder para datos en tiempo real
          LiveMatchCard(
            league: 'Copa Regional',
            team1: 'Deportivo Municipal',
            team2: 'Sport Huancayo',
            score1: '1',
            score2: '0',
            time: '67\'',
            hasStream: true,
            onTap: () => _navigateToDetail(context, 'Copa Regional', 'Deportivo Municipal', 'Sport Huancayo', '1', '0', '67\''),
          ),
          LiveMatchCard(
            league: 'Liga Regional',
            team1: 'Carlos Stein',
            team2: 'Comerciantes Unidos',
            score1: '2',
            score2: '2',
            time: '82\'',
            hasStream: true,
            onTap: () => _navigateToDetail(context, 'Liga Regional', 'Carlos Stein', 'Comerciantes Unidos', '2', '2', '82\''),
          ),
          LiveMatchCard(
            league: 'Copa Perú',
            team1: 'Atlético Grau',
            team2: 'Sport Boys',
            score1: '0',
            score2: '1',
            time: '45+2\'',
            hasStream: false,
            onTap: () => _navigateToDetail(context, 'Copa Perú', 'Atlético Grau', 'Sport Boys', '0', '1', '45+2\''),
          ),
          LiveMatchCard(
            league: 'Torneo Local',
            team1: 'Unión Comercio',
            team2: 'Santos FC',
            score1: '1',
            score2: '1',
            time: 'HT',
            hasStream: true,
            onTap: () => _navigateToDetail(context, 'Torneo Local', 'Unión Comercio', 'Santos FC', '1', '1', 'HT'),
          ),
          LiveMatchCard(
            league: 'Liga 2',
            team1: 'Deportivo Coopsol',
            team2: 'Los Chankas',
            score1: '3',
            score2: '1',
            time: '88\'',
            hasStream: true,
            onTap: () => _navigateToDetail(context, 'Liga 2', 'Deportivo Coopsol', 'Los Chankas', '3', '1', '88\''),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String league, String team1, String team2, String score1, String score2, String time) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveMatchDetailScreen(
          league: league,
          team1: team1,
          team2: team2,
          score1: score1,
          score2: score2,
          time: time,
        ),
      ),
    );
  }
}