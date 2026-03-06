///entidad de Usuario con dni
class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final String dni; //dni cifrado en Firestore
  final String? photoURL;
  final double balance;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? verifiedAt; //verificación de DNI

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.dni,
    this.photoURL,
    required this.balance,
    required this.role,
    required this.createdAt,
    this.verifiedAt,
  });

  bool get isVerified => verifiedAt != null;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
}

enum UserRole {
  user,       // Usuario normal
  admin,      // Admin (puede actualizar scores, transmitir)
  superAdmin, // Super Admin (gestión completa)
}