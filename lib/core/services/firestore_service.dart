import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const _uuid = Uuid();

  // ============================================================
  // AUTENTICACIÓN & USUARIOS
  // ============================================================

  /// Registrar usuario nuevo
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String displayName,
    String role = 'client', // 'client' o 'admin'
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    
    return cred;
  }

  /// Login
  Future<UserCredential> loginUser({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists ? {'uid': user.uid, ...doc.data()!} : null;
  }

  // ============================================================
  // CAMPEONATOS
  // ============================================================

  /// Crear campeonato
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
      'status': 'active', // active, finished, cancelled
      'isActive': true,
      'isVisible': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Actualizar visibilidad de campeonato
  Future<void> toggleChampionshipVisibility(String championshipId, bool isVisible) async {
    await _firestore.collection('championships').doc(championshipId).update({
      'isVisible': isVisible,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Establecer campeonato activo (desactiva los demás)
  Future<void> setActiveChampionship(String championshipId) async {
    // Desactivar todos
    final batch = _firestore.batch();
    final all = await _firestore.collection('championships')
        .where('isActive', isEqualTo: true)
        .get();
    for (final doc in all.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    // Activar este
    batch.update(
      _firestore.collection('championships').doc(championshipId),
      {'isActive': true, 'status': 'active'},
    );
    await batch.commit();
  }

  /// Finalizar campeonato
  Future<void> finishChampionship(String championshipId) async {
    await _firestore.collection('championships').doc(championshipId).update({
      'status': 'finished',
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Eliminar campeonato
  Future<void> deleteChampionship(String championshipId) async {
    await _firestore.collection('championships').doc(championshipId).delete();
  }

  // ============================================================
  // PARTIDOS
  // ============================================================

  /// Agregar partido a un campeonato
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
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Actualizar resultado de partido
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

  /// Actualizar estado del partido (scheduled, live, finished)
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

  // ============================================================
  // TRANSMISIONES
  // ============================================================

  /// Crear transmisión de video (YouTube)
  Future<String> createVideoStream({
    required String title,
    required String youtubeUrl,
    String? description,
    String? championshipId,
  }) async {
    final doc = _firestore.collection('streams').doc();
    await doc.set({
      'title': title,
      'youtubeUrl': youtubeUrl,
      'description': description,
      'championshipId': championshipId,
      'type': 'video',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Crear transmisión de radio
  Future<String> createRadioStream({
    required String title,
    required String streamUrl,
    String? description,
    double? frequency,
  }) async {
    final doc = _firestore.collection('streams').doc();
    await doc.set({
      'title': title,
      'streamUrl': streamUrl,
      'description': description,
      'frequency': frequency,
      'type': 'radio',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Actualizar transmisión
  Future<void> updateStream(String streamId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('streams').doc(streamId).update(data);
  }

  /// Activar/desactivar transmisión
  Future<void> toggleStreamActive(String streamId, bool isActive) async {
    await _firestore.collection('streams').doc(streamId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Eliminar transmisión
  Future<void> deleteStream(String streamId) async {
    await _firestore.collection('streams').doc(streamId).delete();
  }

  // ============================================================
  // CARTILLAS / POZOS DE APUESTAS
  // ============================================================

  /// Crear cartilla de apuestas
  Future<String> createBallot({
    required String championshipId,
    required String title,
    required double prizePool,
    required DateTime deadline,
    required String mode, // 'result' (1X2) o 'score' (marcador exacto)
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
      'status': 'active', // active, closed, finished
      'participantCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Participar en una cartilla (enviar predicciones)
  Future<String> submitBallotEntry({
    required String ballotId,
    required Map<String, dynamic> predictions,
    required String mode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Debes iniciar sesión');
    
    // Verificar que no haya participado ya
    final existing = await _firestore
        .collection('ballot_entries')
        .where('ballotId', isEqualTo: ballotId)
        .where('userId', isEqualTo: user.uid)
        .get();
    
    if (existing.docs.isNotEmpty) {
      throw Exception('Ya participaste en esta cartilla');
    }
    
    final code = 'MG-${_uuid.v4().substring(0, 6).toUpperCase()}';
    
    final doc = _firestore.collection('ballot_entries').doc();
    await doc.set({
      'ballotId': ballotId,
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Usuario',
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

  /// Cerrar cartilla (no más participaciones)
  Future<void> closeBallot(String ballotId) async {
    await _firestore.collection('ballots').doc(ballotId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Resolver cartilla: calcular ganadores
  Future<List<String>> resolveBallot({
    required String ballotId,
    required Map<String, dynamic> results, // resultados reales
  }) async {
    final entries = await _firestore
        .collection('ballot_entries')
        .where('ballotId', isEqualTo: ballotId)
        .get();
    
    final ballot = await _firestore.collection('ballots').doc(ballotId).get();
    final ballotData = ballot.data()!;
    final mode = ballotData['mode'] as String;
    final matches = List<Map<String, dynamic>>.from(ballotData['matches'] ?? []);
    final totalMatches = matches.length;
    
    List<String> winnerIds = [];
    
    final batch = _firestore.batch();
    
    for (final entry in entries.docs) {
      final predictions = Map<String, dynamic>.from(entry.data()['predictions'] ?? {});
      int correct = 0;
      
      for (final key in results.keys) {
        if (mode == 'result') {
          // Comparar resultado (LOCAL, EMPATE, VISITA)
          if (predictions[key] == results[key]) correct++;
        } else {
          // Comparar marcador exacto
          if (predictions[key] == results[key]) correct++;
        }
      }
      
      final isWinner = correct == totalMatches;
      if (isWinner) winnerIds.add(entry.data()['userId']);
      
      batch.update(entry.reference, {
        'correctPredictions': correct,
        'isWinner': isWinner,
      });
    }
    
    // Actualizar cartilla
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

  /// Actualizar cartilla
  Future<void> updateBallot(String ballotId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('ballots').doc(ballotId).update(data);
  }

  /// Eliminar cartilla
  Future<void> deleteBallot(String ballotId) async {
    // Eliminar entradas primero
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
