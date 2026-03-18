import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../streams/presentation/screens/youtube_player_screen.dart';
import '../../../streams/presentation/screens/web_stream_player_screen.dart';
import '../../../radio/presentation/screens/radio_screen.dart';
import '../../../betting/presentation/screens/place_bet_screen.dart';

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
    final globalVideoStreams = ref.watch(liveVideoStreamsProvider);
    final globalRadioStreams = ref.watch(liveRadioStreamsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 0: BETTING - Available bets
          _buildBettingSection(),

          // Section 1: LIVE MATCHES
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.sports_soccer, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Partidos en Vivo',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          activeChampionship.when(
            data: (champ) {
              if (champ == null) return _buildEmptyState('No hay campeonatos activos', Icons.schedule);
              return _buildChampionshipMatches(champ['id']);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildEmptyState('Error al cargar partidos', Icons.error_outline),
          ),

          // Section 2: GLOBAL VIDEO STREAMS (Recommended Lives)
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.live_tv, color: AppColors.liveRed),
                const SizedBox(width: 8),
                Text(
                  'Transmisiones de Video',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          globalVideoStreams.when(
            data: (streams) {
              if (streams.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No hay transmisiones de video activas', style: TextStyle(color: AppColors.textTertiary)),
                  ),
                );
              }
              return SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: streams.length,
                  itemBuilder: (context, index) => _buildGlobalStreamCard(context, streams[index]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Section 3: GLOBAL RADIO STREAMS
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.radio, color: AppColors.adminOrange),
                const SizedBox(width: 8),
                Text(
                  'Transmisiones de Radio',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          globalRadioStreams.when(
            data: (streams) {
              if (streams.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No hay transmisiones de radio activas', style: TextStyle(color: AppColors.textTertiary)),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: streams.map((stream) => _buildRadioStreamCard(context, stream)).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Section: Apuestas Disponibles
  Widget _buildBettingSection() {
    final activeChampionship = ref.watch(activeChampionshipProvider);

    return activeChampionship.when(
      data: (champ) {
        if (champ == null) return const SizedBox.shrink();
        final matches = ref.watch(matchesByChampionshipProvider(champ['id']));
        return matches.when(
          data: (list) {
            final bettingMatches = list.where((m) =>
                m['bettingEnabled'] == true &&
                m['status'] != 'finished'
            ).toList();

            if (bettingMatches.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.casino, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Apuestas Disponibles',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${bettingMatches.length}',
                          style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ...bettingMatches.map((match) => _buildBettingCard(match, champ['id'])),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBettingCard(Map<String, dynamic> match, String championshipId) {
    final odds = Map<String, dynamic>.from(match['bettingOdds'] ?? {});
    final homeTeam = match['homeTeam'] ?? 'Local';
    final awayTeam = match['awayTeam'] ?? 'Visita';
    final status = match['status'] ?? 'scheduled';
    final customOptions = List<Map<String, dynamic>>.from(odds['customOptions'] ?? []);

    String statusLabel;
    Color statusColor;
    switch (status) {
      case 'live':
        statusLabel = '🔴 EN VIVO';
        statusColor = AppColors.liveRed;
        break;
      case 'scheduled':
        statusLabel = '📅 Programado';
        statusColor = Colors.blue;
        break;
      default:
        statusLabel = status.toUpperCase();
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withValues(alpha: 0.05),
            Colors.purple.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.casino, size: 16, color: Colors.deepPurple),
                const SizedBox(width: 4),
                const Text('Apuesta', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              ],
            ),
            const SizedBox(height: 12),

            // Teams
            Row(
              children: [
                _buildTeamLogo(homeTeam),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(homeTeam, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple)),
                ),
                Expanded(
                  child: Text(awayTeam, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                ),
                const SizedBox(width: 10),
                _buildTeamLogo(awayTeam),
              ],
            ),
            const SizedBox(height: 14),

            // Odds chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (odds['homeWin'] != null)
                  _buildOddsChip('1', 'x${(odds['homeWin'] as num).toStringAsFixed(2)}', AppColors.primary),
                if (odds['draw'] != null)
                  _buildOddsChip('X', 'x${(odds['draw'] as num).toStringAsFixed(2)}', Colors.orange),
                if (odds['awayWin'] != null)
                  _buildOddsChip('2', 'x${(odds['awayWin'] as num).toStringAsFixed(2)}', Colors.blue),
                ...customOptions.map((opt) =>
                  _buildOddsChip('★', 'x${(opt['odds'] as num?)?.toStringAsFixed(2) ?? '?'}', Colors.deepPurple),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Apostar button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaceBetScreen(
                        championshipId: championshipId,
                        matchData: match,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.casino, size: 18),
                label: const Text('APOSTAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOddsChip(String label, String odds, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          const SizedBox(width: 6),
          Text(odds, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        ],
      ),
    );
  }

  Widget _buildRadioStreamCard(BuildContext context, Map<String, dynamic> stream) {
    final matchId = stream['matchId'];
    final frequency = stream['frequency'];
    
    return GestureDetector(
      onTap: () => _openStream(context, stream, isGlobal: true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.adminOrange.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6D00), Color(0xFFFF9100)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.radio, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream['title'] ?? 'Radio',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (frequency != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.adminOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${frequency} MHz',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.adminOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (matchId != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sports_soccer, size: 12, color: AppColors.liveGreen),
                            const SizedBox(width: 4),
                            const Text(
                              'Partido vinculado',
                              style: TextStyle(color: AppColors.liveGreen, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      if (stream['description'] != null && matchId == null)
                        Expanded(
                          child: Text(
                            stream['description'],
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Live badge + play icon
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.play_circle_fill, color: AppColors.adminOrange, size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStreamCard(BuildContext context, Map<String, dynamic> stream) {
    final matchId = stream['matchId'];
    
    return GestureDetector(
      onTap: () => _openStream(context, stream, isGlobal: true),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Bottom info
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stream['title'] ?? 'Directo',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      if (matchId != null)
                        _buildLinkedMatchInfo(matchId),
                    ],
                  ),
                ),
              ),
              
              // LIVE Badge
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedMatchInfo(String matchId) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.sports_soccer, color: AppColors.liveGreen, size: 12),
          SizedBox(width: 4),
          Text(
            'Partido vinculado',
            style: TextStyle(color: AppColors.liveGreen, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionshipMatches(String championshipId) {
    final matches = ref.watch(matchesByChampionshipProvider(championshipId));
    return matches.when(
      data: (list) {
        final liveMatches = list.where((m) => m['status'] == 'live').toList();
        
        if (liveMatches.isEmpty) return _buildEmptyState('No hay partidos transmitiéndose en este momento', Icons.schedule);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: liveMatches.map((match) => _buildMatchCard(context, match, championshipId)).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match, String championshipId) {
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
    
    // Streams (video + radio)
    final streams = List<Map<String, dynamic>>.from(match['streams'] ?? []);
    final hasVideo = streams.any((s) => s['type'] == 'video');
    final hasRadio = streams.any((s) => s['type'] == 'radio');
    
    // Goals data
    final goals = List<Map<String, dynamic>>.from(match['goals'] ?? []);
    final homeGoals = goals.where((g) => g['team'] == 'home').toList();
    final awayGoals = goals.where((g) => g['team'] == 'away').toList();

    return GestureDetector(
      onTap: () {
        if (streams.isNotEmpty) {
          _showStreamOptions(context, streams);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay transmisiones disponibles para este partido')),
          );
        }
      },
      child: Container(
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
                    color: timerStatus == 'playing'
                        ? AppColors.liveGreen.withValues(alpha: 0.1)
                        : timerPeriod == 'HT'
                            ? Colors.orange.withValues(alpha: 0.1)
                            : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formattedTime,
                    style: TextStyle(
                      color: timerStatus == 'playing'
                          ? AppColors.liveGreen
                          : timerPeriod == 'HT'
                              ? Colors.orange
                              : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                // Stream type indicators
                Row(
                  children: [
                    if (hasVideo)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam, size: 12, color: AppColors.primary),
                            SizedBox(width: 2),
                            Text('Video', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    if (hasRadio)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.adminOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radio, size: 12, color: AppColors.adminOrange),
                            SizedBox(width: 2),
                            Text('Radio', style: TextStyle(color: AppColors.adminOrange, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
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
            
            // Goal scorers
            if (goals.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Home goals
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: homeGoals.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            "⚽ ${g['scorer'] ?? ''} ${g['minute']}'",
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                      ),
                    ),
                    // Away goals
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: awayGoals.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            "${g['minute']}' ${g['scorer'] ?? ''} ⚽",
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            // Betting button + stream info
            Row(
              children: [
                if (match['bettingEnabled'] == true)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceBetScreen(
                              championshipId: championshipId,
                              matchData: match,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.casino, size: 14),
                      label: const Text('Apostar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    streams.isNotEmpty 
                        ? 'Toca para ver la transmisión (${streams.length} disponible${streams.length > 1 ? 's' : ''})'
                        : 'No hay transmisiones asociadas',
                    style: TextStyle(
                      color: streams.isNotEmpty ? AppColors.textTertiary : AppColors.liveRed.withValues(alpha: 0.6),
                      fontSize: 11, 
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStreamOptions(BuildContext context, List<Map<String, dynamic>> streams) {
    final videoStreams = streams.where((s) => s['type'] == 'video').toList();
    final radioStreams = streams.where((s) => s['type'] == 'radio').toList();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccionar Transmisión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (videoStreams.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  '📺 Video (${videoStreams.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ),
              ...videoStreams.map((s) => ListTile(
                leading: const Icon(Icons.videocam, color: AppColors.primary),
                title: Text(s['title'] ?? 'Ver Video'),
                subtitle: Text(
                  s['url'] ?? '',
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                onTap: () {
                  Navigator.pop(ctx);
                  _openStream(context, s);
                },
              )),
            ],
            if (radioStreams.isNotEmpty) ...[
              if (videoStreams.isNotEmpty) const Divider(),
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  '📻 Radio (${radioStreams.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ),
              ...radioStreams.map((s) => ListTile(
                leading: const Icon(Icons.radio, color: AppColors.adminOrange),
                title: Text(s['title'] ?? 'Escuchar Radio'),
                subtitle: Text(
                  s['url'] ?? '',
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.play_circle_outline, color: AppColors.adminOrange),
                onTap: () {
                  Navigator.pop(ctx);
                  _openStream(context, s);
                },
              )),
            ],
          ],
        ),
      ),
    );
  }
  
  void _openStream(BuildContext context, Map<String, dynamic> stream, {bool isGlobal = false}) {
    final url = isGlobal ? (stream['youtubeUrl'] ?? stream['streamUrl'] ?? '') : (stream['url'] ?? '');
    final title = stream['title'] ?? 'Transmisión en Vivo';

    if (stream['type'] == 'video') {
      final isYoutube = url.contains('youtube.com') || url.contains('youtu.be');
      final isFacebook = url.contains('facebook.com') || url.contains('fb.watch') || url.contains('fb.gg');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => (isYoutube && !isFacebook)
              ? YoutubePlayerScreen(youtubeUrl: url, title: title)
              : WebStreamPlayerScreen(url: url, title: title),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RadioScreen(
            streamUrl: url,
            title: title,
            frequency: stream['frequency']?.toDouble(),
          ),
        ),
      );
    }
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