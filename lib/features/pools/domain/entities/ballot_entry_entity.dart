import 'package:marca_gol/features/pools/domain/entities/ballot_entity.dart';

/// Entrada/Participación de un usuario en la cartilla
class BallotEntryEntity {
  final String id;
  final String ballotId;
  final String userId;
  final String userName;
  final String participationCode; //codigo unico de participación
  final Map<String, MatchResult> predictions; // matchId
  final DateTime createdAt;
  final bool isWinner;
  final int correctPredictions; // Cuántos acertó

  const BallotEntryEntity({
    required this.id,
    required this.ballotId,
    required this.userId,
    required this.userName,
    required this.participationCode,
    required this.predictions,
    required this.createdAt,
    this.isWinner = false,
    this.correctPredictions = 0,
  });

  /// Verifica si acertó todos los 14
  bool get isPerfectScore => correctPredictions == 14;
}