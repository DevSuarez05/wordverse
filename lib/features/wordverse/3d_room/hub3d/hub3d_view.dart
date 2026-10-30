import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/models/shest_models.dart';
import '../../avatar/avatar_node.dart';
import 'hub3d_backend.dart';
import 'hub3d_protocol.dart';

/// Permite al HUD de Flutter (joystick) controlar al personaje de la escena 3D.
class Hub3DController {
  _Hub3DViewState? _state;

  /// `true` cuando la escena 3D está cargada y es quien mueve al personaje.
  bool get isActive => _state?._ready ?? false;

  /// Entrada analógica del joystick: x derecha(+), y abajo(+), rango [-1, 1].
  void setInput(double x, double y) =>
      _state?._backend?.send(Hub3DProtocol.input(x, y));

  /// Notifica cambio de sub-sala directamente a la escena 3D.
  void setSubRoom(String name) =>
      _state?._backend?.send(Hub3DProtocol.subRoom(name));

  /// Envía un mensaje estructurado de protocolo a la escena 3D.
  void send(Map<String, Object?> message) => _state?._backend?.send(message);

  /// Notifica el estado de audio/voz de un usuario a la escena 3D.
  void setSpeaking({required String userId, required bool isSpeaking}) =>
      _state?._backend?.send(Hub3DProtocol.speaking(userId: userId, isSpeaking: isSpeaking));

  /// Teletransporta al avatar local a una zona o coordenadas específicas.
  void teleport({double? x, double? z, String? zone, double? rot}) =>
      _state?._backend?.send(Hub3DProtocol.teleport(x: x, z: z, zone: zone, rot: rot));
}

/// Sala 3D en tercera persona (Three.js) con visor 2.5D de respaldo.
///
/// - Si la plataforma no soporta la escena (tests, móvil) o falla WebGL / la
///   carga, se muestra [fallback].
/// - Flutter sigue siendo dueño del estado (posición, hotspot, Shest): la
///   escena reporta movimiento e interacciones mediante callbacks.
class Hub3DView extends StatefulWidget {
  const Hub3DView({
    super.key,
    required this.localAvatar,
    required this.remoteAvatars,
    required this.subRoom,
    required this.fallback,
    required this.onMoved,
    required this.onInteract,
    required this.onAvatarTapped,
    this.onSubRoomChanged,
    this.onKioskEscrowPurchase,
    this.onUserSpeaking,
    this.cameraYaw = 0,
    this.cameraZoom = 1,
    this.cameraPitch = 0.28,
    this.includeCafe = false,
    this.controller,
    this.loadTimeout = const Duration(seconds: 25),
  });

  final AvatarRoomNode localAvatar;
  final List<AvatarRoomNode> remoteAvatars;
  final String subRoom;
  final Widget fallback;
  final ValueChanged<Hub3DMoved> onMoved;
  final ValueChanged<String> onInteract;
  final void Function(String id, bool isLocal) onAvatarTapped;
  final ValueChanged<String>? onSubRoomChanged;
  final ValueChanged<Hub3DKioskEscrowPurchase>? onKioskEscrowPurchase;
  final ValueChanged<Hub3DUserSpeaking>? onUserSpeaking;
  final double cameraYaw;
  final double cameraZoom;
  final double cameraPitch;
  final bool includeCafe;
  final Hub3DController? controller;
  final Duration loadTimeout;

  @override
  State<Hub3DView> createState() => _Hub3DViewState();
}

class _Hub3DViewState extends State<Hub3DView> {
  Hub3DBackend? _backend;
  StreamSubscription<Map<String, Object?>>? _sub;
  Timer? _loadTimer;
  Timer? _remotesTimer;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _backend = createHub3DBackend();
    if (_backend == null) {
      _failed = true;
      return;
    }
    _sub = _backend!.messages.listen(_onMessage);
    _loadTimer = Timer(widget.loadTimeout, () {
      if (!_ready && mounted) setState(() => _failed = true);
    });
  }

  void _onMessage(Map<String, Object?> json) {
    final Hub3DEvent? event = Hub3DEvent.parse(json);
    switch (event) {
      case Hub3DReady():
        _loadTimer?.cancel();
        _backend?.send(
          Hub3DProtocol.init(
            local: widget.localAvatar,
            remotes: widget.remoteAvatars,
            subRoom: widget.subRoom,
            includeCafe: widget.includeCafe,
          ),
        );
        _backend?.send(
          Hub3DProtocol.camera(
            yaw: widget.cameraYaw,
            zoom: widget.cameraZoom,
            pitch: widget.cameraPitch,
          ),
        );
        if (mounted) setState(() => _ready = true);
      case Hub3DError():
        if (mounted) setState(() => _failed = true);
      case Hub3DMoved():
        widget.onMoved(event);
      case Hub3DInteract(:final String kind):
        widget.onInteract(kind);
      case Hub3DAvatarTapped(:final String id, :final bool isLocal):
        widget.onAvatarTapped(id, isLocal);
      case Hub3DSubRoomChanged(:final String name):
        widget.onSubRoomChanged?.call(name);
      case Hub3DKioskEscrowPurchase():
        widget.onKioskEscrowPurchase?.call(event);
      case Hub3DUserSpeaking():
        widget.onUserSpeaking?.call(event);
      case null:
        break;
    }
  }

  @override
  void didUpdateWidget(Hub3DView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._state = null;
      widget.controller?._state = this;
    }
    final Hub3DBackend? backend = _backend;
    if (backend == null || !_ready) return;

    if (old.subRoom != widget.subRoom) {
      backend.send(Hub3DProtocol.subRoom(widget.subRoom));
    }
    if (old.cameraYaw != widget.cameraYaw ||
        old.cameraZoom != widget.cameraZoom ||
        old.cameraPitch != widget.cameraPitch) {
      backend.send(
        Hub3DProtocol.camera(
          yaw: widget.cameraYaw,
          zoom: widget.cameraZoom,
          pitch: widget.cameraPitch,
        ),
      );
    }
    final WordverseEmote? emote = widget.localAvatar.activeEmote;
    if (emote != null && emote != old.localAvatar.activeEmote) {
      backend.send(Hub3DProtocol.emote('${emote.emoji} ${emote.label}'));
    }
    _scheduleRemotesSync();
  }

  /// Los remotos cambian con mucha frecuencia: se agrupan a ~12 Hz.
  void _scheduleRemotesSync() {
    if (_remotesTimer?.isActive ?? false) return;
    _remotesTimer = Timer(const Duration(milliseconds: 80), () {
      _backend?.send(Hub3DProtocol.remotes(widget.remoteAvatars));
    });
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _loadTimer?.cancel();
    _remotesTimer?.cancel();
    _sub?.cancel();
    _backend?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _backend == null) return widget.fallback;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _backend!.view,
        if (!_ready)
          const IgnorePointer(
            child: ColoredBox(
              color: Color(0xFF050B18),
              child: Center(
                child: Text(
                  'CARGANDO WORDVERSE HUB 3D…',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
