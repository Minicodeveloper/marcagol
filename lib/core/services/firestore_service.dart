import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // ============================================================
  // UTILIDADES
  // ============================================================

  /// Hash SHA-256 de una contraseña
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ============================================================
  // AUTENTICACIÓN contra colección 'users'
  // ============================================================

  /// Login: busca en colección 'users' por email y compara hash
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No existe una cuenta con este correo');
    }

    final userDoc = query.docs.first;
    final userData = userDoc.data();
    final storedHash = userData['passwordHash'] as String? ?? '';

    final inputHash = hashPassword(password);

    if (storedHash != inputHash) {
      throw Exception('Contraseña incorrecta');
    }

    // Guardar sesión localmente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUserId', userDoc.id);

    return {'uid': userDoc.id, ...userData};
  }

  /// Registrar usuario nuevo en la colección 'users'
  Future<String> registerUser({
    required String email,
    required String password,
    required String displayName,
    String role = 'client',
    String? dni,
    String? phone,
  }) async {
    // Verificar que no exista
    final existing = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Ya existe una cuenta con este correo');
    }

    final doc = _firestore.collection('users').doc();
    await doc.set({
      'email': email.trim().toLowerCase(),
      'displayName': displayName,
      'passwordHash': hashPassword(password),
      'role': role,
      'dni': dni ?? '',
      'phone': phone ?? '',
      'balance': 0,
      'isVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Auto-login después de registrar
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUserId', doc.id);

    return doc.id;
  }

  /// Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUserId');
  }

  /// Obtener ID del usuario logueado (de SharedPreferences)
  static Future<String?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loggedInUserId');
  }

  /// Obtener datos del usuario logueado desde Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final userId = await getLoggedInUserId();
    if (userId == null) return null;
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? {'uid': userId, ...doc.data()!} : null;
  }

  /// Stream de datos del usuario logueado
  Stream<Map<String, dynamic>?> currentUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? {'uid': doc.id, ...doc.data()!} : null);
  }

  // ============================================================
  // CAMPEONATOS
  // ============================================================

  Future<String> createChampionship({
    required String name,
    required String description,
    required int totalMatches,
    String? imageUrl,
  }) async {
    final doc = _firestore.collection('championships').doc();
    await doc.set({
      'name': name,
      'description': description,
      'totalMatches': totalMatches,
      'imageUrl': imageUrl,
      'status': 'active',
      'isActive': true,
      'isVisible': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> toggleChampionshipVisibility(String championshipId, bool isVisible) async {
    await _firestore.collection('championships').doc(championshipId).update({
      'isVisible': isVisible,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActiveChampionship(String championshipId) async {
    final batch = _firestore.batch();
    final all = await _firestore.collection('championships')
        .where('isActive', isEqualTo: true)
        .get();
    for (final doc in all.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    batch.update(
      _firestore.collection('championships').doc(championshipId),
      {'isActive': true, 'status': 'active'},
    );
    await batch.commit();
  }

  Future<void> finishChampionship(String championshipId) async {
    await _firestore.collection('championships').doc(championshipId).update({
      'status': 'finished',
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChampionship(String championshipId) async {
    await _firestore.collection('championships').doc(championshipId).delete();
  }

  // ============================================================
  // PARTIDOS
  // ============================================================

  Future<String> addMatch({
    required String championshipId,
    required String homeTeam,
    required String awayTeam,
    required String league,
    required int matchNumber,
    required DateTime startTime,
    String? location,
  }) async {
    final doc = _firestore
        .collection('championships')
        .doc(championshipId)
        .collection('matches')
        .doc();
    await doc.set({
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'league': league,
      'matchNumber': matchNumber,
      'startTime': Timestamp.fromDate(startTime),
      'location': location,
      'homeScore': null,
      'awayScore': null,
      'status': 'scheduled', // scheduled, live, finished
      'timerState': {
        'status': 'scheduled', // scheduled, playing, paused, finished
        'period': '1H', // 1H, HT, 2H, E1, E2, PEN, FT
        'periodStartTime': null,
        'accumulatedMinutes': 0,
      },
      'penaltiesScore': {
        'home': 0,
        'away': 0,
      },
      'goals': [], // { scorer, minute, team (home|away), period }
      'streams': [], // { title, url, type (video|radio) }
      'bettingOdds': null, // { homeWin: 1.5, draw: 3.0, awayWin: 2.0, customOptions: [...] }
      'bettingEnabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateMatchResult({
    required String championshipId,
    required String matchId,
    required int homeScore,
    required int awayScore,
    String status = 'finished',
  }) async {
    await _firestore
        .collection('championships')
        .doc(championshipId)
        .collection('matches')
        .doc(matchId)
        .update({
      'homeScore': homeScore,
      'awayScore': awayScore,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMatchStatus({
    required String championshipId,
    required String matchId,
    required String status,
  }) async {
    await _firestore
        .collection('championships')
        .doc(championshipId)
        .collection('matches')
        .doc(matchId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMatchTimer({
    required String championshipId,
    required String matchId,
    required Map<String, dynamic> timerState,
  }) async {
    await _firestore
        .collection('championships')
        .doc(championshipId)
        .collection('matches')
        .doc(matchId)
        .update({
      'timerState': timerState,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMatchPenalties({
    required String championshipId,
    required String matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    await _firestore
        .collection('championships')
        .doc(championshipId)
        .collection('matches')
        .doc(matchId)
        .update({
      'penaltiesScore': {
        'home': homeScore,
        'away': awayScore,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMatchGoals({
    required String championshipId,
    required String matchId,
    required List<Map<String, dynamic>> goals,
  }) async {
    await _firestore
        .collection('championships')
        .doc(championshipId)
        .collection('matches')
        .doc(matchId)
        .update({
      'goals': goals,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMatchStreams({
    required String championshipId,
    required String matchId,
    required List<Map<String, dynamic>> streams,
  }) async {
    await _firestore
        .collection('championships')
        .doc(championshipId)
        .collection('matches')
        .doc(matchId)
        .update({
      'streams': streams,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // APUESTAS (BETTING)
  // ============================================================

  /// Admin: configurar cuotas de apuestas para un partido
  Future<void> updateMatchBettingOdds({
    required String championshipId,
    required String matchId,
    required Map<String, dynamic> bettingOdds,
    required bool bettingEnabled,
  }) async {
    await _firestore
        .collection('championships')
        .doc(championshipId)
        .collection('matches')
        .doc(matchId)
        .update({
      'bettingOdds': bettingOdds,
      'bettingEnabled': bettingEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Usuario: colocar una apuesta
  Future<String> placeBet({
    required String championshipId,
    required String matchId,
    required String homeTeam,
    required String awayTeam,
    required String selection, // homeWin, draw, awayWin, custom:label
    required double odds,
    required double amount,
  }) async {
    final userId = await getLoggedInUserId();
    if (userId == null) throw Exception('Debes iniciar sesión');

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['displayName'] ?? 'Usuario';
    final userPhone = userDoc.data()?['phone'] ?? '';

    final betCode = 'BET-${_uuid.v4().substring(0, 6).toUpperCase()}';

    final doc = _firestore.collection('bets').doc();
    await doc.set({
      'championshipId': championshipId,
      'matchId': matchId,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'betCode': betCode,
      'selection': selection,
      'selectionLabel': _getSelectionLabel(selection, homeTeam, awayTeam),
      'odds': odds,
      'amount': amount,
      'potentialWinnings': (amount * odds),
      // Status flow: pending_payment → confirmed → won/lost → paid
      'status': 'pending_payment',
      'paymentConfirmed': false,
      'resultSettled': false,
      'payoutDelivered': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return betCode;
  }

  String _getSelectionLabel(String selection, String homeTeam, String awayTeam) {
    switch (selection) {
      case 'homeWin': return 'Gana $homeTeam';
      case 'draw': return 'Empate';
      case 'awayWin': return 'Gana $awayTeam';
      default:
        if (selection.startsWith('custom:')) {
          return selection.substring(7);
        }
        return selection;
    }
  }

  /// Admin: confirmar pago recibido (activar apuesta)
  Future<void> confirmBetPayment(String betId) async {
    await _firestore.collection('bets').doc(betId).update({
      'status': 'confirmed',
      'paymentConfirmed': true,
      'paymentConfirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: marcar apuesta como ganadora o perdedora
  Future<void> settleBet(String betId, bool isWinner) async {
    await _firestore.collection('bets').doc(betId).update({
      'status': isWinner ? 'won' : 'lost',
      'resultSettled': true,
      'isWinner': isWinner,
      'settledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: marcar pago entregado al ganador
  Future<void> markBetPaid(String betId) async {
    await _firestore.collection('bets').doc(betId).update({
      'status': 'paid',
      'payoutDelivered': true,
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: cancelar/rechazar apuesta
  Future<void> cancelBet(String betId) async {
    await _firestore.collection('bets').doc(betId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin: guardar/obtener WhatsApp
  Future<void> updateAdminWhatsapp(String whatsapp) async {
    await _firestore.collection('config').doc('admin').set({
      'whatsapp': whatsapp,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> getAdminWhatsapp() async {
    final doc = await _firestore.collection('config').doc('admin').get();
    return doc.data()?['whatsapp'];
  }

  // ============================================================
  // TRANSMISIONES
  // ============================================================

  Future<String> createVideoStream({
    required String title,
    required String youtubeUrl,
    String? description,
    String? championshipId,
    String? matchId,
  }) async {
    final doc = _firestore.collection('streams').doc();
    await doc.set({
      'title': title,
      'youtubeUrl': youtubeUrl,
      'description': description,
      'championshipId': championshipId,
      'matchId': matchId,
      'type': 'video',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> createRadioStream({
    required String title,
    required String streamUrl,
    String? description,
    double? frequency,
    String? championshipId,
    String? matchId,
  }) async {
    final doc = _firestore.collection('streams').doc();
    await doc.set({
      'title': title,
      'streamUrl': streamUrl,
      'description': description,
      'frequency': frequency,
      'championshipId': championshipId,
      'matchId': matchId,
      'type': 'radio',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateStream(String streamId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('streams').doc(streamId).update(data);
  }

  Future<void> toggleStreamActive(String streamId, bool isActive) async {
    await _firestore.collection('streams').doc(streamId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStream(String streamId) async {
    await _firestore.collection('streams').doc(streamId).delete();
  }

  // ============================================================
  // CARTILLAS / POZOS DE APUESTAS
  // ============================================================

  Future<String> createBallot({
    required String championshipId,
    required String title,
    required double prizePool,
    required DateTime deadline,
    required String mode,
    required List<Map<String, dynamic>> matches,
  }) async {
    final doc = _firestore.collection('ballots').doc();
    await doc.set({
      'championshipId': championshipId,
      'title': title,
      'prizePool': prizePool,
      'deadline': Timestamp.fromDate(deadline),
      'mode': mode,
      'matches': matches,
      'status': 'active',
      'participantCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<String> submitBallotEntry({
    required String ballotId,
    required Map<String, dynamic> predictions,
    required String mode,
  }) async {
    final userId = await getLoggedInUserId();
    if (userId == null) throw Exception('Debes iniciar sesión');

    // Verificar que no haya participado ya
    final existing = await _firestore
        .collection('ballot_entries')
        .where('ballotId', isEqualTo: ballotId)
        .where('userId', isEqualTo: userId)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Ya participaste en esta cartilla');
    }

    // Obtener nombre del usuario
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userName = userDoc.data()?['displayName'] ?? 'Usuario';

    final code = 'MG-${_uuid.v4().substring(0, 6).toUpperCase()}';

    final doc = _firestore.collection('ballot_entries').doc();
    await doc.set({
      'ballotId': ballotId,
      'userId': userId,
      'userName': userName,
      'predictions': predictions,
      'mode': mode,
      'participationCode': code,
      'createdAt': FieldValue.serverTimestamp(),
      'isWinner': false,
      'correctPredictions': 0,
    });

    // Incrementar participantes
    await _firestore.collection('ballots').doc(ballotId).update({
      'participantCount': FieldValue.increment(1),
    });

    return code;
  }

  Future<void> closeBallot(String ballotId) async {
    await _firestore.collection('ballots').doc(ballotId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> resolveBallot({
    required String ballotId,
    required Map<String, dynamic> results,
  }) async {
    final entries = await _firestore
        .collection('ballot_entries')
        .where('ballotId', isEqualTo: ballotId)
        .get();

    final ballot = await _firestore.collection('ballots').doc(ballotId).get();
    final ballotData = ballot.data()!;
    final matches = List<Map<String, dynamic>>.from(ballotData['matches'] ?? []);
    final totalMatches = matches.length;

    List<String> winnerIds = [];

    final batch = _firestore.batch();

    for (final entry in entries.docs) {
      final predictions = Map<String, dynamic>.from(entry.data()['predictions'] ?? {});
      int correct = 0;

      for (final key in results.keys) {
        if (predictions[key] == results[key]) correct++;
      }

      final isWinner = correct == totalMatches;
      if (isWinner) winnerIds.add(entry.data()['userId']);

      batch.update(entry.reference, {
        'correctPredictions': correct,
        'isWinner': isWinner,
      });
    }

    batch.update(_firestore.collection('ballots').doc(ballotId), {
      'status': 'finished',
      'winnerIds': winnerIds,
      'results': results,
      'resolvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return winnerIds;
  }

  Future<void> updateBallot(String ballotId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('ballots').doc(ballotId).update(data);
  }

  Future<void> deleteBallot(String ballotId) async {
    final entries = await _firestore
        .collection('ballot_entries')
        .where('ballotId', isEqualTo: ballotId)
        .get();
    final batch = _firestore.batch();
    for (final entry in entries.docs) {
      batch.delete(entry.reference);
    }
    batch.delete(_firestore.collection('ballots').doc(ballotId));
    await batch.commit();
  }
}
