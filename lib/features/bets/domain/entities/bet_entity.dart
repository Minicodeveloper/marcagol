/// Entidad de dominio para Apuesta P2P
/// Representa una apuesta entre dos usuarios
class BetEntity {
  final String id;
  final String creatorId;
  final String creatorName;
  final String eventId;
  final String eventName;
  final String betType;
  final double amount;
  final BetStatus status;
  final DateTime createdAt;
  final DateTime deadline;
  final String? acceptorId;
  final String? acceptorName;
  final DateTime? acceptedAt;
  final String? winnerId;
  final DateTime? resolvedAt;

  const BetEntity({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.eventId,
    required this.eventName,
    required this.betType,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.deadline,
    this.acceptorId,
    this.acceptorName,
    this.acceptedAt,
    this.winnerId,
    this.resolvedAt,
  });

  bool get isPending => status == BetStatus.pending;
  bool get isAccepted => status == BetStatus.accepted;
  bool get isFinished => status == BetStatus.finished;
  bool get isCancelled => status == BetStatus.cancelled;
}

enum BetStatus {
  pending,    // Esperando aceptación
  accepted,   // Aceptada, esperando resultado
  finished,   // Finalizada con ganador
  cancelled,  // Cancelada
}