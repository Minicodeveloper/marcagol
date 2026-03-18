import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';

class PlaceBetScreen extends ConsumerStatefulWidget {
  final String championshipId;
  final Map<String, dynamic> matchData;

  const PlaceBetScreen({
    super.key,
    required this.championshipId,
    required this.matchData,
  });

  @override
  ConsumerState<PlaceBetScreen> createState() => _PlaceBetScreenState();
}

class _PlaceBetScreenState extends ConsumerState<PlaceBetScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _amountCtrl = TextEditingController();
  String? _selectedOption;
  double _selectedOdds = 0;
  bool _isPlacing = false;

  Map<String, dynamic> get _odds {
    return Map<String, dynamic>.from(widget.matchData['bettingOdds'] ?? {});
  }

  String get _homeTeam => widget.matchData['homeTeam'] ?? 'Local';
  String get _awayTeam => widget.matchData['awayTeam'] ?? 'Visita';

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final customOptions = List<Map<String, dynamic>>.from(_odds['customOptions'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apostar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Match Header
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('PARTIDO', style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Text(
                            _homeTeam,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        Expanded(
                          child: Text(
                            _awayTeam,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Betting Options
            const Text('Selecciona tu apuesta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Standard options (homeWin, draw, awayWin)
            if (_odds['homeWin'] != null)
              _buildOddsOption(
                'homeWin',
                'Gana $_homeTeam',
                (_odds['homeWin'] as num).toDouble(),
                Icons.chevron_left,
                AppColors.primary,
              ),
            if (_odds['draw'] != null)
              _buildOddsOption(
                'draw',
                'Empate',
                (_odds['draw'] as num).toDouble(),
                Icons.balance,
                Colors.orange,
              ),
            if (_odds['awayWin'] != null)
              _buildOddsOption(
                'awayWin',
                'Gana $_awayTeam',
                (_odds['awayWin'] as num).toDouble(),
                Icons.chevron_right,
                Colors.blue,
              ),

            // Custom options
            ...customOptions.map((opt) => _buildOddsOption(
              'custom:${opt['label']}',
              opt['label'] ?? '',
              (opt['odds'] as num?)?.toDouble() ?? 1.0,
              Icons.star_outline,
              Colors.deepPurple,
            )),

            const SizedBox(height: 24),

            // Amount Input
            const Text('¿Cuánto quieres apostar?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto (S/)',
                hintText: 'Ej: 10.00',
                prefixIcon: const Icon(Icons.monetization_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (_) => setState(() {}),
            ),

            // Potential winnings preview
            if (_selectedOption != null && _amountCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.liveGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.liveGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: AppColors.liveGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ganancia potencial', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            'S/ ${_calculateWinnings().toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.liveGreen),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'x${_selectedOdds.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.liveGreen),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Place Bet Button
            Container(
              decoration: BoxDecoration(
                gradient: (_selectedOption != null && _amountCtrl.text.isNotEmpty && isLoggedIn)
                    ? AppColors.orangeGradient
                    : null,
                color: (_selectedOption == null || _amountCtrl.text.isEmpty || !isLoggedIn)
                    ? Colors.grey[300]
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: (_selectedOption != null && _amountCtrl.text.isNotEmpty && !_isPlacing && isLoggedIn)
                    ? _placeBet
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.transparent,
                  disabledForegroundColor: Colors.grey,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isPlacing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isLoggedIn ? 'REALIZAR APUESTA' : 'INICIA SESIÓN PARA APOSTAR',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Info text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('¿Cómo funciona?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('1. Selecciona tu opción y monto', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('2. Envía tu apuesta', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('3. Contacta al admin por WhatsApp para pagar', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('4. El admin confirma tu pago y activa la apuesta', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('5. Si ganas, el admin te paga directamente', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOddsOption(String key, String label, double odds, IconData icon, Color color) {
    final isSelected = _selectedOption == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOption = key;
          _selectedOdds = odds;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x${odds.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateWinnings() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    return amount * _selectedOdds;
  }

  Future<void> _placeBet() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }

    setState(() => _isPlacing = true);

    try {
      final betCode = await _firestoreService.placeBet(
        championshipId: widget.championshipId,
        matchId: widget.matchData['id'],
        homeTeam: _homeTeam,
        awayTeam: _awayTeam,
        selection: _selectedOption!,
        odds: _selectedOdds,
        amount: amount,
      );

      if (!mounted) return;

      // Show success dialog with WhatsApp option
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.liveGreen, size: 28),
              SizedBox(width: 8),
              Text('¡Apuesta Registrada!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('Tu código de apuesta:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(betCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Para activar tu apuesta, contacta al administrador por WhatsApp y realiza el pago.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                '⚠️ Tu apuesta no es válida hasta que el admin confirme el pago.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                Navigator.pop(context);
                await _contactAdmin(betCode, amount);
              },
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Contactar por WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  Future<void> _contactAdmin(String betCode, double amount) async {
    final adminWp = await _firestoreService.getAdminWhatsapp();
    if (adminWp == null || adminWp.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El administrador no ha configurado su WhatsApp')),
        );
      }
      return;
    }

    // Clean phone number  
    final cleanPhone = adminWp.replaceAll(RegExp(r'[^0-9+]'), '');
    final selectionLabel = _getLabel();
    final msg = Uri.encodeComponent(
      '🎰 *APUESTA - Marca Gol*\n\n'
      '📋 Código: *$betCode*\n'
      '⚽ Partido: $_homeTeam vs $_awayTeam\n'
      '🎯 Apuesta: *$selectionLabel*\n'
      '💰 Monto: *S/ ${amount.toStringAsFixed(2)}*\n'
      '📊 Cuota: *x${_selectedOdds.toStringAsFixed(2)}*\n'
      '🏆 Ganancia potencial: *S/ ${_calculateWinnings().toStringAsFixed(2)}*\n\n'
      'Quiero confirmar mi apuesta. ¿Cómo puedo pagar?'
    );

    final url = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _getLabel() {
    if (_selectedOption == 'homeWin') return 'Gana $_homeTeam';
    if (_selectedOption == 'draw') return 'Empate';
    if (_selectedOption == 'awayWin') return 'Gana $_awayTeam';
    if (_selectedOption != null && _selectedOption!.startsWith('custom:')) {
      return _selectedOption!.substring(7);
    }
    return _selectedOption ?? '';
  }
}
