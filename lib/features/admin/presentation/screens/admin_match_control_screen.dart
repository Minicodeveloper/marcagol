import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
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

  String get _formattedTime {
    final minutes = _currentTimerSeconds ~/ 60;
    final seconds = _currentTimerSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getPeriodLabel(String? period) {
    switch (period) {
      case '1H': return '1er Tiempo';
      case 'HT': return 'Descanso (E.T.)';
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

  Future<void> _updateScore(bool isHome, int change) async {
    int currentHome = matchData['homeScore'] ?? 0;
    int currentAway = matchData['awayScore'] ?? 0;

    if (isHome) {
      currentHome = (currentHome + change).clamp(0, 99);
    } else {
      currentAway = (currentAway + change).clamp(0, 99);
    }

    await _firestoreService.updateMatchResult(
      championshipId: widget.championshipId,
      matchId: widget.matchData['id'],
      homeScore: currentHome,
      awayScore: currentAway,
      status: matchData['status'] ?? 'scheduled',
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
                    DropdownMenuItem(value: 'video', child: Text('Video (YouTube)')),
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
                  decoration: const InputDecoration(labelText: 'URL (Youtube/Stream)'),
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
            // SCORER CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _getPeriodLabel(timerPeriod).toUpperCase(),
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formattedTime,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: timerStatus == 'playing' ? AppColors.liveGreen : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTeamScoreControl(
                          matchData['homeTeam'] ?? 'Local',
                          matchData['homeScore'] ?? 0,
                          true,
                          false,
                        ),
                        const Text('VS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                        _buildTeamScoreControl(
                          matchData['awayTeam'] ?? 'Visita',
                          matchData['awayScore'] ?? 0,
                          false,
                          false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // TIMER CONTROLS
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
                            if (matchData['homeScore'] == null) _updateScore(true, 0);
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

                    // Guaranteed Finalize Button for stuck matches or HT period
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
            
            // PENALTIES CARD (Only if in PEN or finished after PEN)
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
                            _buildTeamScoreControl(
                              matchData['homeTeam'] ?? 'Local',
                              matchData['penaltiesScore']?['home'] ?? 0,
                              true,
                              true,
                            ),
                            const Text('-', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                            _buildTeamScoreControl(
                              matchData['awayTeam'] ?? 'Visita',
                              matchData['penaltiesScore']?['away'] ?? 0,
                              false,
                              true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
               ),
            ],

            const SizedBox(height: 24),
            
            // STREAMS CONTROL
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

  Widget _buildTeamScoreControl(String teamName, int score, bool isHome, bool isPenalty) {
    return Column(
      children: [
        Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => isPenalty ? _updatePenalties(isHome, -1) : _updateScore(isHome, -1)),
              Text('$score', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: () => isPenalty ? _updatePenalties(isHome, 1) : _updateScore(isHome, 1)),
            ],
          ),
        ),
      ],
    );
  }
}
