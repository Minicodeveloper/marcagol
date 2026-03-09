import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Crea un usuario administrador por defecto si no existe ninguno.
/// Solo se ejecuta una vez usando una flag en Firestore.
class SeedAdmin {
  static Future<void> ensureAdminExists() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    // Verificar si ya se corrió el seed
    final seedDoc = await firestore.collection('_app_config').doc('seed').get();
    if (seedDoc.exists && seedDoc.data()?['adminCreated'] == true) {
      return; // Ya existe un admin, no hacer nada
    }

    // Datos del admin por defecto
    const email = 'admin@marcagol.com';
    const password = 'Admin2026!';
    const displayName = 'Administrador';

    try {
      // Intentar crear el usuario en Firebase Auth
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento en Firestore con rol admin
      await firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Marcar seed como ejecutado
      await firestore.collection('_app_config').doc('seed').set({
        'adminCreated': true,
        'adminEmail': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cerrar sesión para que el usuario entre manualmente
      await auth.signOut();

      // ignore: avoid_print
      print('✅ Admin creado: $email / $password');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Ya existe, solo marcar como creado
        await firestore.collection('_app_config').doc('seed').set({
          'adminCreated': true,
          'adminEmail': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        // ignore: avoid_print
        print('ℹ️ El admin ya existía: $email');
      }
    }
  }
}
