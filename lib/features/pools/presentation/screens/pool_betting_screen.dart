import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/pool_card.dart';
import 'pool_detail_screen.dart';
import 'create_pool_screen.dart';

class PoolBettingScreen extends StatelessWidget {
  const PoolBettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cartillas'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Ver historial
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card explicativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo jugar?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Predice 14 resultados y gana el pozo',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cartillas activas
          PoolCard(
            id: 'CART-001',
            event: 'Cartilla Fin de Semana',
            totalAmount: 'S/ 1,250.00',
            participants: 23,
            timeLeft: '2d 5h',
            isActive: true,
            onTap: () => _navigateToDetail(context, 'CART-001'),
          ),

          PoolCard(
            id: 'CART-002',
            event: 'Cartilla Semanal',
            totalAmount: 'S/ 3,800.00',
            participants: 67,
            timeLeft: '5d 12h',
            isActive: true,
            onTap: () => _navigateToDetail(context, 'CART-002'),
          ),

          PoolCard(
            id: 'CART-003',
            event: 'Cartilla del Mes',
            totalAmount: 'S/ 890.00',
            participants: 15,
            timeLeft: 'FINALIZADO',
            isActive: false,
            onTap: () => _navigateToDetail(context, 'CART-003'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePoolScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cartilla'),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String poolId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoolDetailScreen(poolId: poolId),
      ),
    );
  }
}