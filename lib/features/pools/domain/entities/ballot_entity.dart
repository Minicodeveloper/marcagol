///entidad para cartilla de puestas 14 equipos
/// el usuario debe predecir 14 resultados para ganar el pozo
class BallotEntity {
  final String id;
  final double prizePool; //pozo acumulado (ej: S/ 1,000)
  final double entryFee; //costo de participación (ej: S/ 10)
  final DateTime deadline; //fecha límite para participar
  final BallotStatus status;
  final DateTime createdAt;
  final List<BallotMatch> matches; //14 partidos
  final int participantCount;
  final List<String>? winnerIds; //usuarios que acertaron los 14
  final DateTime? resolvedAt;

  const BallotEntity({
    required this.id,
    required this.prizePool,
    required this.entryFee,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.matches,
    required this.participantCount,
    this.winnerIds,
    this.resolvedAt,
  });

  /// Verifica si hay ganadores
  bool get hasWinners => winnerIds != null && winnerIds!.isNotEmpty;

  /// Calcula el premio por ganador si hay múltiples
  double get prizePerWinner {
    if (!hasWinners) return prizePool;
    return prizePool / winnerIds!.length;
  }
}

enum BallotStatus {
  active,    // Activo, aceptando participantes
  closed,    // Cerrado, esperando resultados
  finished,  // Finalizado con resultados
  cancelled, // Cancelado
}

/// Partido dentro de la cartilla
class BallotMatch {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final String league;
  final DateTime startTime;
  final MatchResult? finalResult; // null si aún no termina

  const BallotMatch({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.league,
    required this.startTime,
    this.finalResult,
  });
}

/// Resultado de un partido
enum MatchResult {
  home,  // Ganó local (1)
  draw,  // Empate (X)
  away,  // Ganó visitante (2)
}