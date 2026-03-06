import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/profile_header.dart';
import '../widgets/menu_item_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Verificar si el usuario está autenticado y su rol
    final bool isLoggedIn = false; // Reemplazar con estado real
    final bool isAdmin = false; // Reemplazar con estado real

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileHeader(isLoggedIn: isLoggedIn),
          const SizedBox(height: 24),
          
          // 🔧 BOTÓN ADMIN (SOLO VISIBLE PARA ADMIN)
          if (isLoggedIn && isAdmin) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                ),
                title: const Text(
                  '🔧 Panel de Administración',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
                onTap: () {
                  // TODO: Navegar a AdminDashboardScreen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Panel Admin: Próximamente'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
          ],
          
          const MenuItemWidget(
            icon: Icons.account_balance_wallet,
            title: 'Mi Billetera',
          ),
          const MenuItemWidget(
            icon: Icons.history,
            title: 'Mis Cartillas',
          ),
          const MenuItemWidget(
            icon: Icons.card_giftcard,
            title: 'Promociones',
          ),
          const MenuItemWidget(
            icon: Icons.settings,
            title: 'Configuración',
          ),
          const MenuItemWidget(
            icon: Icons.help_outline,
            title: 'Ayuda',
          ),
          const MenuItemWidget(
            icon: Icons.info_outline,
            title: 'Acerca de',
          ),
          if (isLoggedIn) ...[
            const SizedBox(height: 16),
            const MenuItemWidget(
              icon: Icons.logout,
              title: 'Cerrar Sesión',
              isDestructive: true,
            ),
          ],
        ],
      ),
    );
  }
}