import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';

class AdminBetsScreen extends ConsumerStatefulWidget {
  const AdminBetsScreen({super.key});

  @override
  ConsumerState<AdminBetsScreen> createState() => _AdminBetsScreenState();
}

class _AdminBetsScreenState extends ConsumerState<AdminBetsScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  final TextEditingController _whatsappCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadWhatsapp();
  }

  Future<void> _loadWhatsapp() async {
    final wp = await _firestoreService.getAdminWhatsapp();
    if (wp != null) _whatsappCtrl.text = wp;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allBets = ref.watch(allBetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Apuestas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _configureWhatsapp,
            tooltip: 'Configurar WhatsApp',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: '⏳ Pendientes'),
            Tab(text: '✅ Confirmadas'),
            Tab(text: '🏆 Ganadas'),
            Tab(text: '📋 Todas'),
          ],
        ),
      ),
      body: allBets.when(
        data: (bets) {
          final pending = bets.where((b) => b['status'] == 'pending_payment').toList();
          final confirmed = bets.where((b) => b['status'] == 'confirmed').toList();
          final won = bets.where((b) => b['status'] == 'won' || b['status'] == 'paid').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBetList(pending, 'pending'),
              _buildBetList(confirmed, 'confirmed'),
              _buildBetList(won, 'won'),
              _buildBetList(bets, 'all'),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBetList(List<Map<String, dynamic>> bets, String tab) {
    if (bets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.casino_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No hay apuestas en esta sección',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bets.length,
      itemBuilder: (context, index) => _buildBetCard(bets[index]),
    );
  }

  Widget _buildBetCard(Map<String, dynamic> bet) {
    final status = bet['status'] ?? 'pending_payment';
    final statusInfo = _getStatusInfo(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusInfo['color'].withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: user + status
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    (bet['userName'] ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bet['userName'] ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(bet['betCode'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const Divider(height: 24),
            // Match info
            Text(
              '${bet['homeTeam'] ?? ''} vs ${bet['awayTeam'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            // Bet details
            Row(
              children: [
                _buildDetailChip('Apuesta', bet['selectionLabel'] ?? '', AppColors.primary),
                const SizedBox(width: 8),
                _buildDetailChip('Cuota', 'x${(bet['odds'] ?? 0).toStringAsFixed(2)}', Colors.deepPurple),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildDetailChip('Monto', 'S/ ${(bet['amount'] ?? 0).toStringAsFixed(2)}', AppColors.adminOrange),
                const SizedBox(width: 8),
                _buildDetailChip('Ganancia', 'S/ ${(bet['potentialWinnings'] ?? 0).toStringAsFixed(2)}', AppColors.liveGreen),
              ],
            ),
            if (bet['userPhone'] != null && bet['userPhone'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('📱 ${bet['userPhone']}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            ],
            const SizedBox(height: 12),
            // Action buttons
            _buildActions(bet),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActions(Map<String, dynamic> bet) {
    final status = bet['status'] ?? 'pending_payment';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (status == 'pending_payment') ...[
          _actionButton('✅ Confirmar Pago', AppColors.liveGreen, () async {
            await _firestoreService.confirmBetPayment(bet['id']);
            _showSnack('Pago confirmado - Apuesta activada');
          }),
          _actionButton('❌ Rechazar', Colors.red, () async {
            await _firestoreService.cancelBet(bet['id']);
            _showSnack('Apuesta rechazada');
          }),
        ],
        if (status == 'confirmed') ...[
          _actionButton('🏆 Ganó', AppColors.liveGreen, () async {
            await _firestoreService.settleBet(bet['id'], true);
            _showSnack('Apuesta marcada como ganadora');
          }),
          _actionButton('❌ Perdió', Colors.red, () async {
            await _firestoreService.settleBet(bet['id'], false);
            _showSnack('Apuesta marcada como perdida');
          }),
        ],
        if (status == 'won')
          _actionButton('💰 Marcar Pagado', AppColors.liveGreen, () async {
            await _firestoreService.markBetPaid(bet['id']);
            _showSnack('Pago entregado al usuario');
          }),
        if (status == 'cancelled' || status == 'lost' || status == 'paid')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status == 'paid' ? '✅ Pagado' : status == 'lost' ? '❌ Perdida' : '🚫 Cancelada',
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
      ],
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending_payment': return {'label': '⏳ Pendiente de pago', 'color': Colors.orange};
      case 'confirmed': return {'label': '✅ Confirmada', 'color': AppColors.liveGreen};
      case 'won': return {'label': '🏆 Ganó', 'color': AppColors.liveGreen};
      case 'lost': return {'label': '❌ Perdió', 'color': Colors.red};
      case 'paid': return {'label': '💰 Pagada', 'color': Colors.blue};
      case 'cancelled': return {'label': '🚫 Cancelada', 'color': Colors.grey};
      default: return {'label': status, 'color': Colors.grey};
    }
  }

  void _configureWhatsapp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('WhatsApp de contacto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Los usuarios usarán este número para contactarte y coordinar el pago de apuestas.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _whatsappCtrl,
              decoration: const InputDecoration(
                labelText: 'Número de WhatsApp',
                hintText: '+51 999999999',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (_whatsappCtrl.text.trim().isEmpty) return;
              await _firestoreService.updateAdminWhatsapp(_whatsappCtrl.text.trim());
              if (mounted) {
                Navigator.pop(ctx);
                _showSnack('WhatsApp actualizado');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
