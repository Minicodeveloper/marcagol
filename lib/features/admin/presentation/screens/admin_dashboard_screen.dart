import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import 'admin_championships_screen.dart';
import 'admin_streams_screen.dart';
import 'admin_ballots_screen.dart';
import 'admin_bets_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.adminGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header admin
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.adminGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, size: 32, color: AppColors.adminOrange),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData.when(
                          data: (d) => d?['displayName'] ?? 'Admin',
                          loading: () => 'Cargando...',
                          error: (_, __) => 'Admin',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Administrador',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Gestión',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Campeonatos
          _buildAdminCard(
            context,
            icon: Icons.emoji_events,
            title: 'Campeonatos',
            subtitle: 'Crear, ocultar/mostrar campeonatos y gestionar partidos',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminChampionshipsScreen()),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Transmisiones
          _buildAdminCard(
            context,
            icon: Icons.live_tv,
            title: 'Transmisiones',
            subtitle: 'Agregar enlaces de YouTube y emisoras de radio',
            color: AppColors.liveRed,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminStreamsScreen()),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Cartillas / Pozos
          _buildAdminCard(
            context,
            icon: Icons.sports_soccer,
            title: 'Cartillas / Pozos',
            subtitle: 'Crear cartillas, definir pozos, resolver ganadores',
            color: AppColors.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminBallotsScreen()),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Apuestas
          _buildAdminCard(
            context,
            icon: Icons.casino,
            title: 'Apuestas',
            subtitle: 'Gestionar apuestas, confirmar pagos, resolver resultados',
            color: Colors.deepPurple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminBetsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
