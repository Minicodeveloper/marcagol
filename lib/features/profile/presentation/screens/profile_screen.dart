import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../widgets/menu_item_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final userData = ref.watch(currentUserDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 20),

            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isLoggedIn
                  ? userData.when(
                      data: (data) => Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: isAdmin ? AppColors.adminOrange : AppColors.primary,
                            child: Text(
                              (data?['displayName'] ?? 'U').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data?['displayName'] ?? 'Usuario',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  data?['email'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? AppColors.adminOrange.withValues(alpha: 0.1)
                                        : AppColors.liveGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isAdmin ? '🔧 Administrador' : '✅ Verificado',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin ? AppColors.adminOrange : AppColors.liveGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Error cargando perfil'),
                    )
                  : Column(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.background,
                          child: Icon(Icons.person, size: 32, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Inicia sesión o regístrate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Para participar en las cartillas',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('INICIAR SESIÓN',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Admin panel button (only for admins)
            if (isAdmin) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.adminGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                  title: const Text(
                    'Panel de Administración',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'Gestión de campeonatos, transmisiones y cartillas',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    );
                  },
                ),
              ),
            ],

            // Menu items
            if (isLoggedIn) ...[
              MenuItemWidget(
                icon: Icons.receipt_long,
                title: 'Mis Cartillas',
                onTap: () {},
              ),
              MenuItemWidget(
                icon: Icons.settings,
                title: 'Configuración',
                onTap: () {},
              ),
              MenuItemWidget(
                icon: Icons.help_outline,
                title: 'Ayuda',
                onTap: () {},
              ),
              MenuItemWidget(
                icon: Icons.info_outline,
                title: 'Acerca de',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Marca Gol',
                    applicationVersion: '1.0.0',
                    children: [
                      const Text('Sistema de apuestas deportivas con pozos colectivos.'),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              MenuItemWidget(
                icon: Icons.logout,
                title: 'Cerrar Sesión',
                isDestructive: true,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('¿Cerrar sesión?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Cerrar Sesión',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirestoreService().logout();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}