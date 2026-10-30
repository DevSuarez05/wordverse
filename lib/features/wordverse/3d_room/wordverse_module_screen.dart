import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/events/wordverse_events.dart';
import '../../../core/models/shest_models.dart';
import '../../../core/services/spatial_audio_service.dart';
import '../avatar/avatar_node.dart';
import '../meetings/escrow_p2p_modals.dart';
import '../meetings/meetings_qr_modals.dart';
import '../meetings/notifications_sheet.dart';
import '../meetings/shest_cafe_sheet.dart';
import '../movement/room_physics_controller.dart';
import '../multiplayer/multiplayer_service.dart';
import 'glb_inspector.dart';
import 'hub3d/hub3d_protocol.dart';
import 'hub3d/hub3d_view.dart';
import 'room_3d_viewport.dart';
import '../../../core/theme/wordverse_tokens.dart';
import '../models/private_room.dart';
import '../models/public_room.dart';
import '../screens/private_suites_screen.dart';
import '../screens/public_hub_screen.dart';

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
  WalletInfo? _walletInfo;
  ({double normX, double normZ})? _floorTarget;

  double _cameraPitch = 0.62;
  double _cameraZoom = 1.0;
  double _cameraYaw = 0.0;
  bool _showArchitecturalBackdrop = false;
  bool _showDebugTicker = false;
  final Hub3DController _hub3d = Hub3DController();
  final SpatialAudioService _spatialAudio = SpatialAudioService();
  String _selectedSubRoom = 'Sala Principal';
  String _selectedGateUserId = 'usr_1';
  bool _isProbingConnection = false;
  bool? _connectionProbeOk;
  String? _connectionProbeMessage;
  late final TextEditingController _remoteUrlCtrl;
  late final TextEditingController _remoteKeyCtrl;

  static const List<String> _subRooms = <String>[
    'Sala Principal',
    'Sala Privada',
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

  Future<void> _probeRemoteConnection() async {
    setState(() {
      _isProbingConnection = true;
      _connectionProbeMessage = null;
    });
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
    final ({bool ok, String message}) result = await widget.apiClient
        .verifyRemoteConnection();
    if (!mounted) return;
    setState(() {
      _isProbingConnection = false;
      _connectionProbeOk = result.ok;
      _connectionProbeMessage = result.message;
    });
  }

  Future<void> _copySupabaseSqlSchema() async {
    try {
      final String sql = await rootBundle.loadString('supabase_schema.sql');
      await Clipboard.setData(ClipboardData(text: sql));
      if (!mounted) return;
      setState(() {
        _connectionProbeOk = true;
        _connectionProbeMessage =
            'Script supabase_schema.sql (7 tablas + RLS + Seed) copiado al portapapeles. Pégalo con Ctrl+V en Supabase -> SQL Editor -> Run.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionProbeOk = false;
        _connectionProbeMessage = 'No se pudo copiar el script SQL: $e';
      });
    }
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
    final WalletInfo wallet = await widget.apiClient.wallet.getWalletInfo(
      session.user.id,
    );

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
      _walletInfo = wallet;
      _inRoom = true;
    });
  }

  void _enterSubRoom(String roomName) {
    final AvatarRoomNode? current = _localAvatar;
    if (current == null) {
      _selectedSubRoom = roomName;
      _enterWordverseFromShestSession(userId: _selectedGateUserId);
      return;
    }
    _multiplayer.switchRoom(
      localUser: current.user,
      newRoomName: roomName,
    );
    _hub3d.setSubRoom(roomName);
    setState(() {
      _selectedSubRoom = roomName;
      if (roomName != 'Sala Privada') {
        _localAvatar = current.copyWith(
          normX: RoomPhysicsController.spawnX,
          normZ: RoomPhysicsController.spawnZ,
          isMoving: false,
        );
      }
    });
  }

  void _openPublicHub() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => PublicHubScreen(
          apiClient: widget.apiClient,
          onBackToLobby: () => Navigator.of(ctx).pop(),
          onEnterRoom: (PublicRoom room) {
            Navigator.of(ctx).pop();
            _enterSubRoom(room.subRoomKey);
          },
        ),
      ),
    );
  }

  void _openPrivateSuites() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext ctx) => PrivateSuitesScreen(
          apiClient: widget.apiClient,
          onBackToLobby: () => Navigator.of(ctx).pop(),
          onEnterBoardroom: (PrivateRoom suite) {
            Navigator.of(ctx).pop();
            _enterSubRoom(suite.subRoomKey);
          },
        ),
      ),
    );
  }

  Future<void> _refreshWalletBalance() async {
    final ShestUser? user = _localAvatar?.user;
    if (user == null) return;
    try {
      final WalletInfo wallet = await widget.apiClient.wallet.getWalletInfo(
        user.id,
      );
      if (!mounted) return;
      setState(() => _walletInfo = wallet);
      _hub3d.send(<String, Object?>{
        'type': 'walletUpdated',
        'balance': wallet.usdtBalance,
      });
    } catch (_) {}
  }

  void _openShestCafeSheet() {
    final ShestUser? user = _localAvatar?.user;
    if (user == null) return;
    WordverseShestCafeSheet.show(
      context: context,
      apiClient: widget.apiClient,
      currentUser: user,
      onTransactionComplete: _refreshWalletBalance,
    );
  }

  void _onJoystickMove(StickDragDetails details) {
    // Con la escena 3D activa, el personaje lo mueve Three.js (cámara-relativo).
    if (_hub3d.isActive) {
      _hub3d.setInput(details.x, details.y);
      return;
    }
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

  void _onHub3DMoved(Hub3DMoved m) {
    final AvatarRoomNode? current = _localAvatar;
    if (current == null) return;
    final HotspotKind? detectedHotspot =
        RoomPhysicsController.detectNearbyHotspot(m.x, m.z);
    setState(() {
      _localAvatar = current.copyWith(
        normX: m.x,
        normZ: m.z,
        rotationRadians: m.rotation,
        isMoving: m.moving,
      );
      _nearbyHotspot = detectedHotspot;
    });
    if (m.moving) {
      _multiplayer.broadcastLocalMove(
        userId: current.user.id,
        x: m.x,
        z: m.z,
        rotation: m.rotation,
      );
    }
  }

  void _onHub3DInteract(String kind) {
    if (kind == Hub3DProtocol.cafeKind) {
      _openShestCafeSheet();
      return;
    }
    final HotspotKind? spot = Hub3DProtocol.hotspotFromKind(kind);
    if (spot != null) _handleHotspotAction(spot);
  }

  void _onHub3DSubRoomChanged(String roomName) {
    final String normalized = roomName == 'Sala Pública' ? 'Sala Principal' : roomName;
    if (_subRooms.contains(normalized) && _selectedSubRoom != normalized) {
      final AvatarRoomNode? local = _localAvatar;
      if (local != null) {
        _multiplayer.switchRoom(
          localUser: local.user,
          newRoomName: normalized,
        );
      }
      setState(() {
        _selectedSubRoom = normalized;
      });
    }
  }

  void _onHub3DAvatarTapped(String id, bool isLocal) {
    final AvatarRoomNode? local = _localAvatar;
    if (local == null) return;
    if (isLocal) {
      _handleHotspotAction(HotspotKind.myProfile);
      return;
    }
    for (final AvatarRoomNode node in _multiplayer.remoteAvatars) {
      if (node.user.id == id) {
        _handleAvatarTapped(node);
        return;
      }
    }
  }

  Future<void> _onHub3DKioskEscrowPurchase(Hub3DKioskEscrowPurchase purchase) async {
    final AvatarRoomNode? local = _localAvatar;
    if (local == null) return;
    try {
      await widget.apiClient.escrow.createEscrow(
        creatorId: local.user.id,
        counterpartyId: 'usr_vendor_${purchase.productId}',
        amount: purchase.amountUsdt > 0 ? purchase.amountUsdt : 100.0,
        description: 'Compra Kiosco 3D: ${purchase.productName}',
        conditions: 'Entrega de producto digital auditado vía Kiosco WordVerse',
      );
      if (_walletInfo != null) {
        final double newBalance = (_walletInfo!.usdtBalance - purchase.amountUsdt).clamp(0.0, double.infinity);
        setState(() {
          _walletInfo = _walletInfo!.copyWith(usdtBalance: newBalance);
        });
        _hub3d.send(<String, Object?>{
          'type': 'walletUpdated',
          'balance': newBalance,
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD4AF37),
            content: Text(
              'Contrato Escrow activado en Bóveda: ${purchase.productName} (${purchase.amountUsdt} USDT)',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sincronizando escrow de kiosco: $e');
    }
  }

  void _handleAvatarTapped(AvatarRoomNode tappedNode) {
    final AvatarRoomNode local = _localAvatar!;
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
      _floorTarget = (normX: finalX, normZ: finalZ);
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
    // Notificar al bus de eventos
    widget.apiClient.eventBus.emit(
      WordverseEventType.avatarSelected,
      'Has usado el emote ${emote.emoji} ${emote.label}',
      <String, Object?>{
        'userId': current.user.id,
        'emote': emote.name,
        'emoji': emote.emoji,
        'label': emote.label,
      },
    );
    // Limpiar el emote automáticamente tras 4 segundos
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (mounted && _localAvatar?.activeEmote == emote) {
        setState(() {
          _localAvatar = _localAvatar?.copyWith(activeEmote: null);
        });
      }
    });
    if (emote == WordverseEmote.p2p) {
      _handleHotspotAction(HotspotKind.p2p);
    } else if (emote == WordverseEmote.coffee) {
      _openShestCafeSheet();
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
                    const SizedBox(height: 14),
                    // Vista Previa del Diseño "WORDVERSE — GLOBAL BUSINESS HUB"
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: <Widget>[
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/wordverse_global_hub.jpg',
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) => const SizedBox.shrink(),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Colors.transparent,
                                  Color(0xEE061024),
                                ],
                              ),
                            ),
                            child: const Text(
                              'Ⓦ WORDVERSE • GLOBAL BUSINESS HUB (Salas Pública/Privada SHES\'T + Registro Mundial)',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('btn_verify_remote_connection'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.amberAccent,
                                side: const BorderSide(
                                  color: Colors.amberAccent,
                                ),
                              ),
                              onPressed: _isProbingConnection
                                  ? null
                                  : _probeRemoteConnection,
                              icon: _isProbingConnection
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.amberAccent,
                                      ),
                                    )
                                  : const Icon(Icons.network_check, size: 16),
                              label: Text(
                                _isProbingConnection
                                    ? 'Verificando...'
                                    : 'Probar Conexión',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          if (widget.apiClient.environment ==
                              ShestBackendEnvironment
                                  .supabaseStaging) ...<Widget>[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key('btn_copy_supabase_sql'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.cyanAccent,
                                  side: const BorderSide(
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                                onPressed: _copySupabaseSqlSchema,
                                icon: const Icon(Icons.copy_all, size: 16),
                                label: const Text(
                                  'Copiar SQL (7 Tablas)',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_connectionProbeMessage != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_connectionProbeOk ?? false)
                                ? Colors.green.withValues(alpha: 0.16)
                                : Colors.orange.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (_connectionProbeOk ?? false)
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                (_connectionProbeOk ?? false)
                                    ? Icons.check_circle
                                    : Icons.info_outline,
                                size: 16,
                                color: (_connectionProbeOk ?? false)
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _connectionProbeMessage!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 18),
                    // Portales de Selección de Experiencia (Master Prompt V2 - Sección 5)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('btn_gate_public_hub'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: WordVerseTokens.cianHolografico,
                              side: const BorderSide(
                                color: WordVerseTokens.cianHolografico,
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _openPublicHub,
                            icon: const Icon(Icons.public, size: 18),
                            label: const Text(
                              'PUBLIC HUB\n(Salas Públicas)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('btn_gate_private_suites'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: WordVerseTokens.oroLuminoso,
                              side: const BorderSide(
                                color: WordVerseTokens.oroPremium,
                                width: 1.2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _openPrivateSuites,
                            icon: const Icon(Icons.security, size: 18),
                            label: const Text(
                              'PRIVATE SUITES\n(The Boardroom)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const Key('btn_enter_wordverse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WordVerseTokens.oroPremium,
                          foregroundColor: WordVerseTokens.negroProfundo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _enterWordverseFromShestSession(
                          userId: _selectedGateUserId,
                        ),
                        icon: const Icon(Icons.view_in_ar, size: 20),
                        label: const Text(
                          'ENTRAR A WORDVERSE NEXUS 3D',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
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
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 768 || screenSize.shortestSide < 550;
    final AvatarRoomNode local = _localAvatar!;
    final List<WordverseEvent> events = widget.apiClient.eventBus.history;
    final WordverseEvent? latestMeaningfulEvent = events.cast<WordverseEvent?>().firstWhere(
      (e) => e != null && e.type.code != 'AVATAR_MOVED',
      orElse: () => events.isNotEmpty ? events.first : null,
    );
    final String latestEventText = latestMeaningfulEvent != null
        ? '[${latestMeaningfulEvent.type.code}] ${latestMeaningfulEvent.summary}'
        : 'Conectado a Shest API';

    return Scaffold(
      backgroundColor: const Color(0xFF050811),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // 1. Escenario Visual WordVerse: Modo Hub HD Fotorealista vs Modo Malla 3D WebGL
            if (_showArchitecturalBackdrop)
              Positioned.fill(
                child: Room3DViewport(
                  localAvatar: local,
                  remoteAvatars: _multiplayer.remoteAvatars,
                  activeHotspot: _nearbyHotspot,
                  cameraPitch: _cameraPitch,
                  cameraZoom: _cameraZoom,
                  cameraYaw: _cameraYaw,
                  subRoomName: _selectedSubRoom,
                  floorTarget: _floorTarget,
                  glbReport: _glbReport,
                  showArchitecturalBackdrop: true,
                  onFloorTapped: _onFloorTapped,
                  onOrbitDelta: (double delta) {
                    setState(() => _cameraYaw += delta);
                  },
                  onPitchDelta: (double delta) {
                    setState(() {
                      _cameraPitch = (_cameraPitch + delta).clamp(0.25, 0.82);
                    });
                  },
                  onShestCafeTapped: _openShestCafeSheet,
                  onHotspotTapped: _handleHotspotAction,
                  onAvatarTapped: _handleAvatarTapped,
                ),
              )
            else
              Positioned.fill(
                child: Hub3DView(
                  controller: _hub3d,
                  localAvatar: local,
                  remoteAvatars: _multiplayer.remoteAvatars,
                  subRoom: _selectedSubRoom,
                  cameraYaw: _cameraYaw,
                  cameraZoom: _cameraZoom,
                  cameraPitch: _cameraPitch,
                  includeCafe: true,
                  onMoved: _onHub3DMoved,
                  onInteract: _onHub3DInteract,
                  onAvatarTapped: _onHub3DAvatarTapped,
                  onSubRoomChanged: _onHub3DSubRoomChanged,
                  onKioskEscrowPurchase: _onHub3DKioskEscrowPurchase,
                  fallback: Room3DViewport(
                    localAvatar: local,
                    remoteAvatars: _multiplayer.remoteAvatars,
                    activeHotspot: _nearbyHotspot,
                    cameraPitch: _cameraPitch,
                    cameraZoom: _cameraZoom,
                    cameraYaw: _cameraYaw,
                    subRoomName: _selectedSubRoom,
                    floorTarget: _floorTarget,
                    glbReport: _glbReport,
                    showArchitecturalBackdrop: false,
                    onFloorTapped: _onFloorTapped,
                    onOrbitDelta: (double delta) {
                      setState(() => _cameraYaw += delta);
                    },
                    onPitchDelta: (double delta) {
                      setState(() {
                        _cameraPitch = (_cameraPitch + delta).clamp(0.25, 0.82);
                      });
                    },
                    onShestCafeTapped: _openShestCafeSheet,
                    onHotspotTapped: _handleHotspotAction,
                    onAvatarTapped: _handleAvatarTapped,
                  ),
                ),
              ),

            // 2. HUD Superior: Sesión Shest, Selector de Salas (Fase 8), Estado (Fase 16), Wallet USDT, Shest Coffee, Eventos y Reconexión
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

                        // Acceso Rápido al Ecosistema Public Hub
                        InkWell(
                          key: const Key('btn_hud_public_hub'),
                          onTap: _openPublicHub,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: WordVerseTokens.cianHolografico.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WordVerseTokens.cianHolografico.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const <Widget>[
                                Icon(Icons.public, size: 13, color: WordVerseTokens.cianHolografico),
                                SizedBox(width: 4),
                                Text(
                                  'Public Hub',
                                  style: TextStyle(
                                    color: WordVerseTokens.cianHolografico,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Acceso Rápido a The Boardroom & Suites VIP
                        InkWell(
                          key: const Key('btn_hud_private_suites'),
                          onTap: _openPrivateSuites,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: WordVerseTokens.oroPremium.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: WordVerseTokens.oroPremium.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const <Widget>[
                                Icon(Icons.lock_outline, size: 13, color: WordVerseTokens.oroLuminoso),
                                SizedBox(width: 4),
                                Text(
                                  'Suites VIP',
                                  style: TextStyle(
                                    color: WordVerseTokens.oroLuminoso,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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

                        // Píldora Wallet USDT TRC20 en vivo (Fase 19 / 26)
                        InkWell(
                          key: const Key('btn_hud_wallet'),
                          onTap: () => _handleHotspotAction(HotspotKind.p2p),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.greenAccent.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Text(
                              _walletInfo == null
                                  ? '💰 Wallet USDT'
                                  : '💰 ${_walletInfo!.usdtBalance.toStringAsFixed(0)} USDT',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Píldora Vitrina Oficial Shest Coffee & Glosario
                        InkWell(
                          key: const Key('btn_hud_shest_cafe'),
                          onTap: _openShestCafeSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF281E0D),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD4AF37)),
                            ),
                            child: const Text(
                              '☕ Shest Coffee',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Conmutador Vista Arquitectónica Global Business Hub HD vs Malla Holográfica 360°
                        InkWell(
                          key: const Key('btn_hud_toggle_hub_view'),
                          onTap: () {
                            setState(() {
                              _showArchitecturalBackdrop =
                                  !_showArchitecturalBackdrop;
                              if (_showArchitecturalBackdrop) {
                                _cameraYaw = 0.0;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _showArchitecturalBackdrop
                                  ? Colors.cyanAccent.withValues(alpha: 0.18)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _showArchitecturalBackdrop
                                    ? Colors.cyanAccent
                                    : Colors.white38,
                              ),
                            ),
                            child: Text(
                              _showArchitecturalBackdrop
                                  ? '🌐 Malla 2.5D'
                                  : '🏛️ Hub 3D Realista',
                              style: TextStyle(
                                color: _showArchitecturalBackdrop
                                    ? Colors.cyanAccent
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
                          onLongPress: () {
                            setState(() {
                              _showDebugTicker = !_showDebugTicker;
                            });
                          },
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

                        // Conmutador de Micrófono & Audio Espacial (Fase B)
                        IconButton(
                          key: const Key('btn_microphone_toggle'),
                          tooltip: _spatialAudio.isMicrophoneMuted
                              ? 'Activar Micrófono'
                              : 'Silenciar Micrófono',
                          icon: Icon(
                            _spatialAudio.isMicrophoneMuted
                                ? Icons.mic_off
                                : Icons.mic,
                            size: 16,
                            color: _spatialAudio.isMicrophoneMuted
                                ? Colors.redAccent
                                : Colors.greenAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              final bool muted = _spatialAudio.toggleMicrophone();
                              _hub3d.setSpeaking(
                                userId: _localAvatar?.user.id ?? 'local',
                                isSpeaking: !muted,
                              );
                            });
                          },
                        ),

                        // Indicador de Dispositivo Detectado: Móvil o PC
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            isMobile ? '📱 Móvil' : '💻 PC',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showDebugTicker) ...[
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
                ],
              ),
            ),

            // 3. Banner contextual cuando el Avatar entra en contacto con un Hotspot (Fase 27)
            if (_nearbyHotspot != null && !_hub3d.isActive)
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

            // 5. Guía de Controles Desktop (Solo en PC)
            if (!isMobile)
              Positioned(
                bottom: 14,
                left: 140,
                right: 250,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC050E20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      '⌨️ WASD/Flechas: Mover · Shift: Correr · Clic y arrastrar: Girar 360° · Rueda: Zoom · E: Interactuar',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            // 6. Joystick Táctil (Optimizado para móvil y utilizable en PC)
            Positioned(
              left: 14,
              bottom: 14,
              child: SizedBox(
                width: isMobile ? 104 : 92,
                height: isMobile ? 104 : 92,
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
