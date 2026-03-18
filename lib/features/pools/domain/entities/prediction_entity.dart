/// Entidad de dominio para Predicción de usuario en un pozo
class PredictionEntity {
  final String id;
  final String poolId;
  final String userId;
  final String userName;
  final String predictedScore; // Formato: "2-1"
  final int team1Score;
  final int team2Score;
  final DateTime createdAt;
  final bool isWinner;

  const PredictionEntity({
    required this.id,
    required this.poolId,
    required this.userId,
    required this.userName,
    required this.predictedScore,
    required this.team1Score,
    required this.team2Score,
    required this.createdAt,
    this.isWinner = false,
  });

  /// Verifica si la predicción coincide con un marcador
  bool matchesScore(String actualScore) {
    return predictedScore == actualScore;
  }
}