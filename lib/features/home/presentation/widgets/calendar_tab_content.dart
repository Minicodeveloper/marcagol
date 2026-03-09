import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';

class CalendarTabContent extends ConsumerStatefulWidget {
  const CalendarTabContent({super.key});

  @override
  ConsumerState<CalendarTabContent> createState() => _CalendarTabContentState();
}

class _CalendarTabContentState extends ConsumerState<CalendarTabContent> {
  @override
  Widget build(BuildContext context) {
    final historicChampionships = ref.watch(historicChampionshipsProvider);
    final activeChampionship = ref.watch(activeChampionshipProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.history, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Historial de Campeonatos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Revisa los resultados de campeonatos anteriores',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Active championship
          activeChampionship.when(
            data: (champ) {
              if (champ == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '🟢 Campeonato Actual',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.liveGreen,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildChampionshipCard(champ, isActive: true),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Historic championships
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '📋 Campeonatos Anteriores',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          historicChampionships.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 60, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        const Text(
                          'No hay campeonatos finalizados aún',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: list.map((champ) => _buildChampionshipCard(champ)).toList(),
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildChampionshipCard(Map<String, dynamic> champ, {bool isActive = false}) {
    return GestureDetector(
      onTap: () => _showChampionshipMatches(champ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: AppColors.liveGreen, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.liveGreen.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.emoji_events,
                color: isActive ? AppColors.liveGreen : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    champ['name'] ?? 'Sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (champ['description'] != null)
                    Text(
                      champ['description'],
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.liveGreen.withValues(alpha: 0.1)
                          : AppColors.textTertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isActive ? 'En curso' : 'Finalizado',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.liveGreen : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showChampionshipMatches(Map<String, dynamic> champ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ChampionshipDetailScreen(
          championshipId: champ['id'],
          championshipName: champ['name'] ?? '',
        ),
      ),
    );
  }
}

/// Pantalla de detalle de un campeonato (historial)
class _ChampionshipDetailScreen extends ConsumerWidget {
  final String championshipId;
  final String championshipName;

  const _ChampionshipDetailScreen({
    required this.championshipId,
    required this.championshipName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesByChampionshipProvider(championshipId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(championshipName),
      ),
      body: matches.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No hay partidos registrados', style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final match = list[index];
              final homeScore = match['homeScore'];
              final awayScore = match['awayScore'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
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
                          '${match['matchNumber'] ?? (index + 1)}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        match['homeTeam'] ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: homeScore != null ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        homeScore != null ? '$homeScore - $awayScore' : 'VS',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        match['awayTeam'] ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}