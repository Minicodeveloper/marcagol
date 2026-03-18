import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';

class AdminBallotsScreen extends ConsumerWidget {
  const AdminBallotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ballots = ref.watch(allBallotsProvider);
    final championships = ref.watch(championshipsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cartillas / Pozos'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.adminGradient),
        ),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBallotDialog(context, ref),
        backgroundColor: AppColors.adminOrange,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cartilla'),
      ),
      body: ballots.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer_outlined, size: 80, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text('No hay cartillas', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                  SizedBox(height: 8),
                  Text('Crea una cartilla con su pozo', style: TextStyle(color: AppColors.textTertiary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final ballot = list[index];
              final status = ballot['status'] ?? 'active';
              final mode = ballot['mode'] ?? 'result';
              final prizePool = (ballot['prizePool'] as num?)?.toDouble() ?? 0;
              final participants = ballot['participantCount'] ?? 0;
              final winnerIds = List<String>.from(ballot['winnerIds'] ?? []);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: status == 'active'
                      ? AppColors.primaryGradient
                      : (status == 'finished' ? AppColors.goldGradient : AppColors.inactiveGradient),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              mode == 'result' ? '1X2 Resultado' : '⚽ Marcador',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status == 'active' ? '🟢 Activa' : (status == 'finished' ? '🏆 Finalizada' : '🔒 Cerrada'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ballot['title'] ?? 'Sin título',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'POZO',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'S/ ${prizePool.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              const Icon(Icons.people, color: Colors.white, size: 24),
                              Text(
                                '$participants',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'participantes',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (status == 'finished' && winnerIds.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                '${winnerIds.length} ganador(es) - S/ ${(prizePool / winnerIds.length).toStringAsFixed(2)} c/u',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (status == 'active')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final service = FirestoreService();
                                  await service.closeBallot(ballot['id']);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                ),
                                child: const Text('CERRAR', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          if (status == 'closed') ...[
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showResolveDialog(context, ballot),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.liveGreen,
                                ),
                                child: const Text('RESOLVER GANADORES', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('¿Eliminar cartilla?'),
                                  content: const Text('Se eliminarán también todas las participaciones.'),
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
                                final service = FirestoreService();
                                await service.deleteBallot(ballot['id']);
                              }
                            },
                            icon: const Icon(Icons.delete, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
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

  void _showResolveDialog(BuildContext context, Map<String, dynamic> ballot) {
    final matches = List<Map<String, dynamic>>.from(ballot['matches'] ?? []);
    final mode = ballot['mode'] ?? 'result';
    final results = <String, String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ingresar Resultados'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final title = ballot['title'] ?? 'Cartilla';
                      // Auto-fill from championship matches
                      final champId = ballot['championshipId'];
                      if (champId == null) return;
                      
                      final snap = await FirebaseFirestore.instance
                          .collection('championships')
                          .doc(champId)
                          .collection('matches')
                          .get();
                          
                      final realMatches = {for (var doc in snap.docs) doc.id: doc.data()};
                      
                      setDialogState(() {
                        for (int i = 0; i < matches.length; i++) {
                          final matchId = matches[i]['matchId'];
                          if (matchId != null && realMatches.containsKey(matchId)) {
                            final realM = realMatches[matchId]!;
                            final hScore = realM['homeScore'];
                            final aScore = realM['awayScore'];
                            
                            if (hScore != null && aScore != null) {
                              if (mode == 'result') {
                                if (hScore > aScore) results['$i'] = 'LOCAL';
                                else if (hScore == aScore) results['$i'] = 'EMPATE';
                                else results['$i'] = 'VISITA';
                              } else {
                                results['$i'] = '$hScore-$aScore';
                              }
                            }
                          }
                        }
                      });
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Se cargaron los resultados listos. Favor confirmar.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Cargar Resultados Reales'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mode == 'result'
                        ? 'Selecciona el resultado de cada partido'
                        : 'Ingresa el marcador de cada partido',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ...matches.asMap().entries.map((entry) {
                    final i = entry.key;
                    final match = entry.value;
                    final key = '$i';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: results.containsKey(key)
                            ? Border.all(color: AppColors.liveGreen)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${match['homeTeam']} vs ${match['awayTeam']}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (mode == 'result')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: ['LOCAL', 'EMPATE', 'VISITA'].map((option) {
                                final isSelected = results[key] == option;
                                return GestureDetector(
                                  onTap: () => setDialogState(() => results[key] = option),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : Colors.grey,
                                      ),
                                    ),
                                    child: Text(
                                      option == 'LOCAL' ? '1' : (option == 'EMPATE' ? 'X' : '2'),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(hintText: '0'),
                                    onChanged: (v) {
                                      final away = results[key]?.split('-').last ?? '0';
                                      setDialogState(() => results[key] = '$v-$away');
                                    },
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(hintText: '0'),
                                    onChanged: (v) {
                                      final home = results[key]?.split('-').first ?? '0';
                                      setDialogState(() => results[key] = '$home-$v');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          if (mode == 'score' && results.containsKey(key))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Resultado Actual: ${results[key]}',
                                style: TextStyle(color: AppColors.liveGreen, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: results.length == matches.length
                  ? () async {
                      final service = FirestoreService();
                      final winners = await service.resolveBallot(
                        ballotId: ballot['id'],
                        results: results,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            winners.isEmpty
                                ? '❌ No hubo ganadores'
                                : '🏆 ${winners.length} ganador(es) encontrado(s)',
                          ),
                          backgroundColor: winners.isEmpty ? Colors.orange : AppColors.liveGreen,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.liveGreen),
              child: Text('RESOLVER (${results.length}/${matches.length})'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateBallotDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final prizeCtrl = TextEditingController();
    String selectedMode = 'result';
    String? selectedChampionshipId;
    DateTime deadline = DateTime.now().add(const Duration(days: 3));

    final championships = ref.read(championshipsProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nueva Cartilla'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Seleccionar campeonato
                championships.when(
                  data: (list) {
                    return DropdownButtonFormField<String>(
                      value: selectedChampionshipId,
                      decoration: const InputDecoration(labelText: 'Campeonato'),
                      items: list.map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['name'] ?? 'Sin nombre', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedChampionshipId = v),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título de la Cartilla',
                    hintText: 'Ej: Cartilla Fin de Semana',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prizeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto del Pozo (S/)',
                    hintText: '500',
                  ),
                ),
                const SizedBox(height: 16),
                // Mode selector
                const Text('Modalidad:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedMode = 'result'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedMode == 'result' ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.check_box,
                                color: selectedMode == 'result' ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1X2',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: selectedMode == 'result' ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Por Resultado',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selectedMode == 'result' ? Colors.white70 : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedMode = 'score'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedMode == 'score' ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.sports_score,
                                color: selectedMode == 'score' ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Marcador',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: selectedMode == 'score' ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Exacto',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selectedMode == 'score' ? Colors.white70 : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || prizeCtrl.text.isEmpty || selectedChampionshipId == null) return;
                
                // Obtener partidos del campeonato
                final matchesSnap = await FirebaseFirestore.instance
                    .collection('championships')
                    .doc(selectedChampionshipId!)
                    .collection('matches')
                    .orderBy('matchNumber')
                    .get();
                
                final matchesList = matchesSnap.docs.map((d) => {
                  'matchId': d.id,
                  'homeTeam': d.data()['homeTeam'],
                  'awayTeam': d.data()['awayTeam'],
                  'league': d.data()['league'],
                  'matchNumber': d.data()['matchNumber'],
                }).toList();
                
                if (matchesList.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El campeonato no tiene partidos. Agrega partidos primero.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final service = FirestoreService();
                await service.createBallot(
                  championshipId: selectedChampionshipId!,
                  title: titleCtrl.text,
                  prizePool: double.tryParse(prizeCtrl.text) ?? 0,
                  deadline: deadline,
                  mode: selectedMode,
                  matches: matchesList,
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminOrange),
              child: const Text('Crear Cartilla'),
            ),
          ],
        ),
      ),
    );
  }
}
