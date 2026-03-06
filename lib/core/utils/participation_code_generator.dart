import 'package:crypto/crypto.dart';
import 'dart:convert';

class ParticipationCodeGenerator {
  ///genera codigo unico basado en userId + ballotId + timestamp
  static String generate(String userId, String ballotId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final input = '$userId-$ballotId-$timestamp';
    final hash = sha256.convert(utf8.encode(input)).toString();
    
    // Tomar primeros 8 caracteres y convertir a mayúsculas
    return hash.substring(0, 8).toUpperCase();
  }

  /// Genera código legible para el usuario (tipo: CART-ABC123)
  static String generateReadable(String userId, String ballotId) {
    final hash = generate(userId, ballotId);
    return 'CART-${hash.substring(0, 6)}';
  }
}