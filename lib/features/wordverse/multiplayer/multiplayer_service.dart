import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/events/wordverse_events.dart';
import '../../../core/models/shest_models.dart';
import '../avatar/avatar_node.dart';

/// Servicio de Presencia Multiplayer y Reconexión (Fases 7, 8, 35).
/// Emite y sincroniza los eventos oficiales:
/// - `USER_JOINED_ROOM`
/// - `USER_LEFT_ROOM`
/// - `AVATAR_MOVED`
/// Soporta:
/// 1. Sincronización en tiempo real mediante **Supabase Realtime WebSocket + PostgREST (`room_presence`)**
///    cuando se configuran credenciales de Supabase.
/// 2. Simulación multi-avatar automática cuando se ejecuta en modo `Mock` sin credenciales remotas.
class WordverseMultiplayerService {
  WordverseMultiplayerService({
    required this.eventBus,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final WordverseEventBus eventBus;
  final http.Client _http;
  final Map<String, AvatarRoomNode> _remoteNodes = <String, AvatarRoomNode>{};

  Timer? _simulationTimer;
  WebSocketChannel? _realtimeChannel;
  StreamSubscription<Object?>? _wsSubscription;

  double _tickPhase = 0.0;
  bool _isConnected = false;
  String _currentRoomName = 'Sala Principal';
  String _remoteRestUrl = '';
  String _remoteAnonKey = '';

  bool get isConnected => _isConnected;
  String get currentRoomName => _currentRoomName;

  bool get isUsingLiveSupabase =>
      _remoteRestUrl.isNotEmpty &&
      !_remoteRestUrl.contains('your-project.supabase.co') &&
      !_remoteRestUrl.contains('mock://') &&
      _remoteAnonKey.isNotEmpty;

  List<AvatarRoomNode> get remoteAvatars =>
      _remoteNodes.values.toList(growable: false);

  /// Configura las credenciales opcionales de Supabase para sincronizar avatares reales.
  void configureRealtimeEndpoint({
    required String restUrl,
    required String anonKey,
  }) {
    final String clean = restUrl.trim().replaceAll(RegExp(r'/$'), '');
    if (clean.contains('.supabase.co') && !clean.endsWith('/rest/v1')) {
      _remoteRestUrl = '$clean/rest/v1';
    } else {
      _remoteRestUrl = clean;
    }
    _remoteAnonKey = anonKey.trim();
  }

  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    'Prefer': 'resolution=merge-duplicates',
    if (_remoteAnonKey.isNotEmpty) 'Authorization': 'Bearer $_remoteAnonKey',
    if (_remoteAnonKey.isNotEmpty) 'apikey': _remoteAnonKey,
  };

  /// Conecta el cliente a la sala multiplayer y registra `USER_JOINED_ROOM`.
  void joinRoom({
    required ShestUser localUser,
    required List<ShestUser> peerUsers,
    String roomName = 'Sala Principal',
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

    if (isUsingLiveSupabase) {
      _connectLiveSupabaseWebSocket(
        localUser: localUser,
        onTickUpdate: onTickUpdate,
      );
    }

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!_isConnected) return;
      _tickPhase += 0.06;
      if (!isUsingLiveSupabase) {
        _animateRemotePeers();
      }
      onTickUpdate?.call();
    });
  }

  void _connectLiveSupabaseWebSocket({
    required ShestUser localUser,
    void Function()? onTickUpdate,
  }) {
    try {
      final String hostUrl = _remoteRestUrl
          .replaceFirst('/rest/v1', '')
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');
      final Uri wsUri = Uri.parse(
        '$hostUrl/realtime/v1/websocket?apikey=$_remoteAnonKey&vsn=1.0.0',
      );
      _wsSubscription?.cancel();
      _realtimeChannel?.sink.close();
      _realtimeChannel = WebSocketChannel.connect(wsUri);

      // Suscribirse al canal Phoenix de la sala en Supabase Realtime
      _realtimeChannel!.sink.add(
        jsonEncode(<String, Object?>{
          'topic': 'realtime:public:room_presence',
          'event': 'phx_join',
          'payload': const <String, Object?>{},
          'ref': '1',
        }),
      );

      _wsSubscription = _realtimeChannel!.stream.listen((Object? rawMessage) {
        if (rawMessage is! String) return;
        try {
          final Map<String, Object?> msg =
              jsonDecode(rawMessage) as Map<String, Object?>;
          final Map<String, Object?>? payload =
              msg['payload'] as Map<String, Object?>?;
          final Map<String, Object?>? record =
              payload?['record'] as Map<String, Object?>?;
          if (record != null) {
            final String uid = '${record['user_id'] ?? ''}';
            if (uid.isNotEmpty &&
                uid != localUser.id &&
                _remoteNodes.containsKey(uid)) {
              final AvatarRoomNode current = _remoteNodes[uid]!;
              final double nx =
                  (record['pos_x'] as num?)?.toDouble() ?? current.normX;
              final double nz =
                  (record['pos_z'] as num?)?.toDouble() ?? current.normZ;
              final double rot =
                  (record['rotacion'] as num?)?.toDouble() ??
                  current.rotationRadians;
              _remoteNodes[uid] = current.copyWith(
                normX: nx,
                normZ: nz,
                rotationRadians: rot,
                isMoving: true,
              );
              onTickUpdate?.call();
            }
          }
        } catch (_) {}
      }, onError: (_) {});
    } catch (_) {}
  }

  void _animateRemotePeers() {
    final List<String> ids = _remoteNodes.keys.toList();
    for (int i = 0; i < ids.length; i++) {
      final String id = ids[i];
      final AvatarRoomNode node = _remoteNodes[id]!;
      final double baseAngle = _tickPhase + (i * 2.1);
      final double radius = 0.34 + (i * 0.11);
      final double newX = (math.cos(baseAngle * 0.45) * radius).clamp(
        -0.72,
        0.72,
      );
      final double newZ = (math.sin(baseAngle * 0.45) * radius).clamp(
        -0.72,
        0.72,
      );
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
    if ((_tickPhase * 10).round() % 18 == 0) {
      eventBus.emit(
        WordverseEventType.avatarMoved,
        'AVATAR_MOVED ($userId) → (${x.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})',
        <String, Object?>{'userId': userId, 'x': x, 'z': z, 'rot': rotation},
      );
      if (isUsingLiveSupabase) {
        unawaited(_upsertPresenceToSupabase(userId, x, z, rotation));
      }
    }
  }

  Future<void> _upsertPresenceToSupabase(
    String userId,
    double x,
    double z,
    double rotation,
  ) async {
    try {
      final Uri uri = Uri.parse('$_remoteRestUrl/room_presence');
      await _http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(<String, Object?>{
              'user_id': userId,
              'sala': _currentRoomName,
              'pos_x': x,
              'pos_z': z,
              'rotacion': rotation,
              'online': true,
              'updated_at': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Actualiza datos de un usuario remoto en la sala.
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

  /// Cambia de sub-sala dentro de WordVerse (Fase 8: Sala Principal, Networking, Negocios, P2P, Escrow).
  void switchRoom({
    required ShestUser localUser,
    required String newRoomName,
  }) {
    if (_currentRoomName == newRoomName) return;
    final String previousRoom = _currentRoomName;
    eventBus.emit(
      WordverseEventType.userLeftRoom,
      '${localUser.name} salió de $previousRoom',
      <String, Object?>{'userId': localUser.id, 'room': previousRoom},
    );
    _currentRoomName = newRoomName;
    eventBus.emit(
      WordverseEventType.userJoinedRoom,
      '${localUser.name} entró a la sub-sala $newRoomName',
      <String, Object?>{'userId': localUser.id, 'room': newRoomName},
    );
  }

  void leaveRoom(String localUserId) {
    _isConnected = false;
    _simulationTimer?.cancel();
    _wsSubscription?.cancel();
    _realtimeChannel?.sink.close();
    eventBus.emit(
      WordverseEventType.userLeftRoom,
      'USER_LEFT_ROOM ($localUserId)',
    );
  }

  void dispose() {
    _simulationTimer?.cancel();
    _wsSubscription?.cancel();
    _realtimeChannel?.sink.close();
  }
}
