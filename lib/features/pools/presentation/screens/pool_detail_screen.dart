import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/firestore_service.dart';

class PoolDetailScreen extends ConsumerStatefulWidget {
  final String ballotId;

  const PoolDetailScreen({super.key, required this.ballotId});

  @override
  ConsumerState<PoolDetailScreen> createState() => _PoolDetailScreenState();
}

class _PoolDetailScreenState extends ConsumerState<PoolDetailScreen> {
  final Map<String, String> _predictions = {};
  // For score mode: each key maps to "homeScore-awayScore"
  final Map<String, TextEditingController> _homeScoreControllers = {};
  final Map<String, TextEditingController> _awayScoreControllers = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final c in _homeScoreControllers.values) {
      c.dispose();
    }
    for (final c in _awayScoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ballotAsync = ref.watch(ballotByIdProvider(widget.ballotId));

    return ballotAsync.when(
      data: (ballot) {
        if (ballot == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Cartilla')),
            body: const Center(child: Text('Cartilla no encontrada')),
          );
        }

        final matches = List<Map<String, dynamic>>.from(ballot['matches'] ?? []);
        final mode = ballot['mode'] ?? 'result';
        final prizePool = (ballot['prizePool'] as num?)?.toDouble() ?? 0;
        final title = ballot['title'] ?? 'Cartilla';
        final totalMatches = matches.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _predictions.length == totalMatches ? Colors.green : AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_predictions.length}/$totalMatches',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Promo banner
                _buildPromoBanner(title),
                _buildHowToWinButton(mode),
                _buildPrizeSection(prizePool),

                // Mode indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: AppColors.accent.withValues(alpha: 0.1),
                  child: Text(
                    mode == 'result'
                        ? '📋 Modalidad: Por Resultado (Local / Empate / Visita)'
                        : '⚽ Modalidad: Por Marcador Exacto',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Table header
                if (mode == 'result') _buildResultTableHeader(),

                // Matches list
                _buildMatchesList(matches, mode),

                // Submit button
                _buildSubmitButton(mode, totalMatches),

                const SizedBox(height: 100),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPromoBanner(String title) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.orangeGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '¡DEMUESTRA QUE ERES EL QUE MÁS SABE DE FÚTBOL!',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(height: 8),
                const Text(
                  '¡GANA EL GRAN POZO ACUMULADO!',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_soccer, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToWinButton(String mode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () => _showHowToWinDialog(mode),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('¿Cómo Ganar?',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPrizeSection(double prizePool) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.monetization_on, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text('¡GANA EL MONTO DE',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          Text(
            'S/ ${prizePool.toStringAsFixed(0)}!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC0032),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTableHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Container()),
          Expanded(child: _buildHeaderCell('LOCAL')),
          Expanded(child: _buildHeaderCell('EMPATE')),
          Expanded(child: _buildHeaderCell('VISITA')),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Center(
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMatchesList(List<Map<String, dynamic>> matches, String mode) {
    return Column(
      children: List.generate(matches.length, (index) {
        final match = matches[index];
        final key = '$index';
        final prediction = _predictions[key];

        if (mode == 'result') {
          return _buildResultMatchRow(match, index, key, prediction);
        } else {
          return _buildScoreMatchRow(match, index, key);
        }
      }),
    );
  }

  Widget _buildResultMatchRow(Map<String, dynamic> match, int index, String key, String? prediction) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: prediction != null ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
          width: prediction != null ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: prediction != null ? AppColors.primary : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match['homeTeam'] ?? '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'vs ${match['awayTeam'] ?? ''}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(child: _buildCheckbox(key, 'LOCAL', prediction)),
          Expanded(child: _buildCheckbox(key, 'EMPATE', prediction)),
          Expanded(child: _buildCheckbox(key, 'VISITA', prediction)),
        ],
      ),
    );
  }

  Widget _buildScoreMatchRow(Map<String, dynamic> match, int index, String key) {
    _homeScoreControllers.putIfAbsent(key, () => TextEditingController());
    _awayScoreControllers.putIfAbsent(key, () => TextEditingController());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _predictions.containsKey(key) ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
          width: _predictions.containsKey(key) ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _predictions.containsKey(key) ? AppColors.primary : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              match['homeTeam'] ?? '',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 40,
            height: 36,
            child: TextField(
              controller: _homeScoreControllers[key],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0',
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onChanged: (v) => _updateScorePrediction(key),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 40,
            height: 36,
            child: TextField(
              controller: _awayScoreControllers[key],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0',
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onChanged: (v) => _updateScorePrediction(key),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              match['awayTeam'] ?? '',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _updateScorePrediction(String key) {
    final home = _homeScoreControllers[key]?.text ?? '';
    final away = _awayScoreControllers[key]?.text ?? '';
    if (home.isNotEmpty && away.isNotEmpty) {
      setState(() {
        _predictions[key] = '$home-$away';
      });
    } else {
      setState(() {
        _predictions.remove(key);
      });
    }
  }

  Widget _buildCheckbox(String key, String option, String? currentPrediction) {
    final isSelected = currentPrediction == option;

    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _predictions[key] = option;
          });
        },
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isSelected
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String mode, int totalMatches) {
    final isComplete = _predictions.length == totalMatches;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: isComplete && !_isSubmitting ? () => _submitBallot(mode) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete ? AppColors.primary : Colors.grey[400],
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                isComplete ? 'ENVIAR CARTILLA' : 'COMPLETA LOS $totalMatches (${_predictions.length}/$totalMatches)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _submitBallot(String mode) async {
    setState(() => _isSubmitting = true);
    
    try {
      final service = FirestoreService();
      final code = await service.submitBallotEntry(
        ballotId: widget.ballotId,
        predictions: _predictions,
        mode: mode,
      );
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('✅ ¡Cartilla Confirmada!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tu cartilla ha sido registrada exitosamente.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text('Código de Participación', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        code,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('¡Listo!'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showHowToWinDialog(String mode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Cómo Ganar?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mode == 'result') ...[
                const Text('1. Marca LOCAL, EMPATE o VISITA para cada partido', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                const Text('2. Debes completar los 14 partidos', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                const Text('3. Si aciertas los 14 resultados, ¡ganas el pozo!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ] else ...[
                const Text('1. Ingresa el marcador exacto de cada partido', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                const Text('2. Debes completar los 14 marcadores', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                const Text('3. Si aciertas los 14 marcadores, ¡ganas el pozo!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
              const SizedBox(height: 12),
              const Text('4. Si hay varios ganadores, el pozo se divide entre todos', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}