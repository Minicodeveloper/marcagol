import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';

class AdminMatchControlScreen extends ConsumerStatefulWidget {
  final String championshipId;
  final Map<String, dynamic> matchData;

  const AdminMatchControlScreen({
    super.key,
    required this.championshipId,
    required this.matchData,
  });

  @override
  ConsumerState<AdminMatchControlScreen> createState() => _AdminMatchControlScreenState();
}

class _AdminMatchControlScreenState extends ConsumerState<AdminMatchControlScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Map<String, dynamic> matchData;
  Timer? _timer;
  int _currentTimerSeconds = 0;

  @override
  void initState() {
    super.initState();
    matchData = widget.matchData;
    _setupTimerUpdates();
    
    // Listen to real-time updates for this match
    FirebaseFirestore.instance
        .collection('championships')
        .doc(widget.championshipId)
        .collection('matches')
        .doc(widget.matchData['id'])
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          matchData = {'id': snapshot.id, ...snapshot.data()!};
        });
        _calculateCurrentSeconds();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setupTimerUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final timerState = matchData['timerState'] ?? {};
      if (timerState['status'] == 'playing') {
        setState(() {
          _calculateCurrentSeconds();
        });
      }
    });
  }

  void _calculateCurrentSeconds() {
    final timerState = matchData['timerState'] ?? {};
    int baseSeconds = (timerState['accumulatedMinutes'] ?? 0) * 60;
    
    if (timerState['status'] == 'playing' && timerState['periodStartTime'] != null) {
      final Timestamp startTime = timerState['periodStartTime'];
      final diff = DateTime.now().difference(startTime.toDate()).inSeconds;
      baseSeconds += diff;
    }
    _currentTimerSeconds = baseSeconds;
  }

  int get _currentMinutes => _currentTimerSeconds ~/ 60;

  String get _formattedTime {
    final minutes = _currentTimerSeconds ~/ 60;
    final seconds = _currentTimerSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getPeriodLabel(String? period) {
    switch (period) {
      case '1H': return '1er Tiempo';
      case 'HT': return 'Descanso';
      case '2H': return '2do Tiempo';
      case 'E1': return '1er Tmp. Extra';
      case 'E2': return '2do Tmp. Extra';
      case 'PEN': return 'Penales';
      case 'FT': return 'Finalizado';
      default: return 'Programado';
    }
  }

  Future<void> _updateTimerState({
    required String status,
    required String period,
    int additionalMinutes = 0,
    bool resetStartTime = false,
  }) async {
    final currentState = Map<String, dynamic>.from(matchData['timerState'] ?? {});
    
    int newAccumulated = currentState['accumulatedMinutes'] ?? 0;
    newAccumulated += additionalMinutes;
    
    await _firestoreService.updateMatchTimer(
      championshipId: widget.championshipId,
      matchId: widget.matchData['id'],
      timerState: {
        'status': status,
        'period': period,
        'accumulatedMinutes': newAccumulated,
        'periodStartTime': resetStartTime ? FieldValue.serverTimestamp() : currentState['periodStartTime'],
      },
    );
  }

  Future<void> _updatePenalties(bool isHome, int change) async {
    final penScore = matchData['penaltiesScore'] ?? {'home': 0, 'away': 0};
    int currentHome = penScore['home'] ?? 0;
    int currentAway = penScore['away'] ?? 0;

    if (isHome) {
      currentHome = (currentHome + change).clamp(0, 99);
    } else {
      currentAway = (currentAway + change).clamp(0, 99);
    }

    await _firestoreService.updateMatchPenalties(
      championshipId: widget.championshipId,
      matchId: widget.matchData['id'],
      homeScore: currentHome,
      awayScore: currentAway,
    );
  }

  // ============================================================
  // GOAL MANAGEMENT
  // ============================================================

  List<Map<String, dynamic>> get _goals {
    return List<Map<String, dynamic>>.from(matchData['goals'] ?? []);
  }

  Future<void> _addGoal(bool isHome) async {
    final scorerCtrl = TextEditingController();
    final minuteCtrl = TextEditingController(text: '$_currentMinutes');
    final timerPeriod = (matchData['timerState'] ?? {})['period'] ?? '1H';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.sports_soccer, color: AppColors.liveGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '⚽ Gol - ${isHome ? matchData['homeTeam'] : matchData['awayTeam']}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scorerCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del goleador',
                hintText: 'Ej: L. Messi',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: minuteCtrl,
              decoration: const InputDecoration(
                labelText: 'Minuto del gol',
                hintText: 'Ej: 45',
                prefixIcon: Icon(Icons.timer),
                suffixText: "'",
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (scorerCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa el nombre del goleador')),
                );
                return;
              }
              Navigator.pop(ctx, {
                'scorer': scorerCtrl.text.trim(),
                'minute': int.tryParse(minuteCtrl.text) ?? _currentMinutes,
                'team': isHome ? 'home' : 'away',
                'period': timerPeriod,
              });
            },
            icon: const Icon(Icons.sports_soccer),
            label: const Text('¡GOL!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.liveGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      // Add the goal to the goals list
      final goals = _goals;
      goals.add(result);
      
      // Update goals array
      await _firestoreService.updateMatchGoals(
        championshipId: widget.championshipId,
        matchId: widget.matchData['id'],
        goals: goals,
      );
      
      // Update score count
      int currentHome = matchData['homeScore'] ?? 0;
      int currentAway = matchData['awayScore'] ?? 0;
      if (isHome) {
        currentHome++;
      } else {
        currentAway++;
      }
      await _firestoreService.updateMatchResult(
        championshipId: widget.championshipId,
        matchId: widget.matchData['id'],
        homeScore: currentHome,
        awayScore: currentAway,
        status: matchData['status'] ?? 'live',
      );
    }
  }

  Future<void> _removeGoal(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar gol?'),
        content: const Text('El marcador se actualizará automáticamente'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final goals = _goals;
      final removedGoal = goals.removeAt(index);
      
      // Update goals array
      await _firestoreService.updateMatchGoals(
        championshipId: widget.championshipId,
        matchId: widget.matchData['id'],
        goals: goals,
      );
      
      // Update score count
      int currentHome = matchData['homeScore'] ?? 0;
      int currentAway = matchData['awayScore'] ?? 0;
      if (removedGoal['team'] == 'home') {
        currentHome = (currentHome - 1).clamp(0, 99);
      } else {
        currentAway = (currentAway - 1).clamp(0, 99);
      }
      await _firestoreService.updateMatchResult(
        championshipId: widget.championshipId,
        matchId: widget.matchData['id'],
        homeScore: currentHome,
        awayScore: currentAway,
        status: matchData['status'] ?? 'live',
      );
    }
  }

  Future<void> _addStream() async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String selectedType = 'video';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Agregar Transmisión'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'video', child: Text('Video (YouTube/Facebook/Twitch)')),
                    DropdownMenuItem(value: 'radio', child: Text('Radio (Audio/YouTube)')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: 'Tipo de Transmisión'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título (ej. Narración ESPN)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'URL (YouTube/Facebook Live/Twitch)'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
                  final currentStreams = List<Map<String, dynamic>>.from(matchData['streams'] ?? []);
                  currentStreams.add({
                    'title': titleCtrl.text,
                    'url': urlCtrl.text,
                    'type': selectedType,
                  });
                  await _firestoreService.updateMatchStreams(
                    championshipId: widget.championshipId,
                    matchId: widget.matchData['id'],
                    streams: currentStreams,
                  );
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _removeStream(int index) async {
    final currentStreams = List<Map<String, dynamic>>.from(matchData['streams'] ?? []);
    currentStreams.removeAt(index);
    await _firestoreService.updateMatchStreams(
      championshipId: widget.championshipId,
      matchId: widget.matchData['id'],
      streams: currentStreams,
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerState = matchData['timerState'] ?? {};
    final timerStatus = timerState['status'] ?? 'scheduled';
    final timerPeriod = timerState['period'] ?? '1H';
    final streams = List<Map<String, dynamic>>.from(matchData['streams'] ?? []);
    final goals = _goals;
    final homeGoals = goals.where((g) => g['team'] == 'home').toList();
    final awayGoals = goals.where((g) => g['team'] == 'away').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Partido'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =============================================
            // SCOREBOARD + TIMER CARD
            // =============================================
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Period label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: timerStatus == 'playing' 
                            ? AppColors.liveGreen.withValues(alpha: 0.1)
                            : timerPeriod == 'HT'
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getPeriodLabel(timerPeriod).toUpperCase(),
                        style: TextStyle(
                          color: timerStatus == 'playing' 
                              ? AppColors.liveGreen 
                              : timerPeriod == 'HT' 
                                  ? Colors.orange 
                                  : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Timer
                    Text(
                      _formattedTime,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: timerStatus == 'playing' ? AppColors.liveGreen : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Teams + Score
                    Row(
                      children: [
                        // Home team
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                matchData['homeTeam'] ?? 'Local',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${matchData['homeScore'] ?? 0}',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              // Add Goal button for home
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _addGoal(true),
                                  icon: const Icon(Icons.sports_soccer, size: 16),
                                  label: const Text('GOL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.liveGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // VS separator
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const Text('VS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                "$_currentMinutes'",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: timerStatus == 'playing' ? AppColors.liveGreen : AppColors.textTertiary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Away team
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                matchData['awayTeam'] ?? 'Visita',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${matchData['awayScore'] ?? 0}',
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              // Add Goal button for away
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _addGoal(false),
                                  icon: const Icon(Icons.sports_soccer, size: 16),
                                  label: const Text('GOL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.liveGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // =============================================
            // GOALS LIST
            // =============================================
            if (goals.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Goles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      // Home goals
                      if (homeGoals.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                matchData['homeTeam'] ?? 'Local',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        ...homeGoals.asMap().entries.map((entry) {
                          final goalIndex = goals.indexOf(entry.value);
                          return _buildGoalTile(entry.value, goalIndex);
                        }),
                      ],
                      if (homeGoals.isNotEmpty && awayGoals.isNotEmpty)
                        const Divider(),
                      // Away goals
                      if (awayGoals.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                matchData['awayTeam'] ?? 'Visita',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade700),
                              ),
                            ],
                          ),
                        ),
                        ...awayGoals.asMap().entries.map((entry) {
                          final goalIndex = goals.indexOf(entry.value);
                          return _buildGoalTile(entry.value, goalIndex);
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // =============================================
            // TIMER CONTROLS
            // =============================================
            const Text('Control de Reloj', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (timerStatus == 'scheduled' || (timerStatus == 'paused' && timerPeriod != 'HT'))
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: Text(timerPeriod == '1H' && timerStatus == 'scheduled' ? 'Iniciar Partido' : 'Reanudar Reloj'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.liveGreen, foregroundColor: Colors.white),
                        onPressed: () {
                          if (matchData['status'] == 'scheduled') {
                            _firestoreService.updateMatchStatus(
                              championshipId: widget.championshipId,
                              matchId: widget.matchData['id'],
                              status: 'live',
                            );
                            _firestoreService.updateMatchResult(
                              championshipId: widget.championshipId,
                              matchId: widget.matchData['id'],
                              homeScore: matchData['homeScore'] ?? 0,
                              awayScore: matchData['awayScore'] ?? 0,
                              status: 'live',
                            );
                          }
                          _updateTimerState(status: 'playing', period: timerPeriod, resetStartTime: true);
                        },
                      ),
                    
                    if (timerStatus == 'playing') ...[
                      if (timerPeriod == '1H')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.pause),
                          label: const Text('Descanso (Fin 1erT)'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          onPressed: () => _updateTimerState(status: 'paused', period: 'HT', additionalMinutes: 45),
                        ),
                      if (timerPeriod == '2H')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: const Text('Fin del Partido'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.liveRed, foregroundColor: Colors.white),
                          onPressed: () {
                            _firestoreService.updateMatchStatus(
                                championshipId: widget.championshipId,
                                matchId: widget.matchData['id'],
                                status: 'finished',
                            );
                            _updateTimerState(status: 'finished', period: 'FT', additionalMinutes: 45);
                          },
                        ),
                      if (timerPeriod == 'E1')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.pause),
                          label: const Text('Descanso (Fin 1erT.E.)'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          onPressed: () => _updateTimerState(status: 'paused', period: 'E1', additionalMinutes: 15),
                        ),
                      if (timerPeriod == 'E2')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.sports_score),
                          label: const Text('Ir a Penales'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                          onPressed: () {
                             _updateTimerState(status: 'paused', period: 'PEN', additionalMinutes: 15);
                          },
                        ),
                      if (timerPeriod == 'E2')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: const Text('Fin del Partido (E.T.)'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.liveRed, foregroundColor: Colors.white),
                          onPressed: () {
                            _firestoreService.updateMatchStatus(
                                championshipId: widget.championshipId,
                                matchId: widget.matchData['id'],
                                status: 'finished',
                            );
                            _updateTimerState(status: 'finished', period: 'FT', additionalMinutes: 15);
                          },
                        ),
                      if (timerPeriod == '1H' || timerPeriod == '2H' || timerPeriod == 'E1' || timerPeriod == 'E2')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.timer_off),
                          label: const Text('Pausar Reloj'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                          onPressed: () {
                            final currentMins = _currentTimerSeconds ~/ 60;
                            final additional = currentMins - (timerState['accumulatedMinutes'] ?? 0) as int;
                            _updateTimerState(status: 'paused', period: timerPeriod, additionalMinutes: additional);
                          },
                        ),
                    ],

                    if (timerStatus == 'paused') ...[
                      if (timerPeriod == 'HT')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Iniciar 2do Tiempo'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.liveGreen, foregroundColor: Colors.white),
                          onPressed: () => _updateTimerState(status: 'playing', period: '2H', resetStartTime: true),
                        ),
                      if (timerPeriod == '2H' || timerPeriod == 'FT') ...[
                         ElevatedButton.icon(
                          icon: const Icon(Icons.more_time),
                          label: const Text('Iniciar 1er Tiempo Extra'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                          onPressed: () => _updateTimerState(status: 'playing', period: 'E1', resetStartTime: true),
                        ),
                        ElevatedButton.icon(
                            icon: const Icon(Icons.sports_score),
                            label: const Text('Ir Directo a Penales'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                            onPressed: () => _updateTimerState(status: 'paused', period: 'PEN', resetStartTime: true),
                        ),
                      ],
                      if (timerPeriod == 'E1')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Iniciar 2do Tiempo Extra'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                          onPressed: () => _updateTimerState(status: 'playing', period: 'E2', resetStartTime: true),
                        ),
                     ],

                    // Guaranteed Finalize Button
                    if (timerPeriod == 'HT' || timerPeriod == 'E1' || timerPeriod == 'E2' || matchData['status'] == 'live' || timerPeriod == 'PEN')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: const Text('Finalizar Partido (Forzar)'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.liveRed, foregroundColor: Colors.white),
                        onPressed: () {
                          _firestoreService.updateMatchStatus(
                              championshipId: widget.championshipId,
                              matchId: widget.matchData['id'],
                              status: 'finished',
                          );
                          _updateTimerState(status: 'finished', period: 'FT', additionalMinutes: 0);
                        },
                      ),
                  ],
                ),
              ),
            ),
            
            // =============================================
            // PENALTIES CARD
            // =============================================
            if (timerPeriod == 'PEN' || (matchData['penaltiesScore'] != null && (matchData['penaltiesScore']['home'] > 0 || matchData['penaltiesScore']['away'] > 0))) ...[
               const SizedBox(height: 16),
               const Text('Tanda de Penales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
               const SizedBox(height: 8),
               Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'RESULTADO DE PENALES',
                          style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPenaltyControl(
                              matchData['homeTeam'] ?? 'Local',
                              matchData['penaltiesScore']?['home'] ?? 0,
                              true,
                            ),
                            const Text('-', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                            _buildPenaltyControl(
                              matchData['awayTeam'] ?? 'Visita',
                              matchData['penaltiesScore']?['away'] ?? 0,
                              false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
               ),
            ],

            const SizedBox(height: 24),
            
            // =============================================
            // STREAMS CONTROL
            // =============================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transmisiones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addStream,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (streams.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No hay transmisiones asociadas', style: TextStyle(color: Colors.grey)),
              ))
            else
              ...streams.asMap().entries.map((entry) {
                final idx = entry.key;
                final stream = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(stream['type'] == 'video' ? Icons.videocam : Icons.radio, color: AppColors.primary),
                    title: Text(stream['title'] ?? ''),
                    subtitle: Text(stream['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.liveRed),
                      onPressed: () => _removeStream(idx),
                    ),
                  ),
                );
              }),
              
            // =============================================
            // BETTING ODDS CONFIGURATION
            // =============================================
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Apuestas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Switch(
                  value: matchData['bettingEnabled'] == true,
                  activeColor: AppColors.liveGreen,
                  onChanged: (val) async {
                    await _firestoreService.updateMatchBettingOdds(
                      championshipId: widget.championshipId,
                      matchId: widget.matchData['id'],
                      bettingOdds: matchData['bettingOdds'] ?? {},
                      bettingEnabled: val,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configurar Cuotas (Odds)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Define cuánto paga cada resultado. Ej: 1.50 = gana 50% más',
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildOddsField('Gana ${matchData['homeTeam'] ?? 'Local'}', 'homeWin')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildOddsField('Empate', 'draw')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildOddsField('Gana ${matchData['awayTeam'] ?? 'Visita'}', 'awayWin')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Custom options
                    _buildCustomOddsSection(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveOdds,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Cuotas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Match bets list
            _buildMatchBetsList(),

            const SizedBox(height: 24),
            
            // =============================================
            // STREAMS CONTROL
            // =============================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transmisiones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addStream,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (streams.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No hay transmisiones asociadas', style: TextStyle(color: Colors.grey)),
              ))
            else
              ...streams.asMap().entries.map((entry) {
                final idx = entry.key;
                final stream = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(stream['type'] == 'video' ? Icons.videocam : Icons.radio, color: AppColors.primary),
                    title: Text(stream['title'] ?? ''),
                    subtitle: Text(stream['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.liveRed),
                      onPressed: () => _removeStream(idx),
                    ),
                  ),
                );
              }),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ODDS HELPERS
  // =============================================

  final _homeWinCtrl = TextEditingController();
  final _drawCtrl = TextEditingController();
  final _awayWinCtrl = TextEditingController();
  bool _oddsInitialized = false;

  void _initOddsControllers() {
    if (_oddsInitialized) return;
    _oddsInitialized = true;
    final odds = matchData['bettingOdds'] ?? {};
    _homeWinCtrl.text = (odds['homeWin'] ?? '').toString();
    _drawCtrl.text = (odds['draw'] ?? '').toString();
    _awayWinCtrl.text = (odds['awayWin'] ?? '').toString();
  }

  Widget _buildOddsField(String label, String key) {
    _initOddsControllers();
    final ctrl = key == 'homeWin' ? _homeWinCtrl : key == 'draw' ? _drawCtrl : _awayWinCtrl;

    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        hintText: '1.50',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCustomOddsSection() {
    final customOptions = List<Map<String, dynamic>>.from(matchData['bettingOdds']?['customOptions'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Opciones personalizadas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            TextButton.icon(
              onPressed: _addCustomOdds,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
            ),
          ],
        ),
        ...customOptions.asMap().entries.map((entry) {
          final idx = entry.key;
          final opt = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(child: Text(opt['label'] ?? '', style: const TextStyle(fontSize: 13))),
                Text('x${(opt['odds'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeCustomOdds(idx),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _addCustomOdds() {
    final labelCtrl = TextEditingController();
    final oddsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Opción personalizada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Descripción', hintText: 'Ej: Más de 2.5 goles'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: oddsCtrl,
              decoration: const InputDecoration(labelText: 'Cuota', hintText: 'Ej: 2.50'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (labelCtrl.text.isEmpty || oddsCtrl.text.isEmpty) return;
              final customOptions = List<Map<String, dynamic>>.from(matchData['bettingOdds']?['customOptions'] ?? []);
              customOptions.add({
                'label': labelCtrl.text.trim(),
                'odds': double.tryParse(oddsCtrl.text) ?? 1.0,
              });
              // Save immediately
              final currentOdds = Map<String, dynamic>.from(matchData['bettingOdds'] ?? {});
              currentOdds['customOptions'] = customOptions;
              _firestoreService.updateMatchBettingOdds(
                championshipId: widget.championshipId,
                matchId: widget.matchData['id'],
                bettingOdds: currentOdds,
                bettingEnabled: matchData['bettingEnabled'] == true,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _removeCustomOdds(int index) {
    final customOptions = List<Map<String, dynamic>>.from(matchData['bettingOdds']?['customOptions'] ?? []);
    customOptions.removeAt(index);
    final currentOdds = Map<String, dynamic>.from(matchData['bettingOdds'] ?? {});
    currentOdds['customOptions'] = customOptions;
    _firestoreService.updateMatchBettingOdds(
      championshipId: widget.championshipId,
      matchId: widget.matchData['id'],
      bettingOdds: currentOdds,
      bettingEnabled: matchData['bettingEnabled'] == true,
    );
  }

  void _saveOdds() {
    final currentOdds = Map<String, dynamic>.from(matchData['bettingOdds'] ?? {});
    
    final hw = double.tryParse(_homeWinCtrl.text);
    final dr = double.tryParse(_drawCtrl.text);
    final aw = double.tryParse(_awayWinCtrl.text);

    if (hw != null) currentOdds['homeWin'] = hw;
    if (dr != null) currentOdds['draw'] = dr;
    if (aw != null) currentOdds['awayWin'] = aw;

    _firestoreService.updateMatchBettingOdds(
      championshipId: widget.championshipId,
      matchId: widget.matchData['id'],
      bettingOdds: currentOdds,
      bettingEnabled: matchData['bettingEnabled'] == true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuotas guardadas')),
    );
  }

  Widget _buildMatchBetsList() {
    final bets = ref.watch(betsByMatchProvider(widget.matchData['id']));

    return bets.when(
      data: (betList) {
        if (betList.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Apuestas del partido (${betList.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...betList.map((bet) {
              final betStatus = bet['status'] ?? 'pending_payment';
              final statusColor = betStatus == 'pending_payment' ? Colors.orange
                  : betStatus == 'confirmed' ? AppColors.liveGreen
                  : betStatus == 'won' ? AppColors.liveGreen
                  : betStatus == 'paid' ? Colors.blue
                  : betStatus == 'lost' ? Colors.red
                  : Colors.grey;

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Text(
                      (bet['userName'] ?? 'U').substring(0, 1),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                  title: Text('${bet['userName']} - ${bet['selectionLabel']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'S/ ${(bet['amount'] ?? 0).toStringAsFixed(2)} → S/ ${(bet['potentialWinnings'] ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: _buildQuickAction(bet),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickAction(Map<String, dynamic> bet) {
    final status = bet['status'] ?? 'pending_payment';

    if (status == 'pending_payment') {
      return IconButton(
        icon: const Icon(Icons.check_circle, color: AppColors.liveGreen, size: 22),
        onPressed: () => _firestoreService.confirmBetPayment(bet['id']),
        tooltip: 'Confirmar pago',
      );
    }
    if (status == 'confirmed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: AppColors.liveGreen, size: 20),
            onPressed: () => _firestoreService.settleBet(bet['id'], true),
            tooltip: 'Ganó',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () => _firestoreService.settleBet(bet['id'], false),
            tooltip: 'Perdió',
          ),
        ],
      );
    }
    if (status == 'won') {
      return IconButton(
        icon: const Icon(Icons.payments, color: Colors.blue, size: 22),
        onPressed: () => _firestoreService.markBetPaid(bet['id']),
        tooltip: 'Marcar pagado',
      );
    }
    return Text(
      status == 'paid' ? '💰' : status == 'lost' ? '❌' : '🚫',
      style: const TextStyle(fontSize: 16),
    );
  }

  Widget _buildGoalTile(Map<String, dynamic> goal, int index) {
    return ListTile(
      dense: true,
      leading: const Text('⚽', style: TextStyle(fontSize: 18)),
      title: Text(
        goal['scorer'] ?? 'Desconocido',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        "${goal['minute']}' - ${_getPeriodLabel(goal['period'])}",
        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 18, color: Colors.red),
        onPressed: () => _removeGoal(index),
        tooltip: 'Eliminar gol',
      ),
    );
  }

  Widget _buildPenaltyControl(String teamName, int score, bool isHome) {
    return Column(
      children: [
        Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.deepPurple),
                onPressed: () => _updatePenalties(isHome, -1),
              ),
              Text('$score', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                onPressed: () => _updatePenalties(isHome, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
