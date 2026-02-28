import '../../domain/entities/bet_entity.dart';

/// Modelo de datos para Apuesta
/// Se usa para serialización JSON con Firebase
class BetModel extends BetEntity {
  const BetModel({
    required super.id,
    required super.creatorId,
    required super.creatorName,
    required super.eventId,
    required super.eventName,
    required super.betType,
    required super.amount,
    required super.status,
    required super.createdAt,
    required super.deadline,
    super.acceptorId,
    super.acceptorName,
    super.acceptedAt,
    super.winnerId,
    super.resolvedAt,
  });

  /// Crear desde JSON (Firestore)
  factory BetModel.fromJson(Map<String, dynamic> json) {
    return BetModel(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      betType: json['betType'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: BetStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BetStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      deadline: DateTime.parse(json['deadline'] as String),
      acceptorId: json['acceptorId'] as String?,
      acceptorName: json['acceptorName'] as String?,
      acceptedAt: json['acceptedAt'] != null 
          ? DateTime.parse(json['acceptedAt'] as String) 
          : null,
      winnerId: json['winnerId'] as String?,
      resolvedAt: json['resolvedAt'] != null 
          ? DateTime.parse(json['resolvedAt'] as String) 
          : null,
    );
  }

  /// Convertir a JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'eventId': eventId,
      'eventName': eventName,
      'betType': betType,
      'amount': amount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'acceptorId': acceptorId,
      'acceptorName': acceptorName,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'winnerId': winnerId,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  /// Crear copia con cambios
  BetModel copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? eventId,
    String? eventName,
    String? betType,
    double? amount,
    BetStatus? status,
    DateTime? createdAt,
    DateTime? deadline,
    String? acceptorId,
    String? acceptorName,
    DateTime? acceptedAt,
    String? winnerId,
    DateTime? resolvedAt,
  }) {
    return BetModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      betType: betType ?? this.betType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      acceptorId: acceptorId ?? this.acceptorId,
      acceptorName: acceptorName ?? this.acceptorName,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      winnerId: winnerId ?? this.winnerId,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}