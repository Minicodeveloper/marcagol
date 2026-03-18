import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../pools/presentation/screens/pool_detail_screen.dart';
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
                            backgroundColor: isAdmin ? AppColors.adminOrange : AppColors.accent,
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
                        // Logo
                        Image.asset(
                          'assets/images/logo.png',
                          height: 60,
                          fit: BoxFit.contain,
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
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.orangeGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('INICIAR SESIÓN',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
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
                onTap: () => _showMyBallots(context, ref),
              ),
              MenuItemWidget(
                icon: Icons.casino,
                title: 'Mis Apuestas',
                onTap: () => _showMyBets(context, ref),
              ),
              MenuItemWidget(
                icon: Icons.settings,
                title: 'Configuración',
                onTap: () => _showSettings(context, ref),
              ),
              MenuItemWidget(
                icon: Icons.help_outline,
                title: 'Ayuda',
                onTap: () => _showHelp(context),
              ),
              MenuItemWidget(
                icon: Icons.info_outline,
                title: 'Acerca de',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Marca Gol',
                    applicationVersion: '1.0.0',
                    applicationIcon: Image.asset('assets/images/logo.png', height: 40),
                    children: [
                      const Text('Sistema de apuestas deportivas con pozos colectivos.'),
                      const SizedBox(height: 8),
                      const Text(
                        'Predice los resultados de los partidos y gana el pozo acumulado.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
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
                    await ref.read(authNotifierProvider.notifier).logout();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows the user's ballot entries (Mis Cartillas)
  void _showMyBallots(BuildContext context, WidgetRef ref) {
    final entries = ref.read(myBallotEntriesProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text(
                      'Mis Cartillas',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: entries.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text(
                                'No has participado en ninguna cartilla',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Participa en las cartillas activas para ver tus entradas aquí',
                                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final entry = list[i];
                        final isWinner = entry['isWinner'] == true;
                        final correct = entry['correctPredictions'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: isWinner
                                ? Border.all(color: AppColors.liveGreen, width: 2)
                                : Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entry['participationCode'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isWinner)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.liveGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('🏆 ¡GANASTE!',
                                          style: TextStyle(color: AppColors.liveGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Progress bar
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: correct / 14,
                                        backgroundColor: Colors.grey.shade200,
                                        color: correct >= 14
                                            ? AppColors.liveGreen
                                            : correct >= 10
                                                ? AppColors.secondary
                                                : AppColors.primary,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$correct/14 aciertos',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              if (entry['ballotId'] != null) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PoolDetailScreen(ballotId: entry['ballotId']),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Ver cartilla →',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows user's bets (Mis Apuestas)
  void _showMyBets(BuildContext context, WidgetRef ref) {
    final bets = ref.read(myBetsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.casino, color: Colors.deepPurple),
                    SizedBox(width: 12),
                    Text('Mis Apuestas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: bets.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.casino_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No has realizado apuestas', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final bet = list[i];
                        final status = bet['status'] ?? 'pending_payment';
                        final statusInfo = _getBetStatusInfo(status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusInfo['color'].withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      bet['betCode'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 11),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusInfo['color'].withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusInfo['label'],
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusInfo['color']),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${bet['homeTeam']} vs ${bet['awayTeam']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text('🎯 ${bet['selectionLabel']}', style: const TextStyle(fontSize: 12)),
                                  const Spacer(),
                                  Text(
                                    'x${(bet['odds'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Apostado: S/ ${(bet['amount'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Ganancia: S/ ${(bet['potentialWinnings'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.liveGreen),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getBetStatusInfo(String status) {
    switch (status) {
      case 'pending_payment': return {'label': '⏳ Pendiente de pago', 'color': Colors.orange};
      case 'confirmed': return {'label': '✅ Confirmada', 'color': AppColors.liveGreen};
      case 'won': return {'label': '🏆 ¡Ganaste!', 'color': AppColors.liveGreen};
      case 'lost': return {'label': '❌ Perdida', 'color': Colors.red};
      case 'paid': return {'label': '💰 Pagada', 'color': Colors.blue};
      case 'cancelled': return {'label': '🚫 Cancelada', 'color': Colors.grey};
      default: return {'label': status, 'color': Colors.grey};
    }
  }

  /// Shows configuration/settings
  void _showSettings(BuildContext context, WidgetRef ref) {
    final userData = ref.read(currentUserDataProvider).valueOrNull;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.settings, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text(
                    'Configuración',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // User info section
              _buildSettingsSection('Información Personal', [
                _buildSettingsItem(
                  icon: Icons.person_outline,
                  title: 'Nombre',
                  value: userData?['displayName'] ?? 'N/A',
                ),
                _buildSettingsItem(
                  icon: Icons.email_outlined,
                  title: 'Correo',
                  value: userData?['email'] ?? 'N/A',
                ),
                _buildSettingsItem(
                  icon: Icons.phone_outlined,
                  title: 'Teléfono',
                  value: userData?['phone']?.toString().isNotEmpty == true 
                      ? userData!['phone'] 
                      : 'No registrado',
                ),
                _buildSettingsItem(
                  icon: Icons.badge_outlined,
                  title: 'DNI',
                  value: userData?['dni']?.toString().isNotEmpty == true 
                      ? userData!['dni'] 
                      : 'No registrado',
                ),
              ]),

              const SizedBox(height: 16),

              // App settings
              _buildSettingsSection('Aplicación', [
                _buildSettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notificaciones',
                  value: 'Activadas',
                ),
                _buildSettingsItem(
                  icon: Icons.language,
                  title: 'Idioma',
                  value: 'Español',
                ),
                _buildSettingsItem(
                  icon: Icons.info_outline,
                  title: 'Versión',
                  value: '1.0.0',
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows help screen
  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.help_outline, color: AppColors.primary),
                  SizedBox(width: 12),
                  Text(
                    'Ayuda',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildHelpItem(
                '¿Cómo participo en una cartilla?',
                'Ve a la sección "Cartillas" desde el menú inferior. Selecciona una cartilla activa y predice los resultados de los 14 partidos. Envía tus predicciones y recibirás un código de participación.',
                Icons.sports_soccer,
              ),
              _buildHelpItem(
                '¿Cómo gano?',
                'Si aciertas los 14 resultados, ¡ganas el pozo acumulado! Si hay varios ganadores, el premio se divide entre todos.',
                Icons.emoji_events,
              ),
              _buildHelpItem(
                '¿Cómo veo las transmisiones en vivo?',
                'En la pestaña "Live" de la pantalla principal puedes ver los partidos en vivo. Toca un partido para ver las transmisiones disponibles (video o radio).',
                Icons.live_tv,
              ),
              _buildHelpItem(
                '¿Cómo veo mis participaciones?',
                'Desde tu perfil, toca "Mis Cartillas" para ver todas tus participaciones, resultados y códigos de participación.',
                Icons.receipt_long,
              ),
              _buildHelpItem(
                '¿Necesito crear una cuenta?',
                'Sí, necesitas registrarte para participar en las cartillas. Puedes ver las transmisiones y partidos sin cuenta.',
                Icons.account_circle,
              ),
              _buildHelpItem(
                '¿Cómo contacto soporte?',
                'Si tienes algún problema, contacta al administrador del campeonato directamente.',
                Icons.support_agent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String question, String answer, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}