import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';
import 'admin_matches_screen.dart';

class AdminChampionshipsScreen extends ConsumerWidget {
  const AdminChampionshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championships = ref.watch(championshipsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campeonatos'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.adminGradient),
        ),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: AppColors.adminOrange,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Campeonato'),
      ),
      body: championships.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 80, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text('No hay campeonatos', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                  SizedBox(height: 8),
                  Text('Crea el primer campeonato', style: TextStyle(color: AppColors.textTertiary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final champ = list[index];
              final isActive = champ['isActive'] == true;
              final isVisible = champ['isVisible'] == true;
              final status = champ['status'] ?? 'active';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
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
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.liveGreen.withValues(alpha: 0.1)
                              : AppColors.textTertiary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: isActive ? AppColors.liveGreen : AppColors.textTertiary,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        champ['name'] ?? 'Sin nombre',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (champ['description'] != null)
                            Text(champ['description'], style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildBadge(
                                status == 'finished' ? 'Finalizado' : (isActive ? 'Activo' : 'Inactivo'),
                                status == 'finished'
                                    ? Colors.grey
                                    : (isActive ? AppColors.liveGreen : AppColors.textTertiary),
                              ),
                              const SizedBox(width: 8),
                              _buildBadge(
                                isVisible ? 'Visible' : 'Oculto',
                                isVisible ? Colors.blue : Colors.orange,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) => _handleAction(context, value, champ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'matches', child: Text('📋 Ver Partidos')),
                          PopupMenuItem(
                            value: 'toggle_visible',
                            child: Text(isVisible ? '👁️ Ocultar' : '👁️ Mostrar'),
                          ),
                          if (!isActive)
                            const PopupMenuItem(value: 'set_active', child: Text('✅ Hacer Activo')),
                          if (status != 'finished')
                            const PopupMenuItem(value: 'finish', child: Text('🏁 Finalizar')),
                          const PopupMenuItem(value: 'delete', child: Text('🗑️ Eliminar')),
                        ],
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleAction(BuildContext context, String action, Map<String, dynamic> champ) async {
    final service = FirestoreService();
    final id = champ['id'] as String;

    switch (action) {
      case 'matches':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminMatchesScreen(
              championshipId: id,
              championshipName: champ['name'] ?? '',
            ),
          ),
        );
        break;
      case 'toggle_visible':
        await service.toggleChampionshipVisibility(id, !(champ['isVisible'] == true));
        break;
      case 'set_active':
        await service.setActiveChampionship(id);
        break;
      case 'finish':
        await service.finishChampionship(id);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Eliminar campeonato?'),
            content: const Text('Esta acción no se puede deshacer.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true) await service.deleteChampionship(id);
        break;
    }
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final matchesCtrl = TextEditingController(text: '14');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Campeonato'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Campeonato',
                  hintText: 'Ej: Liga 2026 - Jornada 1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: Primera jornada del torneo',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: matchesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de Partidos',
                  hintText: '14',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final service = FirestoreService();
              await service.createChampionship(
                name: nameCtrl.text,
                description: descCtrl.text,
                totalMatches: int.tryParse(matchesCtrl.text) ?? 14,
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminOrange),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
