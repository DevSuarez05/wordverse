import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/events/wordverse_events.dart';
import '../../../core/models/shest_models.dart';
import '../avatar/avatar_node.dart';
import '../meetings/escrow_p2p_modals.dart';
import '../meetings/meetings_qr_modals.dart';
import '../meetings/notifications_sheet.dart';
import '../movement/room_physics_controller.dart';
import '../multiplayer/multiplayer_service.dart';
import 'glb_inspector.dart';
import 'room_3d_viewport.dart';

/// Pantalla Principal del Módulo WordVerse 3D integrado con Shest Labs.
class WordverseModuleScreen extends StatefulWidget {
  const WordverseModuleScreen({
    super.key,
    required this.apiClient,
    this.startDirectlyInRoom = false,
  });

  final ShestApiClient apiClient;
  final bool startDirectlyInRoom;

  @override
  State<WordverseModuleScreen> createState() => _WordverseModuleScreenState();
}

class _WordverseModuleScreenState extends State<WordverseModuleScreen> {
  late final WordverseMultiplayerService _multiplayer;
  bool _inRoom = false;

  AvatarRoomNode? _localAvatar;
  HotspotKind? _nearbyHotspot;
  GlbOptimizationReport? _glbReport;

  final double _cameraPitch = 0.62;
  double _cameraZoom = 1.0;
  double _cameraYaw = 0.0;
  String _selectedSubRoom = 'Sala Principal';
  String _selectedGateUserId = 'usr_1';
  late final TextEditingController _remoteUrlCtrl;
  late final TextEditingController _remoteKeyCtrl;

  static const List<String> _subRooms = <String>[
    'Sala Principal',
    'Networking',
    'Negocios',
    'P2P',
    'Escrow',
    'Shest Café',
  ];

  static const Map<String, String> _gateUsers = <String, String>{
    'usr_1': 'usr_1 • Daniel (Tú) — Trader P2P & Dev',
    'usr_2': 'usr_2 • Valeria Méndez — Comerciante Verificada USDT',
    'usr_3': 'usr_3 • Carlos Mendoza — Director de Negocios Web3',
    'usr_4': 'usr_4 • Sofía Herrera — Especialista Escrow & Arbitraje',
  };

  @override
  void initState() {
    super.initState();
    _remoteUrlCtrl = TextEditingController(
      text: widget.apiClient.currentRemoteUrl,
    );
    _remoteKeyCtrl = TextEditingController(
      text: widget.apiClient.currentRemoteKey,
    );
    _multiplayer = WordverseMultiplayerService(
      eventBus: widget.apiClient.eventBus,
    );
    _inspectGlbAsset();
    if (widget.startDirectlyInRoom) {
      _enterWordverseFromShestSession();
    }
  }

  Future<void> _inspectGlbAsset() async {
    final GlbOptimizationReport report =
        await GlbOptimizationReport.inspectAsset(
          'assets/models/01_sala_principal.glb',
        );
    if (!mounted) return;
    setState(() => _glbReport = report);
  }

  Future<void> _enterWordverseFromShestSession({String userId = 'usr_1'}) async {
    if (widget.apiClient.environment != ShestBackendEnvironment.mock) {
      widget.apiClient.configureRemoteCredentials(
        baseUrl: _remoteUrlCtrl.text,
        apiKeyOrToken: _remoteKeyCtrl.text,
      );
      _multiplayer.configureRealtimeEndpoint(
        restUrl: _remoteUrlCtrl.text,
        anonKey: _remoteKeyCtrl.text,
      );
    }
    final ShestAuthSession session = await widget.apiClient.auth
        .loginWithShestSession(userId: userId);
    final List<ShestUser> allUsers =
        await widget.apiClient.auth.searchUsers();

    final AvatarRoomNode initialLocal = AvatarRoomNode(
      user: session.user,
      normX: RoomPhysicsController.spawnX,
      normZ: RoomPhysicsController.spawnZ,
      isLocalPlayer: true,
    );

    _multiplayer.joinRoom(
      localUser: session.user,
      peerUsers: allUsers,
      roomName: _selectedSubRoom,
      onTickUpdate: () {
        if (mounted) setState(() {});
      },
    );

    if (!mounted) return;
    setState(() {
      _localAvatar = initialLocal;
      _inRoom = true;
    });
  }

  void _onJoystickMove(StickDragDetails details) {
    final AvatarRoomNode? current = _localAvatar;
    if (current == null) return;

    final ({double x, double z, double rotation, bool collided}) step =
        RoomPhysicsController.computeStep(
          currentX: current.normX,
          currentZ: current.normZ,
          currentRotation: current.rotationRadians,
          joyDx: details.x,
          joyDy: details.y,
        );

    final HotspotKind? detectedHotspot =
        RoomPhysicsController.detectNearbyHotspot(step.x, step.z);

    setState(() {
      _localAvatar = current.copyWith(
        normX: step.x,
        normZ: step.z,
        rotationRadians: step.rotation,
        isMoving: details.x.abs() > 0.02 || details.y.abs() > 0.02,
      );
      _nearbyHotspot = detectedHotspot;
    });

    if (_localAvatar!.isMoving) {
      _multiplayer.broadcastLocalMove(
        userId: current.user.id,
        x: step.x,
        z: step.z,
        rotation: step.rotation,
      );
    }
  }

  void _onFloorTapped(double targetX, double targetZ) {
    final AvatarRoomNode? current = _localAvatar;
    if (current == null) return;
    final double dx = targetX - current.normX;
    final double dz = targetZ - current.normZ;
    final double dist = math.sqrt((dx * dx) + (dz * dz));
    if (dist < 0.01) return;

    // Respetar colisiones perimetrales y mesa central
    double finalX = targetX.clamp(
      -RoomPhysicsController.maxBound,
      RoomPhysicsController.maxBound,
    );
    double finalZ = targetZ.clamp(
      -RoomPhysicsController.maxBound,
      RoomPhysicsController.maxBound,
    );
    final double distFromCenter = math.sqrt(
      (finalX * finalX) + (finalZ * finalZ),
    );
    if (distFromCenter < RoomPhysicsController.centerTableRadius) {
      final double safeScale =
          (RoomPhysicsController.centerTableRadius + 0.04) /
          (distFromCenter == 0 ? 1 : distFromCenter);
      finalX *= safeScale;
      finalZ *= safeScale;
    }

    final double rotation = math.atan2(dx, dz);
    final HotspotKind? detectedHotspot =
        RoomPhysicsController.detectNearbyHotspot(finalX, finalZ);

    setState(() {
      _localAvatar = current.copyWith(
        normX: finalX,
        normZ: finalZ,
        rotationRadians: rotation,
        isMoving: false,
      );
      _nearbyHotspot = detectedHotspot;
    });

    _multiplayer.broadcastLocalMove(
      userId: current.user.id,
      x: finalX,
      z: finalZ,
      rotation: rotation,
    );
  }

  void _openNotificationsSheet() {
    WordverseNotificationsSheet.show(
      context: context,
      eventBus: widget.apiClient.eventBus,
      onSimulateErrorTest: _triggerReconnectFlow,
    );
  }

  void _triggerEmote(WordverseEmote emote) {
    final AvatarRoomNode? current = _localAvatar;
    if (current == null) return;
    setState(() {
      _localAvatar = current.copyWith(activeEmote: emote);
    });
    if (emote == WordverseEmote.p2p) {
      _handleHotspotAction(HotspotKind.p2p);
    }
  }

  Future<void> _changeMyPresenceStatus(UserPresenceStatus newStatus) async {
    final AvatarRoomNode? current = _localAvatar;
    if (current == null) return;
    final ShestUser updated = await widget.apiClient.auth.updateUserStatus(
      userId: current.user.id,
      status: newStatus,
    );
    if (!mounted) return;
    setState(() {
      _localAvatar = current.copyWith(user: updated);
    });
  }

  void _handleHotspotAction(HotspotKind spot) {
    final ShestUser? user = _localAvatar?.user;
    if (user == null) return;

    switch (spot) {
      case HotspotKind.networking:
        EscrowAndProfileModals.showNetworkingAndChatSheet(
          context: context,
          apiClient: widget.apiClient,
          currentUser: user,
          onUserUpdated: _multiplayer.updateRemoteUser,
        );
      case HotspotKind.createMeeting:
        MeetingsAndQrModals.showMeetingsSheet(
          context: context,
          apiClient: widget.apiClient,
          currentUser: user,
        );
      case HotspotKind.qr:
        MeetingsAndQrModals.showQrCenterSheet(
          context: context,
          apiClient: widget.apiClient,
          currentUser: user,
        );
      case HotspotKind.p2p:
        EscrowAndProfileModals.showP2PAndWalletSheet(
          context: context,
          apiClient: widget.apiClient,
          currentUser: user,
        );
      case HotspotKind.escrow:
        EscrowAndProfileModals.showEscrowSheet(
          context: context,
          apiClient: widget.apiClient,
          currentUser: user,
        );
      case HotspotKind.myProfile:
        MeetingsAndQrModals.showQrCenterSheet(
          context: context,
          apiClient: widget.apiClient,
          currentUser: user,
        );
      case HotspotKind.exit:
        _multiplayer.leaveRoom(user.id);
        setState(() => _inRoom = false);
    }
  }

  Future<void> _triggerReconnectFlow() async {
    final ShestUser? user = _localAvatar?.user;
    if (user == null) return;
    widget.apiClient.simulateOffline = false;
    await _multiplayer.disconnectAndReconnect(
      localUser: user,
      onStatusChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _remoteUrlCtrl.dispose();
    _remoteKeyCtrl.dispose();
    _multiplayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_inRoom || _localAvatar == null) {
      return _buildShestSessionGate();
    }
    return _build3DRoomExperience();
  }

  // ===========================================================================
  // PUERTA DE ENTRADA: SESIÓN SHEST LABS → MÓDULO WORDVERSE (Fase 4)
  // ===========================================================================

  Widget _buildShestSessionGate() {
    return Scaffold(
      backgroundColor: const Color(0xFF070D19),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF101C33),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.view_in_ar,
                            color: Colors.cyanAccent,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'SHEST LABS → WORDVERSE 3D',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Módulo 3D de Reuniones, Networking, P2P y Escrow USDT TRC20',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Estado del archivo 01_sala_principal.glb (Fases 2 y 3)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF091224),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.check_circle,
                            color: Colors.greenAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _glbReport == null
                                  ? 'Verificando 01_sala_principal.glb...'
                                  : 'Asset 3D: ${_glbReport!.assetPath} (glTF v${_glbReport!.version} • ${_glbReport!.byteLength} B • ${_glbReport!.vertexCount} vértices / ${_glbReport!.triangleCount} polígonos • Mobile Ready)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<ShestBackendEnvironment>(
                      initialValue: widget.apiClient.environment,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF162238),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Entorno Shest API Client (Fase 1 / #19)',
                        labelStyle: TextStyle(color: Colors.cyanAccent),
                        isDense: true,
                      ),
                      items: ShestBackendEnvironment.values
                          .map(
                            (ShestBackendEnvironment env) =>
                                DropdownMenuItem<ShestBackendEnvironment>(
                                  value: env,
                                  child: Text(
                                    env.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          )
                          .toList(),
                      onChanged: (ShestBackendEnvironment? val) {
                        if (val != null) {
                          setState(() {
                            widget.apiClient.environment = val;
                            _remoteUrlCtrl.text =
                                widget.apiClient.currentRemoteUrl;
                            _remoteKeyCtrl.text =
                                widget.apiClient.currentRemoteKey;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGateUserId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF162238),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Sesión de Usuario Shest (Fase 4 / Multi-User)',
                        labelStyle: TextStyle(color: Colors.amberAccent),
                        isDense: true,
                      ),
                      items: _gateUsers.entries
                          .map(
                            (MapEntry<String, String> entry) =>
                                DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                          )
                          .toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setState(() => _selectedGateUserId = val);
                        }
                      },
                    ),
                    if (widget.apiClient.environment !=
                        ShestBackendEnvironment.mock) ...<Widget>[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('input_remote_url'),
                        controller: _remoteUrlCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                        ),
                        decoration: InputDecoration(
                          labelText: widget.apiClient.environment ==
                                  ShestBackendEnvironment.supabaseStaging
                              ? 'URL del Proyecto Supabase (ej: https://xyz.supabase.co)'
                              : 'URL Base API Shest Java (ej: https://api.shestlabs.com/v1)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('input_remote_key'),
                        controller: _remoteKeyCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                        ),
                        decoration: InputDecoration(
                          labelText: widget.apiClient.environment ==
                                  ShestBackendEnvironment.supabaseStaging
                              ? 'SUPABASE_ANON_KEY (Opcional: si se omite usa fallback Mock)'
                              : 'Bearer Token JWT de Shest',
                          labelStyle: const TextStyle(color: Colors.white70),
                          isDense: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const Key('btn_enter_wordverse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => _enterWordverseFromShestSession(
                          userId: _selectedGateUserId,
                        ),
                        icon: const Icon(Icons.login),
                        label: const Text(
                          'ENTRAR A LA SALA 3D CON SESIÓN SHEST',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SALA 3D PRINCIPAL + CONTROLES JOYSTICK + HOTSPOTS + MULTIPLAYER
  // ===========================================================================

  Widget _build3DRoomExperience() {
    final AvatarRoomNode local = _localAvatar!;
    final List<WordverseEvent> events = widget.apiClient.eventBus.history;
    final String latestEventText = events.isNotEmpty
        ? '[${events.first.type.code}] ${events.first.summary}'
        : 'Conectado a Shest API';

    return Scaffold(
      backgroundColor: const Color(0xFF050811),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // 1. Escena 3D Interactiva (Sala + 7 Hotspots + Avatares + Tap-to-walk)
            Positioned.fill(
              child: Room3DViewport(
                localAvatar: local,
                remoteAvatars: _multiplayer.remoteAvatars,
                activeHotspot: _nearbyHotspot,
                cameraPitch: _cameraPitch,
                cameraZoom: _cameraZoom,
                cameraYaw: _cameraYaw,
                subRoomName: _selectedSubRoom,
                glbReport: _glbReport,
                onFloorTapped: _onFloorTapped,
                onHotspotTapped: _handleHotspotAction,
                onAvatarTapped: (AvatarRoomNode tappedNode) {
                  if (tappedNode.isLocalPlayer) {
                    _handleHotspotAction(HotspotKind.myProfile);
                  } else {
                    EscrowAndProfileModals.showAvatarProfileSheet(
                      context: context,
                      apiClient: widget.apiClient,
                      currentUser: local.user,
                      targetUser: tappedNode.user,
                      onUserUpdated: _multiplayer.updateRemoteUser,
                    );
                  }
                },
              ),
            ),

            // 2. HUD Superior: Sesión Shest, Selector de Salas (Fase 8), Estado (Fase 16), Eventos (Fase 31/32) y Reconexión (Fase 35)
            Positioned(
              top: 8,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xDD0B1325),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        // Selector de Sub-Sala (Fase 8)
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubRoom,
                            dropdownColor: const Color(0xFF142038),
                            isDense: true,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            items: _subRooms
                                .map(
                                  (String r) => DropdownMenuItem<String>(
                                    value: r,
                                    child: Text(
                                      r == 'Shest Café' ? '☕ $r' : '🏛️ $r',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? room) {
                              if (room != null && room != _selectedSubRoom) {
                                _multiplayer.switchRoom(
                                  localUser: local.user,
                                  newRoomName: room,
                                );
                                setState(() {
                                  _selectedSubRoom = room;
                                  _localAvatar = local.copyWith(
                                    normX: RoomPhysicsController.spawnX,
                                    normZ: RoomPhysicsController.spawnZ,
                                    isMoving: false,
                                  );
                                });
                              }
                            },
                          ),
                        ),

                        // Selector de Estado de Usuario (Fase 16)
                        PopupMenuButton<UserPresenceStatus>(
                          tooltip: 'Cambiar mi estado (Fase 16)',
                          onSelected: _changeMyPresenceStatus,
                          itemBuilder: (BuildContext context) =>
                              UserPresenceStatus.values
                                  .map(
                                    (UserPresenceStatus s) =>
                                        PopupMenuItem<UserPresenceStatus>(
                                          value: s,
                                          child: Text('${s.emoji} ${s.label}'),
                                        ),
                                  )
                                  .toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${local.user.status.emoji} ${local.user.status.label}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),

                        // Botón Centro de Notificaciones & Eventos (Fases 31, 32, 34)
                        TextButton.icon(
                          key: const Key('btn_notifications_center'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _openNotificationsSheet,
                          icon: const Icon(
                            Icons.notifications_active,
                            size: 15,
                            color: Colors.amberAccent,
                          ),
                          label: Text(
                            'Eventos (${events.length})',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Botón de Reconexión / Estado Realtime (Fase 35)
                        TextButton.icon(
                          key: const Key('btn_reconnect'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _triggerReconnectFlow,
                          icon: Icon(
                            _multiplayer.isConnected
                                ? Icons.wifi
                                : Icons.wifi_off,
                            size: 15,
                            color: _multiplayer.isConnected
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          label: Text(
                            _multiplayer.isConnected
                                ? 'Online (${_multiplayer.remoteAvatars.length + 1})'
                                : 'Reconectar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Ticker de Eventos Internos (Fase 32) -> Tocable para abrir Centro de Notificaciones
                  InkWell(
                    onTap: _openNotificationsSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xBB081020),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              latestEventText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 10.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const Text(
                            'Ver historial ›',
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Banner contextual cuando el Avatar entra en contacto con un Hotspot (Fase 27)
            if (_nearbyHotspot != null)
              Positioned(
                top: 90,
                left: 24,
                right: 24,
                child: Center(
                  child: ElevatedButton.icon(
                    key: const Key('btn_activate_nearby_hotspot'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => _handleHotspotAction(_nearbyHotspot!),
                    icon: const Icon(Icons.touch_app, size: 16),
                    label: Text(
                      'Abrir ${_nearbyHotspot!.code}: ${_nearbyHotspot!.title}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),

            // 4. Barra de Emotes Rápidos (Fase 15) + Cámara 3D (Esquina inferior derecha)
            Positioned(
              right: 12,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Controles de Cámara 3D (Rotación Orbital 360° + Zoom)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton.filledTonal(
                        key: const Key('btn_rotate_left'),
                        tooltip: 'Rotar cámara 3D a la izquierda',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(
                          () => _cameraYaw -= 0.28,
                        ),
                        icon: const Icon(Icons.rotate_left, size: 18),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        key: const Key('btn_rotate_right'),
                        tooltip: 'Rotar cámara 3D a la derecha',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(
                          () => _cameraYaw += 0.28,
                        ),
                        icon: const Icon(Icons.rotate_right, size: 18),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        tooltip: 'Acercar cámara 3D',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(
                          () => _cameraZoom = (_cameraZoom + 0.12).clamp(
                            0.75,
                            1.35,
                          ),
                        ),
                        icon: const Icon(Icons.zoom_in, size: 18),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        tooltip: 'Alejar cámara 3D',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(
                          () => _cameraZoom = (_cameraZoom - 0.12).clamp(
                            0.75,
                            1.35,
                          ),
                        ),
                        icon: const Icon(Icons.zoom_out, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Emotes Fase 15: 👋 👍 🤝 ☕ 💬 💰
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xDD0B1325),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Wrap(
                      spacing: 4,
                      children: WordverseEmote.values.map((WordverseEmote e) {
                        return InkWell(
                          key: Key('emote_${e.name}'),
                          onTap: () => _triggerEmote(e),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              e.emoji,
                              style: const TextStyle(fontSize: 17),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // 5. Joystick Móvil Oficial para caminar en la Sala 3D (Fase 6)
            Positioned(
              left: 16,
              bottom: 14,
              child: SizedBox(
                width: 112,
                height: 112,
                child: Joystick(
                  mode: JoystickMode.all,
                  includeInitialAnimation: false,
                  listener: _onJoystickMove,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
