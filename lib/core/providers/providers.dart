import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';

// ============================================================
// PROVIDERS GLOBALES
// ============================================================

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ============================================================
// AUTENTICACIÓN (contra colección 'users' de Firestore)
// ============================================================

/// State notifier para manejar la sesión del usuario
class AuthNotifier extends StateNotifier<String?> {
  AuthNotifier() : super(null);

  /// Inicializar: leer de SharedPreferences
  Future<void> init() async {
    final userId = await FirestoreService.getLoggedInUserId();
    state = userId;
  }

  /// Login exitoso
  void setLoggedIn(String userId) {
    state = userId;
  }

  /// Logout
  Future<void> logout() async {
    await FirestoreService().logout();
    state = null;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, String?>((ref) {
  return AuthNotifier();
});

/// Provider para saber si está logueado
final isLoggedInProvider = Provider<bool>((ref) {
  final userId = ref.watch(authNotifierProvider);
  return userId != null;
});

/// Datos del usuario actual desde Firestore (stream en tiempo real)
final currentUserDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final userId = ref.watch(authNotifierProvider);
  if (userId == null) return Stream.value(null);
  
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.exists ? {'uid': doc.id, ...doc.data()!} : null);
});

/// Provider para saber si es admin
final isAdminProvider = Provider<bool>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (data) => data?['role'] == 'admin' || data?['role'] == 'superAdmin',
    loading: () => false,
    error: (_, __) => false,
  );
});

// ============================================================
// CAMPEONATOS
// ============================================================

/// Todos los campeonatos (admin)
final championshipsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('championships')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

/// Solo campeonatos visibles
final visibleChampionshipsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final all = ref.watch(championshipsProvider);
  return all.when(
    data: (list) => Stream.value(
      list.where((c) => c['isVisible'] == true).toList(),
    ),
    loading: () => Stream.value(<Map<String, dynamic>>[]),
    error: (_, __) => Stream.value(<Map<String, dynamic>>[]),
  );
});

/// Campeonato activo actual
final activeChampionshipProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final all = ref.watch(championshipsProvider);
  return all.when(
    data: (list) {
      final active = list.where((c) => c['isActive'] == true && c['isVisible'] == true).toList();
      return Stream.value(active.isNotEmpty ? active.first : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Campeonatos finalizados (historial)
final historicChampionshipsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final all = ref.watch(championshipsProvider);
  return all.when(
    data: (list) => Stream.value(
      list.where((c) => c['status'] == 'finished' && c['isVisible'] == true).toList(),
    ),
    loading: () => Stream.value(<Map<String, dynamic>>[]),
    error: (_, __) => Stream.value(<Map<String, dynamic>>[]),
  );
});

// ============================================================
// PARTIDOS
// ============================================================

final matchesByChampionshipProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, championshipId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('championships')
      .doc(championshipId)
      .collection('matches')
      .orderBy('matchNumber')
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

// ============================================================
// TRANSMISIONES
// ============================================================

/// Todas las transmisiones
final allStreamsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('streams')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

/// Transmisiones activas de video
final liveVideoStreamsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final all = ref.watch(allStreamsProvider);
  return all.when(
    data: (list) => Stream.value(
      list.where((s) => s['type'] == 'video' && s['isActive'] == true).toList(),
    ),
    loading: () => Stream.value(<Map<String, dynamic>>[]),
    error: (_, __) => Stream.value(<Map<String, dynamic>>[]),
  );
});

/// Transmisiones activas de radio
final liveRadioStreamsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final all = ref.watch(allStreamsProvider);
  return all.when(
    data: (list) => Stream.value(
      list.where((s) => s['type'] == 'radio' && s['isActive'] == true).toList(),
    ),
    loading: () => Stream.value(<Map<String, dynamic>>[]),
    error: (_, __) => Stream.value(<Map<String, dynamic>>[]),
  );
});

// ============================================================
// CARTILLAS / POZOS
// ============================================================

final allBallotsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('ballots')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
});

final activeBallotProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final all = ref.watch(allBallotsProvider);
  return all.when(
    data: (list) => Stream.value(
      list.where((b) => b['status'] == 'active').toList(),
    ),
    loading: () => Stream.value(<Map<String, dynamic>>[]),
    error: (_, __) => Stream.value(<Map<String, dynamic>>[]),
  );
});

final ballotByIdProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, ballotId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('ballots')
      .doc(ballotId)
      .snapshots()
      .map((doc) => doc.exists ? {'id': doc.id, ...doc.data()!} : null);
});

/// Participaciones del usuario actual
final myBallotEntriesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(authNotifierProvider);
  final firestore = ref.watch(firestoreProvider);

  if (userId == null) return Stream.value(<Map<String, dynamic>>[]);
  
  return firestore
      .collection('ballot_entries')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        list.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime == null || bTime == null) return 0;
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });
        return list;
      });
});

final ballotEntriesByBallotProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, ballotId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('ballot_entries')
      .where('ballotId', isEqualTo: ballotId)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        list.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime == null || bTime == null) return 0;
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });
        return list;
      });
});
