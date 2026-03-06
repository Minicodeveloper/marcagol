import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../radio/presentation/screens/radio_screen.dart';
import 'live_stream_card.dart';
import 'previous_match_card.dart';

class LiveTabContent extends StatefulWidget {
  const LiveTabContent({super.key});

  @override
  State<LiveTabContent> createState() => _LiveTabContentState();
}

class _LiveTabContentState extends State<LiveTabContent> {
  String _selectedButton = 'Transmisión'; // ← ESTADO PARA BOTÓN SELECCIONADO

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // BOTONES: Transmisión y Radio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickButton(
                  context,
                  Icons.live_tv,
                  'Transmisión',
                  _selectedButton == 'Transmisión',
                  () {
                    setState(() {
                      _selectedButton = 'Transmisión';
                    });
                  },
                ),
                const SizedBox(width: 16),
                _buildQuickButton(
                  context,
                  Icons.radio,
                  'Radio',
                  _selectedButton == 'Radio',
                  () {
                    setState(() {
                      _selectedButton = 'Radio';
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RadioScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'transmisiones en vivo',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 12),

          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LiveStreamCard(),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Partidos anteriores',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          const SizedBox(height: 12),

          const PreviousMatchCard(
            homeTeam: 'I.E SJCH Cayetano',
            awayTeam: 'Estudiantes Ntra. Señora Jesús',
            homeScore: 2,
            awayScore: 1,
            isLive: true,
          ),

          const PreviousMatchCard(
            homeTeam: 'I.E.I Nuestro Jesús Campeón',
            awayTeam: 'Institución Educativa Estatal',
            homeScore: 0,
            awayScore: 1,
            isLive: true,
          ),

          const PreviousMatchCard(
            homeTeam: 'Deportivo Llacuabamba',
            awayTeam: 'Cultural Santa Rosa',
            homeScore: 3,
            awayScore: 2,
            isLive: false,
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected, // ← NUEVO PARÁMETRO
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface, // ← CAMBIO DE COLOR
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : AppColors.textPrimary, // ← CAMBIO DE COLOR
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary, // ← CAMBIO DE COLOR
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}