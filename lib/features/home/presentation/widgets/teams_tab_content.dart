import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';

class TeamsTabContent extends ConsumerWidget {
  const TeamsTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChampionship = ref.watch(activeChampionshipProvider);

    return activeChampionship.when(
      data: (champ) {
        if (champ == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer_outlined, size: 80, color: AppColors.textTertiary),
                SizedBox(height: 16),
                Text('No hay campeonato activo', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                SizedBox(height: 8),
                Text('El administrador debe activar un campeonato',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              ],
            ),
          );
        }

        return _ChampionshipMatchesView(
          championshipId: champ['id'],
          championshipName: champ['name'] ?? '',
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ChampionshipMatchesView extends ConsumerWidget {
  final String championshipId;
  final String championshipName;

  const _ChampionshipMatchesView({
    required this.championshipId,
    required this.championshipName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesByChampionshipProvider(championshipId));

    return matches.when(
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer_outlined, size: 80, color: AppColors.textTertiary),
                SizedBox(height: 16),
                Text('No hay partidos registrados', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final scheduled = list.where((m) => m['status'] == 'scheduled').toList();
        final live = list.where((m) => m['status'] == 'live').toList();
        final finished = list.where((m) => m['status'] == 'finished').toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Championship name header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        championshipName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${list.length} partidos',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              // Live matches
              if (live.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionHeader(context, '🔴 En Vivo', AppColors.liveGreen),
                ...live.map((m) => _buildMatchCard(m, true)),
              ],

              // Scheduled matches
              if (scheduled.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionHeader(context, '⏰ Programados', Colors.blue),
                ...scheduled.map((m) => _buildMatchCard(m, false)),
              ],

              // Finished matches
              if (finished.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionHeader(context, '✅ Finalizados', AppColors.textSecondary),
                ...finished.map((m) => _buildMatchCard(m, false)),
              ],

              const SizedBox(height: 100),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, bool isLive) {
    final homeScore = match['homeScore'];
    final awayScore = match['awayScore'];
    final status = match['status'] ?? 'scheduled';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isLive ? Border.all(color: AppColors.liveGreen, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Match number & league
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${match['matchNumber'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                match['league'] ?? '',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.liveGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              if (status == 'finished')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('FIN', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Teams and score
          Row(
            children: [
              _buildTeamLogo(match['homeTeam'] ?? ''),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      match['homeTeam'] ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: homeScore != null ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  homeScore != null ? '$homeScore - $awayScore' : 'VS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: homeScore != null ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      match['awayTeam'] ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildTeamLogo(match['awayTeam'] ?? ''),
            ],
          ),
          
          if (match['location'] != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  match['location'],
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
    );
  }
}