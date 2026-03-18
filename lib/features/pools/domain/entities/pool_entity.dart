/// Entidad de dominio para Pozo de Apuestas
/// Representa un pozo donde múltiples usuarios predicen el marcador exacto
class PoolEntity {
  final String id;
  final String eventId;
  final String eventName;
  final String team1;
  final String team2;
  final double entryFee;
  final double totalAmount;
  final int participantCount;
  final DateTime deadline;
  final PoolStatus status;
  final DateTime createdAt;
  final String? finalScore;
  final List<String>? winnerIds;
  final DateTime? resolvedAt;

  const PoolEntity({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.team1,
    required this.team2,
    required this.entryFee,
    required this.totalAmount,
    required this.participantCount,
    required this.deadline,
    required this.status,
    required this.createdAt,
    this.finalScore,
    this.winnerIds,
    this.resolvedAt,
  });

  bool get isActive => status == PoolStatus.active;
  bool get isFinished => status == PoolStatus.finished;
  bool get isCancelled => status == PoolStatus.cancelled;
  
  /// Tiempo restante hasta el deadline
  Duration get timeRemaining => deadline.difference(DateTime.now());
  
  /// Verifica si el deadline ha pasado
  bool get isExpired => DateTime.now().isAfter(deadline);
}

enum PoolStatus {
  active,    // Activo, aceptando participantes
  closed,    // Cerrado, esperando resultado
  finished,  // Finalizado con ganadores
  cancelled, // Cancelado
}