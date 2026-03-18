import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../streams/presentation/screens/youtube_player_screen.dart';
import '../../../radio/presentation/screens/radio_screen.dart';

class LiveTabContent extends ConsumerStatefulWidget {
  const LiveTabContent({super.key});

  @override
  ConsumerState<LiveTabContent> createState() => _LiveTabContentState();
}

class _LiveTabContentState extends ConsumerState<LiveTabContent> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Rebuild every minute to update the local timers of the matches
    _ticker = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeChampionship = ref.watch(activeChampionshipProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Encuentros en Vivo',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Active championship matches
          activeChampionship.when(
            data: (champ) {
              if (champ == null) {
                return _buildEmptyState('No hay campeonatos activos', Icons.sports_soccer);
              }
              return _buildChampionshipMatches(champ['id'], champ['name'] ?? '');
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildEmptyState('Error al cargar partidos', Icons.error_outline),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildChampionshipMatches(String championshipId, String name) {
    final matches = ref.watch(matchesByChampionshipProvider(championshipId));
    return matches.when(
      data: (list) {
        final liveMatches = list.where((m) => m['status'] == 'live').toList();
        
        if (liveMatches.isEmpty) return _buildEmptyState('No hay partidos transmitiéndose en este momento', Icons.schedule);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: liveMatches.map((match) => _buildMatchCard(context, match)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match) {
    final homeScore = match['homeScore'];
    final awayScore = match['awayScore'];
    
    // Timer details
    final timerState = match['timerState'] ?? {};
    final timerStatus = timerState['status'] ?? 'scheduled';
    final timerPeriod = timerState['period'] ?? '1H';
    
    int currentMinutes = timerState['accumulatedMinutes'] ?? 0;
    if (timerStatus == 'playing' && timerState['periodStartTime'] != null) {
      final Timestamp startTime = timerState['periodStartTime'];
      final diffSeconds = DateTime.now().difference(startTime.toDate()).inSeconds;
      currentMinutes += (diffSeconds ~/ 60);
    }
    
    final formattedTime = timerStatus == 'playing' ? "$currentMinutes'" : _getPeriodLabel(timerPeriod);
    
    // Streams
    final streams = List<Map<String, dynamic>>.from(match['streams'] ?? []);
    final hasVideo = streams.any((s) => s['type'] == 'video');
    final hasRadio = streams.any((s) => s['type'] == 'radio');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.liveGreen.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.liveGreen.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Timer and Live Badge)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formattedTime,
                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 4),
                    Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Scoreboard
          Row(
            children: [
              _buildTeamLogo(match['homeTeam'] ?? ''),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  match['homeTeam'] ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.liveGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      homeScore != null ? '$homeScore - $awayScore' : 'VS',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.liveGreen,
                      ),
                    ),
                    if (match['penaltiesScore'] != null && (match['penaltiesScore']['home'] > 0 || match['penaltiesScore']['away'] > 0 || timerPeriod == 'PEN'))
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '(${match['penaltiesScore']['home']} - ${match['penaltiesScore']['away']})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  match['awayTeam'] ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 12),
              _buildTeamLogo(match['awayTeam'] ?? ''),
            ],
          ),
          
          if (streams.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasVideo)
                  Expanded(
                    child: _buildStreamButton(
                      context, 
                      Icons.videocam, 
                      'Ver Video', 
                      AppColors.primary, 
                      streams.firstWhere((s) => s['type'] == 'video'),
                    ),
                  ),
                if (hasVideo && hasRadio) const SizedBox(width: 12),
                if (hasRadio)
                  Expanded(
                    child: _buildStreamButton(
                      context, 
                      Icons.radio, 
                      'Escuchar Radio', 
                      AppColors.adminOrange, 
                      streams.firstWhere((s) => s['type'] == 'radio'),
                    ),
                  ),
              ],
            ),
          ]
        ],
      ),
    );
  }
  
  String _getPeriodLabel(String? period) {
    switch (period) {
      case '1H': return '1er Tiempo';
      case 'HT': return 'Descanso';
      case '2H': return '2do Tiempo';
      case 'E1': return '1er T. Extra';
      case 'E2': return '2do T. Extra';
      case 'PEN': return 'Penales';
      case 'FT': return 'Finalizado';
      default: return 'Programado';
    }
  }

  Widget _buildStreamButton(BuildContext context, IconData icon, String label, Color color, Map<String, dynamic> stream) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      onPressed: () {
        if (stream['type'] == 'video') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => YoutubePlayerScreen(
                  youtubeUrl: stream['url'] ?? '',
                  title: stream['title'] ?? 'Transmisión en Vivo',
                ),
              ),
            );
        } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RadioScreen(
                  streamUrl: stream['url'] ?? '',
                  title: stream['title'] ?? 'Radio en Vivo',
                ),
              ),
            );
        }
      },
    );
  }

  Widget _buildTeamLogo(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 80, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}