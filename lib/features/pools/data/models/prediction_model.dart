import '../../domain/entities/prediction_entity.dart';

/// Modelo de datos para Predicción
/// Serialización JSON para Firebase
class PredictionModel extends PredictionEntity {
  const PredictionModel({
    required super.id,
    required super.poolId,
    required super.userId,
    required super.userName,
    required super.predictedScore,
    required super.team1Score,
    required super.team2Score,
    required super.createdAt,
    super.isWinner,
  });

  /// Crear desde JSON (Firestore)
  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['id'] as String,
      poolId: json['poolId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      predictedScore: json['predictedScore'] as String,
      team1Score: json['team1Score'] as int,
      team2Score: json['team2Score'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isWinner: json['isWinner'] as bool? ?? false,
    );
  }

  /// Convertir a JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poolId': poolId,
      'userId': userId,
      'userName': userName,
      'predictedScore': predictedScore,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'createdAt': createdAt.toIso8601String(),
      'isWinner': isWinner,
    };
  }

  /// Crear copia con cambios
  PredictionModel copyWith({
    String? id,
    String? poolId,
    String? userId,
    String? userName,
    String? predictedScore,
    int? team1Score,
    int? team2Score,
    DateTime? createdAt,
    bool? isWinner,
  }) {
    return PredictionModel(
      id: id ?? this.id,
      poolId: poolId ?? this.poolId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      predictedScore: predictedScore ?? this.predictedScore,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      createdAt: createdAt ?? this.createdAt,
      isWinner: isWinner ?? this.isWinner,
    );
  }
}