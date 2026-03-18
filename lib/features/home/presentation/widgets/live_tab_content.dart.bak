import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String _selectedButton = 'Transmisión';

  @override
  Widget build(BuildContext context) {
    final videoStreams = ref.watch(liveVideoStreamsProvider);
    final radioStreams = ref.watch(liveRadioStreamsProvider);
    final activeChampionship = ref.watch(activeChampionshipProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Buttons: Transmisión y Radio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickButton(
                  context,
                  Icons.live_tv,
                  'Transmisión',
                  _selectedButton == 'Transmisión',
                  () => setState(() => _selectedButton = 'Transmisión'),
                ),
                const SizedBox(width: 16),
                _buildQuickButton(
                  context,
                  Icons.radio,
                  'Radio',
                  _selectedButton == 'Radio',
                  () => setState(() => _selectedButton = 'Radio'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (_selectedButton == 'Transmisión') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Transmisiones en Vivo',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            videoStreams.when(
              data: (streams) {
                if (streams.isEmpty) {
                  return _buildEmptyState('No hay transmisiones de video activas', Icons.videocam_off);
                }
                return Column(
                  children: streams.map((stream) => _buildVideoStreamCard(context, stream)).toList(),
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.accent),
              )),
              error: (e, _) => _buildEmptyState('No hay transmisiones disponibles', Icons.videocam_off),
            ),
          ],

          if (_selectedButton == 'Radio') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Emisoras de Radio',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            radioStreams.when(
              data: (streams) {
                if (streams.isEmpty) {
                  return _buildEmptyState('No hay emisoras activas', Icons.radio);
                }
                return Column(
                  children: streams.map((stream) => _buildRadioStreamCard(context, stream)).toList(),
                );
              },
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.accent),
              )),
              error: (e, _) => _buildEmptyState('No hay emisoras disponibles', Icons.radio),
            ),
          ],

          const SizedBox(height: 24),

          // Active championship matches
          activeChampionship.when(
            data: (champ) {
              if (champ == null) return const SizedBox.shrink();
              return _buildChampionshipMatches(champ['id'], champ['name'] ?? '');
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildVideoStreamCard(BuildContext context, Map<String, dynamic> stream) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YoutubePlayerScreen(
              youtubeUrl: stream['youtubeUrl'] ?? '',
              title: stream['title'] ?? 'Transmisión',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.darkGradient,
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_fill, size: 60, color: Colors.white54),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 6),
                      Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream['title'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (stream['description'] != null)
                      Text(
                        stream['description'],
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioStreamCard(BuildContext context, Map<String, dynamic> stream) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RadioScreen(
              streamUrl: stream['streamUrl'],
              title: stream['title'],
              frequency: (stream['frequency'] as num?)?.toDouble(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.radio, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream['title'] ?? 'Radio',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (stream['description'] != null)
                    Text(
                      stream['description'],
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  if (stream['frequency'] != null)
                    Text(
                      '${stream['frequency']} MHz',
                      style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            const Icon(Icons.play_circle, color: AppColors.accent, size: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildChampionshipMatches(String championshipId, String name) {
    final matches = ref.watch(matchesByChampionshipProvider(championshipId));
    return matches.when(
      data: (list) {
        final liveMatches = list.where((m) => m['status'] == 'live' || m['status'] == 'finished').toList();
        if (liveMatches.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ...liveMatches.map((match) => _buildMatchCard(match)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final isLive = match['status'] == 'live';
    final homeScore = match['homeScore'];
    final awayScore = match['awayScore'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isLive ? Border.all(color: AppColors.liveGreen, width: 1) : null,
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
          _buildTeamLogo(match['homeTeam'] ?? ''),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              match['homeTeam'] ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLive
                  ? AppColors.liveGreen.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              homeScore != null ? '$homeScore - $awayScore' : 'VS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isLive ? AppColors.liveGreen : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              match['awayTeam'] ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          _buildTeamLogo(match['awayTeam'] ?? ''),
          if (isLive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.liveGreen,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('VIVO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String name) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent),
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
            Icon(icon, size: 60, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.orangeGradient : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? AppColors.accent.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}