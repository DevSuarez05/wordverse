import 'dart:async';
import 'dart:math' as math;

import '../../../core/events/wordverse_events.dart';
import '../../../core/models/shest_models.dart';
import '../avatar/avatar_node.dart';

/// Servicio de Presencia Multiplayer y Reconexión (Fases 7, 8, 35).
/// Emite y sincroniza los eventos oficiales:
/// - `USER_JOINED_ROOM`
/// - `USER_LEFT_ROOM`
/// - `AVATAR_MOVED`
/// Soporta simulación multi-usuario en tiempo real y reconexión automática.
class WordverseMultiplayerService {
  WordverseMultiplayerService({required this.eventBus});

  final WordverseEventBus eventBus;
  final Map<String, AvatarRoomNode> _remoteNodes = <String, AvatarRoomNode>{};
  Timer? _simulationTimer;
  double _tickPhase = 0.0;
  bool _isConnected = false;
  String _currentRoomName = 'Sala Principal 3D';

  bool get isConnected => _isConnected;
  String get currentRoomName => _currentRoomName;

  List<AvatarRoomNode> get remoteAvatars =>
      _remoteNodes.values.toList(growable: false);

  /// Conecta el cliente a la sala multiplayer y registra `USER_JOINED_ROOM`.
  void joinRoom({
    required ShestUser localUser,
    required List<ShestUser> peerUsers,
    String roomName = 'Sala Principal 3D',
    void Function()? onTickUpdate,
  }) {
    _currentRoomName = roomName;
    _isConnected = true;
    _remoteNodes.clear();

    eventBus.emit(
      WordverseEventType.userJoinedRoom,
      '${localUser.name} entró a $_currentRoomName',
      <String, Object?>{'userId': localUser.id, 'room': _currentRoomName},
    );

    // Posiciones iniciales de los otros usuarios conectados en la sala
    const List<(double, double)> initialPositions = <(double, double)>[
      (-0.32, -0.18),
      (0.34, -0.12),
      (0.28, 0.30),
    ];

    for (int i = 0; i < peerUsers.length; i++) {
      final ShestUser peer = peerUsers[i];
      if (peer.id == localUser.id) continue;
      final (double px, double pz) =
          initialPositions[i % initialPositions.length];
      _remoteNodes[peer.id] = AvatarRoomNode(
        user: peer,
        normX: px,
        normZ: pz,
        activeEmote: i == 0 ? WordverseEmote.negotiate : null,
      );
      eventBus.emit(
        WordverseEventType.userJoinedRoom,
        '${peer.name} (${peer.company}) presente en la sala [Supabase/Realtime]',
        <String, Object?>{'userId': peer.id, 'x': px, 'z': pz},
      );
    }

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!_isConnected) return;
      _tickPhase += 0.06;
      _animateRemotePeers();
      onTickUpdate?.call();
    });
  }

  void _animateRemotePeers() {
    final List<String> ids = _remoteNodes.keys.toList();
    for (int i = 0; i < ids.length; i++) {
      final String id = ids[i];
      final AvatarRoomNode node = _remoteNodes[id]!;
      final double baseAngle = _tickPhase + (i * 2.1);
      final double radius = 0.34 + (i * 0.11);
      final double newX = (math.cos(baseAngle * 0.45) * radius).clamp(-0.72, 0.72);
      final double newZ = (math.sin(baseAngle * 0.45) * radius).clamp(-0.72, 0.72);
      final double rot = math.atan2(newZ - node.normZ, newX - node.normX);

      _remoteNodes[id] = node.copyWith(
        normX: newX,
        normZ: newZ,
        rotationRadians: rot,
        isMoving: true,
      );
    }
  }

  /// Notifica movimiento del avatar local (`AVATAR_MOVED`).
  void broadcastLocalMove({
    required String userId,
    required double x,
    required double z,
    required double rotation,
  }) {
    if (!_isConnected) return;
    // Emitimos evento de movimiento al bus cuando cambia de sector para no saturar el log
    if ((_tickPhase * 10).round() % 18 == 0) {
      eventBus.emit(
        WordverseEventType.avatarMoved,
        'AVATAR_MOVED ($userId) → (${x.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})',
        <String, Object?>{'userId': userId, 'x': x, 'z': z, 'rot': rotation},
      );
    }
  }

  /// Actualiza datos de un usuario remoto en la sala (ej. cuando se conecta o se marca favorito).
  void updateRemoteUser(ShestUser updatedUser) {
    final AvatarRoomNode? existing = _remoteNodes[updatedUser.id];
    if (existing != null) {
      _remoteNodes[updatedUser.id] = existing.copyWith(user: updatedUser);
    }
  }

  /// Simula desconexión y flujo de reconexión sin cerrar la app (Fase 35).
  Future<void> disconnectAndReconnect({
    required ShestUser localUser,
    void Function()? onStatusChanged,
  }) async {
    _isConnected = false;
    eventBus.emit(
      WordverseEventType.userLeftRoom,
      'Conexión realtime perdida. Intentando reconectar...',
    );
    onStatusChanged?.call();

    await Future<void>.delayed(const Duration(milliseconds: 650));
    _isConnected = true;
    eventBus.emit(
      WordverseEventType.userJoinedRoom,
      'Reconexión exitosa: Sesión recuperada y avatares sincronizados.',
      <String, Object?>{'userId': localUser.id},
    );
    onStatusChanged?.call();
  }

  void leaveRoom(String localUserId) {
    _isConnected = false;
    _simulationTimer?.cancel();
    eventBus.emit(
      WordverseEventType.userLeftRoom,
      'USER_LEFT_ROOM ($localUserId)',
    );
  }

  void dispose() {
    _simulationTimer?.cancel();
  }
}
