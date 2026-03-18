import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';
import 'admin_match_control_screen.dart';

class AdminMatchesScreen extends ConsumerWidget {
  final String championshipId;
  final String championshipName;

  const AdminMatchesScreen({
    super.key,
    required this.championshipId,
    required this.championshipName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesByChampionshipProvider(championshipId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Partidos - $championshipName'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.adminGradient),
        ),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'resetMatches',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Reiniciar todo?'),
                  content: const Text('Esto devolverá TODOS los partidos a estado "Programado", eliminando puntajes, tiempo y transmisiones.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.liveRed, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true), 
                      child: const Text('Sí, Reiniciar')
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final snap = await FirebaseFirestore.instance
                    .collection('championships')
                    .doc(championshipId)
                    .collection('matches')
                    .get();
                
                for (var doc in snap.docs) {
                  await doc.reference.update({
                    'status': 'scheduled',
                    'homeScore': 0,
                    'awayScore': 0,
                    'timerState': {
                      'status': 'scheduled',
                      'period': '1H',
                      'accumulatedMinutes': 0,
                      'periodStartTime': null,
                    },
                    'streams': [],
                  });
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todos los partidos fueron reiniciados')));
                }
              }
            },
            backgroundColor: AppColors.liveRed,
            icon: const Icon(Icons.settings_backup_restore, color: Colors.white),
            label: const Text('Reiniciar Todos', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'genMatches',
            onPressed: () => _showGenerateMatchesDialog(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text('Generar Partidos', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'addMatch',
            onPressed: () => _showAddMatchDialog(context),
            backgroundColor: AppColors.adminOrange,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Agregar Partido', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: matches.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer_outlined, size: 80, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text('No hay partidos', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                  SizedBox(height: 8),
                  Text('Agrega los partidos del campeonato', style: TextStyle(color: AppColors.textTertiary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final match = list[index];
              final status = match['status'] ?? 'scheduled';
              final homeScore = match['homeScore'];
              final awayScore = match['awayScore'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: status == 'live'
                      ? Border.all(color: AppColors.liveGreen, width: 2)
                      : null,
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
                    // Match number & status
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${match['matchNumber'] ?? (index + 1)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          match['league'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Teams
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            match['homeTeam'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: homeScore != null ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            match['awayTeam'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    
                    if (match['location'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            match['location'],
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'GESTIONAR PARTIDO', 
                            AppColors.adminOrange, 
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminMatchControlScreen(
                                    championshipId: championshipId,
                                    matchData: match,
                                  ),
                                ),
                              );
                            }
                          ),
                        ),
                      ],
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'live':
        color = AppColors.liveGreen;
        label = '🔴 EN VIVO';
        break;
      case 'finished':
        color = AppColors.textTertiary;
        label = '✅ Finalizado';
        break;
      default:
        color = Colors.blue;
        label = '⏰ Programado';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label),
      ),
    );
  }



  void _showAddMatchDialog(BuildContext context) {
    final homeCtrl = TextEditingController();
    final awayCtrl = TextEditingController();
    final leagueCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final matchNumCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Partido'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: matchNumCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'N° de Partido (1-14)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: homeCtrl,
                decoration: const InputDecoration(labelText: 'Equipo Local'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: awayCtrl,
                decoration: const InputDecoration(labelText: 'Equipo Visitante'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: leagueCtrl,
                decoration: const InputDecoration(labelText: 'Liga / Torneo'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Ubicación (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (homeCtrl.text.isEmpty || awayCtrl.text.isEmpty) return;
              final service = FirestoreService();
              await service.addMatch(
                championshipId: championshipId,
                homeTeam: homeCtrl.text,
                awayTeam: awayCtrl.text,
                league: leagueCtrl.text,
                matchNumber: int.tryParse(matchNumCtrl.text) ?? 1,
                startTime: selectedDate,
                location: locationCtrl.text.isNotEmpty ? locationCtrl.text : null,
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminOrange),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showGenerateMatchesDialog(BuildContext context) {
    final teamsCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generar Partidos Aleatorios'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa los equipos inscritos, uno por línea. Se emparejarán automáticamente. (Ej: para 14 partidos, ingresa 28 equipos).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: teamsCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Lista de Equipos',
                  alignLabelWithHint: true,
                  hintText: 'Equipo 1\nEquipo 2\nEquipo 3\nEquipo 4...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final lines = teamsCtrl.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              if (lines.isEmpty || lines.length % 2 != 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debes ingresar un número par de equipos.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              lines.shuffle(); // Generar enfrentamientos aleatorios
              final service = FirestoreService();
              
              int matchNumber = 1;
              for (int i = 0; i < lines.length; i += 2) {
                await service.addMatch(
                  championshipId: championshipId,
                  homeTeam: lines[i],
                  awayTeam: lines[i + 1],
                  league: championshipName,
                  matchNumber: matchNumber++,
                  startTime: DateTime.now(),
                );
              }
              
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Se generaron ${lines.length ~/ 2} partidos exitosamente.'),
                    backgroundColor: AppColors.liveGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Generar Fixture', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
