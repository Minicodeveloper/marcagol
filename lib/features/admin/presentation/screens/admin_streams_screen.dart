import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';

class AdminStreamsScreen extends ConsumerWidget {
  const AdminStreamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(allStreamsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Transmisiones'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.adminGradient),
          ),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.live_tv), text: 'Video'),
              Tab(icon: Icon(Icons.radio), text: 'Radio'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateStreamDialog(context, ref),
          backgroundColor: AppColors.adminOrange,
          icon: const Icon(Icons.add),
          label: const Text('Nueva Transmisión'),
        ),
        body: streams.when(
          data: (list) {
            final videoStreams = list.where((s) => s['type'] == 'video').toList();
            final radioStreams = list.where((s) => s['type'] == 'radio').toList();

            return TabBarView(
              children: [
                _buildStreamList(context, videoStreams, 'video'),
                _buildStreamList(context, radioStreams, 'radio'),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildStreamList(BuildContext context, List<Map<String, dynamic>> streams, String type) {
    if (streams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'video' ? Icons.videocam_off : Icons.radio,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay transmisiones de ${type == 'video' ? 'video' : 'radio'}',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: streams.length,
      itemBuilder: (context, index) {
        final stream = streams[index];
        final isActive = stream['isActive'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: AppColors.liveGreen, width: 1) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.liveRed.withValues(alpha: 0.1)
                    : AppColors.textTertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                type == 'video' ? Icons.play_circle_fill : Icons.radio,
                color: isActive ? AppColors.liveRed : AppColors.textTertiary,
                size: 28,
              ),
            ),
            title: Text(
              stream['title'] ?? 'Sin título',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stream['description'] != null)
                  Text(stream['description'], style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  type == 'video'
                      ? (stream['youtubeUrl'] ?? 'Sin URL')
                      : (stream['streamUrl'] ?? 'Sin URL'),
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.liveGreen.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? '🟢 Activa' : '⚪ Inactiva',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.liveGreen : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, value, stream),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(isActive ? '⏸️ Desactivar' : '▶️ Activar'),
                ),
                const PopupMenuItem(value: 'edit', child: Text('✏️ Editar')),
                const PopupMenuItem(value: 'delete', child: Text('🗑️ Eliminar')),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleAction(BuildContext context, String action, Map<String, dynamic> stream) async {
    final service = FirestoreService();
    final id = stream['id'] as String;

    switch (action) {
      case 'toggle':
        await service.toggleStreamActive(id, !(stream['isActive'] == true));
        break;
      case 'edit':
        _showEditStreamDialog(context, stream);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Eliminar transmisión?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true) await service.deleteStream(id);
        break;
    }
  }

  void _showCreateStreamDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    String selectedType = 'video';
    String? selectedMatchId;

    final activeChampionship = ref.read(activeChampionshipProvider).valueOrNull;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final matches = activeChampionship != null 
              ? ref.watch(matchesByChampionshipProvider(activeChampionship['id'])).valueOrNull ?? []
              : [] as List<Map<String, dynamic>>;

          return AlertDialog(
          title: const Text('Nueva Transmisión'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type selector
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedType = 'video'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == 'video' ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📺 Video',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedType == 'video' ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedType = 'radio'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == 'radio' ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '📻 Radio',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedType == 'radio' ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Match selector (Optional)
                if (matches.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    value: selectedMatchId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Global (Sin partido)')),
                      ...matches.map((m) => DropdownMenuItem(
                        value: m['id'],
                        child: Text('${m['homeTeam']} vs ${m['awayTeam']}', 
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (val) => setDialogState(() => selectedMatchId = val),
                    decoration: const InputDecoration(labelText: 'Vincular a Partido'),
                  ),
                const SizedBox(height: 8),

                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText: selectedType == 'video'
                        ? 'URL de Video (YouTube, Facebook, etc.)'
                        : 'URL de Radio (Stream, YouTube, Facebook)',
                    hintText: selectedType == 'video'
                        ? 'https://www.youtube.com/watch?v=... o Facebook'
                        : 'https://stream.radio.com/... o enlace Live',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                ),
                if (selectedType == 'radio') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: freqCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Frecuencia MHz (opcional)',
                      hintText: '107.7',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
                final service = FirestoreService();
                if (selectedType == 'video') {
                  await service.createVideoStream(
                    title: titleCtrl.text,
                    youtubeUrl: urlCtrl.text,
                    description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                    championshipId: activeChampionship?['id'],
                    matchId: selectedMatchId,
                  );
                } else {
                  await service.createRadioStream(
                    title: titleCtrl.text,
                    streamUrl: urlCtrl.text,
                    description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                    frequency: double.tryParse(freqCtrl.text),
                    championshipId: activeChampionship?['id'],
                    matchId: selectedMatchId,
                  );
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminOrange),
              child: const Text('Crear'),
            ),
          ],
        );
        }
      ),
    );
  }

  void _showEditStreamDialog(BuildContext context, Map<String, dynamic> stream) {
    final titleCtrl = TextEditingController(text: stream['title']);
    final urlCtrl = TextEditingController(
      text: stream['type'] == 'video' ? stream['youtubeUrl'] : stream['streamUrl'],
    );
    final descCtrl = TextEditingController(text: stream['description'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Transmisión'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  labelText: stream['type'] == 'video' ? 'URL de Video' : 'URL de Streaming',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final service = FirestoreService();
              final data = <String, dynamic>{
                'title': titleCtrl.text,
                'description': descCtrl.text.isNotEmpty ? descCtrl.text : null,
              };
              if (stream['type'] == 'video') {
                data['youtubeUrl'] = urlCtrl.text;
              } else {
                data['streamUrl'] = urlCtrl.text;
              }
              await service.updateStream(stream['id'], data);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminOrange),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
