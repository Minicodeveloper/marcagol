import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../teams/presentation/widgets/featured_match_card.dart';
import '../../../teams/presentation/widgets/league_match_card.dart';
import '../../../teams/presentation/widgets/scheduled_event_card.dart';

class TeamsTabContent extends StatelessWidget {
  const TeamsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Card destacado grande
          const FeaturedMatchCard(
            imageUrl: null,
            homeTeam: 'Equipo Local',
            awayTeam: 'Equipo Visitante',
            homeScore: 1,
            awayScore: 3,
          ),

          const SizedBox(height: 24),

          // UEFA Champions League
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'UEFA Champions League',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const LeagueMatchCard(
            homeTeam: 'I.E.I Nuestro Jesús Sahara de Guadalupe',
            awayTeam: 'Institución Educativa Ntra. Señora',
            homeScore: 0,
            awayScore: 1,
            location: 'Estadio Municipal', // ← CAMBIADO: Ahora es ubicación
            isLive: true,
          ),

          const SizedBox(height: 24),

          // Eventos Programados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Eventos Programados',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Botón CREAR NUEVO (verde)
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navegar a crear evento
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.liveGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CREAR NUEVO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Encuentros',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const ScheduledEventCard(
            homeTeam: 'I.E.I Nuestro Jesús Sahara de Guadalupe',
            awayTeam: 'Otro Equipo',
            time: '07:30',
            address: 'Jr. Conde de Superunda 508',
            date: 'Sábado 9',
          ),

          const SizedBox(height: 12),

          // Botón "ver todo >"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () {
                // TODO: Ver todos los eventos
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'ver todo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}