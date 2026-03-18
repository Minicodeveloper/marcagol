import '../../domain/entities/pool_entity.dart';

/// Modelo de datos para Pozo de Apuestas
/// Serialización JSON para Firebase
class PoolModel extends PoolEntity {
  const PoolModel({
    required super.id,
    required super.eventId,
    required super.eventName,
    required super.team1,
    required super.team2,
    required super.entryFee,
    required super.totalAmount,
    required super.participantCount,
    required super.deadline,
    required super.status,
    required super.createdAt,
    super.finalScore,
    super.winnerIds,
    super.resolvedAt,
  });

  /// Crear desde JSON (Firestore)
  factory PoolModel.fromJson(Map<String, dynamic> json) {
    return PoolModel(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      team1: json['team1'] as String,
      team2: json['team2'] as String,
      entryFee: (json['entryFee'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      participantCount: json['participantCount'] as int,
      deadline: DateTime.parse(json['deadline'] as String),
      status: PoolStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PoolStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      finalScore: json['finalScore'] as String?,
      winnerIds: (json['winnerIds'] as List<dynamic>?)?.cast<String>(),
      resolvedAt: json['resolvedAt'] != null 
          ? DateTime.parse(json['resolvedAt'] as String) 
          : null,
    );
  }

  /// Convertir a JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventName': eventName,
      'team1': team1,
      'team2': team2,
      'entryFee': entryFee,
      'totalAmount': totalAmount,
      'participantCount': participantCount,
      'deadline': deadline.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'finalScore': finalScore,
      'winnerIds': winnerIds,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  /// Crear copia con cambios
  PoolModel copyWith({
    String? id,
    String? eventId,
    String? eventName,
    String? team1,
    String? team2,
    double? entryFee,
    double? totalAmount,
    int? participantCount,
    DateTime? deadline,
    PoolStatus? status,
    DateTime? createdAt,
    String? finalScore,
    List<String>? winnerIds,
    DateTime? resolvedAt,
  }) {
    return PoolModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      team1: team1 ?? this.team1,
      team2: team2 ?? this.team2,
      entryFee: entryFee ?? this.entryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      participantCount: participantCount ?? this.participantCount,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      finalScore: finalScore ?? this.finalScore,
      winnerIds: winnerIds ?? this.winnerIds,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}