# 🏆 MarcaGol - Aplicación de Apuestas Deportivas

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Ready-orange.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)

Aplicación móvil de apuestas deportivas con sistema **P2P** (persona a persona) y **pozos colectivos** con predicciones de marcador exacto.

---

## Tabla de Contenidos

- [Características](#-características)
- [Arquitectura](#-arquitectura)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Instalación](#-instalación)
- [Configuración de Firebase](#-configuración-de-firebase)
- [Estructura de Firestore](#-estructura-de-firestore)
- [Flujos Principales](#-flujos-principales)
- [Próximos Pasos](#-próximos-pasos)

---

## Características

### **Home - Partidos Destacados**
- Listado de partidos con cuotas en tiempo real
- Filtro por deportes (Fútbol inicialmente)
- Indicador de partidos en vivo
- Vista previa de odds (1, X, 2)

### **Live - Partidos en Vivo**
- Transmisión de partidos en tiempo real
- **Chat en vivo** integrado por partido
- Actualización de marcadores
- Lista de espectadores

### **Bets - Apuestas P2P**
- Crear apuestas personalizadas
- Aceptar apuestas de otros usuarios
- Tipos de apuesta:
  - Ganador
  - Marcador exacto
  - Más/Menos goles
  - Ambos equipos anotan
- **Comprobantes digitales** descargables
- Historial de apuestas

### **Pools - Pozos Colectivos**
- Predicción de marcador exacto
- Múltiples participantes por pozo
- Pozo acumulado si nadie acierta
- División equitativa entre ganadores
- Temporizador de cierre

### **Profile - Perfil de Usuario**
- Autenticación con Firebase
- Billetera virtual
- Historial completo
- Configuración de cuenta

---

## Arquitectura

El proyecto sigue **Clean Architecture** con organización **Feature-First**:

```
lib/
├── core/                 # Código compartido
│   ├── constants/        # Colores, strings, constantes
│   ├── theme/            # Tema de la app
│   └── widgets/          # Widgets reutilizables
│
├── features/             # Módulos por característica
│   ├── home/
│   ├── live/
│   ├── bets/
│   ├── pools/
│   └── profile/
│
└── shared/               # Componentes compartidos
    └── navigation/       # Sistema de navegación
```

### Capas por Feature

Cada feature sigue esta estructura:

```
feature/
├── data/
│   ├── models/           # Modelos con JSON serialization
│   ├── datasources/      # Fuentes de datos (Firebase)
│   └── repositories/     # Implementación de repositorios
│
├── domain/
│   ├── entities/         # Entidades de negocio
│   ├── repositories/     # Contratos de repositorios
│   └── usecases/         # Casos de uso
│
└── presentation/
    ├── screens/          # Pantallas
    ├── widgets/          # Widgets específicos
    └── providers/        # Estado (Riverpod)
```

---

## Estructura del Proyecto

```
MarcaGol/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   └── app_strings.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── widgets/
│   │
│   ├── features/
│   │   ├── home/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   └── home_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── match_card.dart
│   │   │   │       ├── odd_button.dart
│   │   │   │       └── odd_chip.dart
│   │   │   └── domain/
│   │   │       └── entities/
│   │   │
│   │   ├── live/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── live_screen.dart
│   │   │   │   │   └── live_match_detail_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── live_match_card.dart
│   │   │   │       └── chat_message_widget.dart
│   │   │   └── domain/
│   │   │       └── entities/
│   │   │
│   │   ├── bets/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       └── bet_model.dart
│   │   │   ├── domain/
│   │   │   │   └── entities/
│   │   │   │       └── bet_entity.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── bets_screen.dart
│   │   │       │   ├── create_bet_screen.dart
│   │   │       │   ├── bet_detail_screen.dart
│   │   │       │   └── my_bets_history_screen.dart
│   │   │       └── widgets/
│   │   │           ├── bet_card.dart
│   │   │           └── receipt_dialog.dart
│   │   │
│   │   ├── pools/
│   │   │   ├── data/
│   │   │   │   └── models/
│   │   │   │       ├── pool_model.dart
│   │   │   │       └── prediction_model.dart
│   │   │   ├── domain/
│   │   │   │   └── entities/
│   │   │   │       ├── pool_entity.dart
│   │   │   │       └── prediction_entity.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── pool_betting_screen.dart
│   │   │       │   ├── pool_detail_screen.dart
│   │   │       │   └── create_pool_screen.dart
│   │   │       └── widgets/
│   │   │           ├── pool_card.dart
│   │   │           └── prediction_item.dart
│   │   │
│   │   └── profile/
│   │       └── presentation/
│   │           ├── screens/
│   │           │   └── profile_screen.dart
│   │           └── widgets/
│   │               ├── profile_header.dart
│   │               └── menu_item_widget.dart
│   │
│   └── shared/
│       └── navigation/
│           └── main_screen.dart
│
├── pubspec.yaml
└── README.md
```

---

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/EiderMontalvo/marca-gool.git
cd MarcaGol
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Verificar instalación

```bash
flutter doctor
```

### 4. Ejecutar la app

```bash
flutter run
```

---

## Configuración de Firebase

### 1. Crear proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto llamado **"MarcaGol"**
3. Activa **Authentication**, **Firestore** y **Storage**

### 2. Configurar para Android

```bash
flutterfire configure
```

### 3. Configurar Authentication

En Firebase Console:
- Authentication > Sign-in method
- Habilita **Email/Password**
- Habilita **Google Sign-In** (opcional)

### 4. Configurar Firestore

En Firebase Console:
- Firestore Database > Create database
- Inicia en **modo de prueba** (cambiar reglas en producción)

---

## Estructura de Firestore

### Colecciones Principales

#### **users**
```json
{
  "uid": "user123",
  "displayName": "Juan Pérez",
  "email": "juan@example.com",
  "photoURL": "https://...",
  "balance": 500.00,
  "createdAt": "2026-02-28T10:00:00Z",
  "updatedAt": "2026-02-28T10:00:00Z"
}
```

#### **matches**
```json
{
  "id": "match001",
  "league": "Liga 1 - Perú",
  "homeTeam": "Deportivo Llacuabamba",
  "awayTeam": "Cultural Santa Rosa",
  "homeScore": 2,
  "awayScore": 1,
  "status": "live", // scheduled, live, finished
  "startTime": "2026-02-28T19:00:00Z",
  "odds": {
    "home": 2.40,
    "draw": 3.20,
    "away": 2.80
  },
  "hasStream": true,
  "viewerCount": 1234
}
```

#### **bets** (P2P)
```json
{
  "id": "APU-001",
  "creatorId": "user123",
  "creatorName": "Juan Pérez",
  "eventId": "match001",
  "eventName": "Deportivo Llacuabamba vs Cultural Santa Rosa",
  "betType": "Ganador: Deportivo Llacuabamba",
  "amount": 50.00,
  "status": "pending", // pending, accepted, finished, cancelled
  "createdAt": "2026-02-28T10:00:00Z",
  "deadline": "2026-02-28T18:45:00Z",
  "acceptorId": null,
  "acceptorName": null,
  "acceptedAt": null,
  "winnerId": null,
  "resolvedAt": null
}
```

#### **pools**
```json
{
  "id": "POZO-001",
  "eventId": "match001",
  "eventName": "Deportivo Llacuabamba vs Cultural Santa Rosa",
  "team1": "Deportivo Llacuabamba",
  "team2": "Cultural Santa Rosa",
  "entryFee": 50.00,
  "totalAmount": 1250.00,
  "participantCount": 25,
  "deadline": "2026-02-28T18:45:00Z",
  "status": "active", // active, closed, finished, cancelled
  "createdAt": "2026-02-27T10:00:00Z",
  "finalScore": null,
  "winnerIds": [],
  "resolvedAt": null
}
```

#### **predictions**
```json
{
  "id": "pred001",
  "poolId": "POZO-001",
  "userId": "user123",
  "userName": "Juan Pérez",
  "predictedScore": "2-1",
  "team1Score": 2,
  "team2Score": 1,
  "createdAt": "2026-02-28T12:00:00Z",
  "isWinner": false
}
```

#### **chatMessages**
```json
{
  "id": "msg001",
  "matchId": "match001",
  "userId": "user123",
  "userName": "Juan Pérez",
  "message": "¡Vamos Equipo!",
  "createdAt": "2026-02-28T19:30:00Z"
}
```

---

## Flujos Principales

### 1. **Crear Apuesta P2P**

```dart
// TODO: Implementar en features/bets/data/datasources/bets_remote_datasource.dart

Future<void> createBet(BetModel bet) async {
  await FirebaseFirestore.instance
      .collection('bets')
      .doc(bet.id)
      .set(bet.toJson());
}
```

### 2. **Aceptar Apuesta**

```dart
// TODO: Implementar en features/bets/domain/usecases/accept_bet_usecase.dart

Future<void> acceptBet(String betId, String userId) async {
  await FirebaseFirestore.instance
      .collection('bets')
      .doc(betId)
      .update({
        'acceptorId': userId,
        'acceptorName': 'Nombre Usuario',
        'acceptedAt': DateTime.now().toIso8601String(),
        'status': 'accepted',
      });
}
```

### 3. **Participar en Pozo**

```dart
// TODO: Implementar en features/pools/data/datasources/pools_remote_datasource.dart

Future<void> createPrediction(PredictionModel prediction) async {
  final batch = FirebaseFirestore.instance.batch();
  
  // Crear predicción
  batch.set(
    FirebaseFirestore.instance.collection('predictions').doc(prediction.id),
    prediction.toJson(),
  );
  
  // Actualizar pozo
  batch.update(
    FirebaseFirestore.instance.collection('pools').doc(prediction.poolId),
    {
      'participantCount': FieldValue.increment(1),
      'totalAmount': FieldValue.increment(50.00),
    },
  );
  
  await batch.commit();
}
```

### 4. **Chat en Vivo**

```dart
// TODO: Implementar en features/live/data/datasources/chat_datasource.dart

Stream<List<ChatMessage>> getChatMessages(String matchId) {
  return FirebaseFirestore.instance
      .collection('chatMessages')
      .where('matchId', isEqualTo: matchId)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ChatMessage.fromJson(doc.data()))
          .toList());
}
```

---

## Próximos Pasos

### **Ya Completado**
- [x] Estructura de carpetas profesional
- [x] Diseño de UI completo
- [x] Modelos de datos (Entities & Models)
- [x] Pantallas y widgets
- [x] Tema y colores
- [x] Navegación básica

### **Por Implementar**

#### **Firebase Integration**
- [ ] Configurar `flutterfire configure`
- [ ] Crear datasources para cada feature
- [ ] Implementar repositories
- [ ] Conectar StreamBuilders en screens

#### **State Management**
- [ ] Configurar Riverpod providers
- [ ] Crear AuthProvider
- [ ] Crear BetsProvider
- [ ] Crear PoolsProvider

#### **Autenticación**
- [ ] Pantalla de Login
- [ ] Pantalla de Registro
- [ ] Verificación de email
- [ ] Recuperación de contraseña
- [ ] Google Sign-In

#### **Billetera Virtual**
- [ ] Sistema de saldo
- [ ] Historial de transacciones
- [ ] Depósitos y retiros
- [ ] Validación de fondos

#### **Sistema de Partidos**
- [ ] API de partidos en vivo (sugerencia: API-Football)
- [ ] Actualización automática de marcadores
- [ ] Cálculo automático de ganadores
- [ ] Notificaciones push

#### **Comprobantes**
- [ ] Generación de PDF con `pdf` package
- [ ] QR code con `qr_flutter`
- [ ] Compartir comprobantes

#### **Testing**
- [ ] Unit tests para entities
- [ ] Unit tests para usecases
- [ ] Widget tests
- [ ] Integration tests

---

## 🛠️ Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Ejecutar app en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter run -d <device_id>

# Construir APK
flutter build apk --release

# Construir App Bundle
flutter build appbundle --release

# Limpiar proyecto
flutter clean

# Analizar código
flutter analyze

# Formatear código
dart format .

# Generar código (json_serializable, freezed)
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Recursos Adicionales

- [Documentación de Flutter](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture-tdd/)

---
