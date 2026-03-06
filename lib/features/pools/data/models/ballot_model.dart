import '../../domain/entities/ballot_entity.dart';

class BallotModel extends BallotEntity {
  const BallotModel({
    required super.id,
    required super.prizePool,
    required super.entryFee,
    required super.deadline,
    required super.status,
    required super.createdAt,
    required super.matches,
    required super.participantCount,
    super.winnerIds,
    super.resolvedAt,
  });

  factory BallotModel.fromJson(Map<String, dynamic> json) {
    return BallotModel(
      id: json['id'] as String,
      prizePool: (json['prizePool'] as num).toDouble(),
      entryFee: (json['entryFee'] as num).toDouble(),
      deadline: DateTime.parse(json['deadline'] as String),
      status: BallotStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BallotStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      matches: (json['matches'] as List<dynamic>)
          .map((m) => BallotMatchModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      participantCount: json['participantCount'] as int,
      winnerIds: (json['winnerIds'] as List<dynamic>?)?.cast<String>(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prizePool': prizePool,
      'entryFee': entryFee,
      'deadline': deadline.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'matches': matches.map((m) => (m as BallotMatchModel).toJson()).toList(),
      'participantCount': participantCount,
      'winnerIds': winnerIds,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}

class BallotMatchModel extends BallotMatch {
  const BallotMatchModel({
    required super.matchId,
    required super.homeTeam,
    required super.awayTeam,
    required super.league,
    required super.startTime,
    super.finalResult,
  });

  factory BallotMatchModel.fromJson(Map<String, dynamic> json) {
    return BallotMatchModel(
      matchId: json['matchId'] as String,
      homeTeam: json['homeTeam'] as String,
      awayTeam: json['awayTeam'] as String,
      league: json['league'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      finalResult: json['finalResult'] != null
          ? MatchResult.values.firstWhere(
              (e) => e.name == json['finalResult'],
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'league': league,
      'startTime': startTime.toIso8601String(),
      'finalResult': finalResult?.name,
    };
  }
}