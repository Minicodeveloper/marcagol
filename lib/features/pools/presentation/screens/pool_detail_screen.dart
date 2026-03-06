import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PoolDetailScreen extends StatefulWidget {
  final String poolId;

  const PoolDetailScreen({super.key, required this.poolId});

  @override
  State<PoolDetailScreen> createState() => _PoolDetailScreenState();
}

class _PoolDetailScreenState extends State<PoolDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final Map<int, String> _predictions = {};

  final List<Map<String, String>> _matches = [
    {'home': 'I.E.I Santos Toribio', 'away': 'Equipo A'},
    {'home': 'Mencuri F.C.', 'away': 'Equipo B'},
    {'home': 'I.E. María Natividad', 'away': 'Equipo C'},
    {'home': 'I.E. Nueva Cultura', 'away': 'Equipo D'},
    {'home': 'I.E. Rosado Benito', 'away': 'Equipo E'},
    {'home': 'Deportivo Unidos', 'away': 'Equipo F'},
    {'home': 'Alianza FC', 'away': 'Equipo G'},
    {'home': 'Sport Chavelines', 'away': 'Equipo H'},
    {'home': 'Real Academia', 'away': 'Equipo I'},
    {'home': 'Los Tigres', 'away': 'Equipo J'},
    {'home': 'Juventud FC', 'away': 'Equipo K'},
    {'home': 'Cultural Andino', 'away': 'Equipo L'},
    {'home': 'Unión Deportiva', 'away': 'Equipo M'},
    {'home': 'Sporting Club', 'away': 'Equipo N'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'MG',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'MARCA GOL',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _predictions.length == 14 ? Colors.green : AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_predictions.length}/14',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView( // ← SCROLL COMPLETO
        child: Column(
          children: [
            _buildPromoBanner(),
            _buildHowToWinButton(),
            _buildPrizeSection(),

            // Tabs
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Marcar'),
                  Tab(text: 'Por números'),
                ],
              ),
            ),

            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'MG',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MARCA GOL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Headers
            _buildTableHeader(),

            // Lista de 14 equipos
            _buildMatchesList(),

            // Botón Enviar
            _buildSubmitButton(),

            const SizedBox(height: 24),

            // NUEVA SECCIÓN: Detalle de partidos por liga
            _buildMatchDetailsByLeague(),

            const SizedBox(height: 100), // Espacio al final
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC0032), Color(0xFF8B0020)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '¡PARTICIPA EN NUESTRA CARTILLA GRATUITA!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '¡DEMUESTRA QUE ERES EL QUE MÁS SABE DE FÚTBOL!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 8),
                Text(
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
          // TODO: Reemplazar con imagen real
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToWinButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _showHowToWinDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          '¿Cómo Ganar?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // TODO: Reemplazar con imagen real de monedas
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.monetization_on,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '¡GANA EL MONTO DE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Text(
            '500 SOLES!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC0032),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Container(),
          ),
          Expanded(
            child: _buildHeaderCell('LOCAL'),
          ),
          Expanded(
            child: _buildHeaderCell('EMPATE'),
          ),
          Expanded(
            child: _buildHeaderCell('VISITA'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    return Column(
      children: List.generate(_matches.length, (index) {
        final match = _matches[index];
        final prediction = _predictions[index];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: prediction != null ? AppColors.primary : Colors.grey.withOpacity(0.3),
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
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  match['home']!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: _buildCheckbox(index, 'LOCAL', prediction),
              ),
              Expanded(
                child: _buildCheckbox(index, 'EMPATE', prediction),
              ),
              Expanded(
                child: _buildCheckbox(index, 'VISITA', prediction),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCheckbox(int index, String option, String? currentPrediction) {
    final isSelected = currentPrediction == option;

    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _predictions[index] = option;
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
              ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isComplete = _predictions.length == 14;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: isComplete ? _submitBallot : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isComplete ? AppColors.primary : Colors.grey[400],
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          isComplete ? 'Enviar' : 'COMPLETA LOS 14 (${_predictions.length}/14)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============ NUEVA SECCIÓN: DETALLE DE PARTIDOS ============
  Widget _buildMatchDetailsByLeague() {
    return Column(
      children: [
        // Banner "DETALLE DE LOS PARTIDOS POR LIGA"
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDC0032), Color(0xFF8B0020)],
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Stack(
            children: [
              // TODO: Agregar imagen de fondo (patron diagonal)
              Center(
                child: Column(
                  children: const [
                    Text(
                      'DETALLE DE LOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      'PARTIDOS POR LIGA',
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ELIMINATORIA 2026
        _buildLeagueSection(
          'ELIMINATORIA 2026',
          [
            {'home': 'Ancile De', 'away': 'Seco Oliveros'},
            {'home': 'El Buen Pastor', 'away': 'Colegio Aleph'},
            {'home': 'Innova Schools', 'away': 'I.E. Rosa Merino'},
            {'home': 'Colegio Guadalupe', 'away': 'I.E. Rosa Merino'},
          ],
        ),

        const SizedBox(height: 24),

        // ELIMINATORIA 2024
        _buildLeagueSection(
          'ELIMINATORIA 2024',
          [
            {'home': 'Ancile De', 'away': 'Seco Oliveros'},
            {'home': 'El Buen Pastor', 'away': 'Colegio Aleph'},
            {'home': 'Innova Schools', 'away': 'I.E. Rosa Merino'},
            {'home': 'Colegio Guadalupe', 'away': 'I.E. Rosa Merino'},
          ],
        ),

        const SizedBox(height: 24),

        // Puedes agregar más eliminatorias aquí
      ],
    );
  }

  Widget _buildLeagueSection(String leagueName, List<Map<String, String>> matches) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la liga
          Text(
            leagueName,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Lista de partidos
          ...matches.map((match) => _buildMatchDetail(match)).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchDetail(Map<String, String> match) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              match['home']!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'VS',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              match['away']!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _submitBallot() {
    final code = 'CART-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('✅ ¡Cartilla Confirmada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu cartilla ha sido registrada exitosamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Código de Participación',
                    style: TextStyle(fontSize: 12),
                  ),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  void _showHowToWinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Cómo Ganar?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Selecciona el resultado de los 14 partidos', style: TextStyle(fontSize: 13)),
              SizedBox(height: 8),
              Text('2. Marca LOCAL, EMPATE o VISITA para cada partido', style: TextStyle(fontSize: 13)),
              SizedBox(height: 8),
              Text('3. Confirma tu cartilla antes del cierre', style: TextStyle(fontSize: 13)),
              SizedBox(height: 8),
              Text(
                '4. ¡Si aciertas los 14 resultados, ganas el pozo completo!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}