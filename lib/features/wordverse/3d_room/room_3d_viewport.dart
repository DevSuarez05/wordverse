import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/models/shest_models.dart';
import '../avatar/avatar_node.dart';
import '../movement/room_physics_controller.dart';
import 'glb_inspector.dart';
import 'hub_architecture_painter.dart';

/// Visor 3D Interactivo de la Sala Principal de WordVerse — Global Business Hub
/// (Fases 2, 5, 6, 7, 12, 27).
///
/// Inspirado en la arquitectura "WORDVERSE — GLOBAL BUSINESS HUB":
/// - Domo y cilindro LED superior con emblema VR WordVerse
/// - Holograma cilíndrico central "Registro de Empresas Mundiales" con mapa mundi
/// - Salas acristaladas de 2 niveles ("Sala de Reuniones Pública" y "Sala de Reuniones Privada" SHES'T)
/// - Kiosco interactivo "Compañía Privada" y Recepción curva "WordVerse"
/// - Tapete luminoso de Spawn "WORDVERSE" y estelas de datos holográficas
/// - Avatares ejecutivos de cuerpo completo con visor VR y etiquetas flotantes
class Room3DViewport extends StatelessWidget {
  const Room3DViewport({
    super.key,
    required this.localAvatar,
    required this.remoteAvatars,
    required this.activeHotspot,
    required this.cameraPitch,
    required this.cameraZoom,
    required this.onAvatarTapped,
    required this.onHotspotTapped,
    this.cameraYaw = 0.0,
    this.subRoomName = 'Sala Principal',
    this.onFloorTapped,
    this.onOrbitDelta,
    this.onPitchDelta,
    this.onShestCafeTapped,
    this.floorTarget,
    this.glbReport,
    this.showArchitecturalBackdrop = true,
  });

  final AvatarRoomNode localAvatar;
  final List<AvatarRoomNode> remoteAvatars;
  final HotspotKind? activeHotspot;
  final double cameraPitch;
  final double cameraZoom;
  final double cameraYaw;
  final String subRoomName;
  final ValueChanged<AvatarRoomNode> onAvatarTapped;
  final ValueChanged<HotspotKind> onHotspotTapped;
  final void Function(double normX, double normZ)? onFloorTapped;
  final ValueChanged<double>? onOrbitDelta;
  final ValueChanged<double>? onPitchDelta;
  final VoidCallback? onShestCafeTapped;
  final ({double normX, double normZ})? floorTarget;
  final GlbOptimizationReport? glbReport;
  final bool showArchitecturalBackdrop;

  /// Proyecta una coordenada 3D normalizada (x, z) en el plano del piso al lienzo 2D.
  static Offset projectToScreen(
    double normX,
    double normZ,
    Size size, {
    double pitch = 0.62,
    double zoom = 1.0,
    double yaw = 0.0,
  }) {
    return project3DToScreen(
      normX,
      0.0,
      normZ,
      size,
      pitch: pitch,
      zoom: zoom,
      yaw: yaw,
    );
  }

  /// Proyecta un vértice 3D completo (x, y, z) incluyendo su altura `normY` y rotación orbital `yaw`.
  static Offset project3DToScreen(
    double normX,
    double normY,
    double normZ,
    Size size, {
    double pitch = 0.62,
    double zoom = 1.0,
    double yaw = 0.0,
  }) {
    final double cosY = math.cos(yaw);
    final double sinY = math.sin(yaw);
    final double rx = (normX * cosY) - (normZ * sinY);
    final double rz = (normX * sinY) + (normZ * cosY);

    final double cx = size.width * 0.5;
    final double cy = size.height * 0.54;
    final double baseScale = math.min(size.width, size.height) * 0.42 * zoom;

    final double depthFactor = 1.0 + (rz * 0.28);
    final double screenX = cx + (rx * baseScale * depthFactor);
    final double elevationPx = normY * baseScale * 0.85 * depthFactor;
    final double screenY = cy + (rz * baseScale * pitch) - elevationPx;
    return Offset(screenX, screenY);
  }

  /// Desproyecta un toque en pantalla 2D a coordenadas (normX, normZ) del piso 3D.
  static ({double normX, double normZ}) unprojectScreenToFloor(
    Offset localPosition,
    Size size, {
    double pitch = 0.62,
    double zoom = 1.0,
    double yaw = 0.0,
  }) {
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.54;
    final double baseScale = math.min(size.width, size.height) * 0.42 * zoom;
    final double rz = ((localPosition.dy - cy) / (baseScale * pitch)).clamp(
      -RoomPhysicsController.maxBound,
      RoomPhysicsController.maxBound,
    );
    final double depthFactor = 1.0 + (rz * 0.28);
    final double rx =
        ((localPosition.dx - cx) / (baseScale * depthFactor)).clamp(
          -RoomPhysicsController.maxBound,
          RoomPhysicsController.maxBound,
        );
    final double cosY = math.cos(-yaw);
    final double sinY = math.sin(-yaw);
    final double normX = ((rx * cosY) - (rz * sinY)).clamp(
      -RoomPhysicsController.maxBound,
      RoomPhysicsController.maxBound,
    );
    final double normZ = ((rx * sinY) + (rz * cosY)).clamp(
      -RoomPhysicsController.maxBound,
      RoomPhysicsController.maxBound,
    );
    return (normX: normX, normZ: normZ);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size canvasSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        final List<AvatarRoomNode> allAvatars = <AvatarRoomNode>[
          ...remoteAvatars,
          localAvatar,
        ]..sort(
            (AvatarRoomNode a, AvatarRoomNode b) => a.normZ.compareTo(b.normZ),
          );

        final double normalizedYaw =
            ((cameraYaw % (math.pi * 2)) + (math.pi * 2)) % (math.pi * 2);
        final double yawDeviation = math.min(
          normalizedYaw,
          (math.pi * 2) - normalizedYaw,
        );
        // El fondo arquitectónico HD se muestra nítido en vista frontal y se atenúa suavemente al orbitar 360°
        final double backdropOpacity = showArchitecturalBackdrop
            ? (1.0 - (yawDeviation / 1.4)).clamp(0.18, 0.88)
            : 0.0;

        return _HubClock(
          builder: (BuildContext context, Animation<double> clock) {
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // 0. Capa Arquitectónica Fotorrealista "WORDVERSE GLOBAL BUSINESS HUB"
                if (backdropOpacity > 0.01)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: backdropOpacity,
                        child: Transform.scale(
                          scale: cameraZoom.clamp(0.85, 1.25),
                          child: Image.asset(
                            'assets/images/wordverse_global_hub.jpg',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            color: _tintForSubRoom(),
                            colorBlendMode: subRoomName == 'Sala Principal'
                                ? BlendMode.dst
                                : BlendMode.color,
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 1. Escenario 3D Holográfico + Malla binaria .GLB + Arquitectura Global Hub
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (DragUpdateDetails details) {
                      if (onOrbitDelta != null) {
                        onOrbitDelta!(details.delta.dx * 0.006);
                      }
                      if (onPitchDelta != null) {
                        onPitchDelta!(-details.delta.dy * 0.003);
                      }
                    },
                    onTapUp: (TapUpDetails details) {
                      if (onFloorTapped == null) return;
                      final ({double normX, double normZ}) target =
                          unprojectScreenToFloor(
                            details.localPosition,
                            canvasSize,
                            pitch: cameraPitch,
                            zoom: cameraZoom,
                            yaw: cameraYaw,
                          );
                      onFloorTapped!(target.normX, target.normZ);
                    },
                    child: CustomPaint(
                      painter: _Room3DScenePainter(
                        pitch: cameraPitch,
                        zoom: cameraZoom,
                        yaw: cameraYaw,
                        subRoomName: subRoomName,
                        activeHotspot: activeHotspot,
                        floorTarget: floorTarget,
                        glbReport: glbReport,
                        hasBackdropImage: backdropOpacity > 0.35,
                        clock: clock,
                      ),
                    ),
                  ),
                ),

                // 1.2. Cilindro Holográfico Central "Registro de Empresas Mundiales" (solo en modo vectorial sin fondo)
                if (backdropOpacity <= 0.35)
                  _buildCentralWorldRegistryBanner(canvasSize),

                // 1.5. Marcador 3D Interactivo sobre la Barra de Shest Coffee (-0.42, 0.22, -0.58)
                if (onShestCafeTapped != null && (backdropOpacity <= 0.35 || activeHotspot != null))
                  _buildShestCafeBarMarker(canvasSize),

                // 2. Hotspots Interactivos: En modo HD solo muestra el hotspot activo cercano para no tapar la escena
                for (final HotspotKind spot in HotspotKind.values)
                  if (backdropOpacity <= 0.35 || activeHotspot == spot)
                    _buildHotspotMarker(spot, canvasSize),

                // 3. Avatares Ejecutivos VR (Local + Remotos Multiplayer) con etiqueta holográfica (Fase 5)
                for (final AvatarRoomNode avatar in allAvatars)
                  _buildAvatarMarker(avatar, canvasSize, clock.value),
              ],
            );
          },
        );
      },
    );
  }

  Color? _tintForSubRoom() {
    switch (subRoomName) {
      case 'Shest Café':
        return const Color(0x55D4AF37);
      case 'P2P':
        return const Color(0x3300E676);
      case 'Escrow':
        return const Color(0x33FFD740);
      case 'Negocios':
        return const Color(0x33E040FB);
      default:
        return null;
    }
  }

  /// Cartel holográfico interactivo sobre el núcleo central "Registro de Empresas Mundiales".
  Widget _buildCentralWorldRegistryBanner(Size canvasSize) {
    final Offset centerTop = project3DToScreen(
      0.0,
      0.32,
      0.0,
      canvasSize,
      pitch: cameraPitch,
      zoom: cameraZoom,
      yaw: cameraYaw,
    );

    return Positioned(
      left: centerTop.dx - 115,
      top: centerTop.dy - 36,
      width: 230,
      child: GestureDetector(
        key: const Key('marker_world_companies_registry'),
        behavior: HitTestBehavior.translucent,
        onTap: () => onHotspotTapped(HotspotKind.networking),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Cilindro LED Superior "WORDVERSE GLOBAL BUSINESS HUB"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xEE07142B),
                    Color(0xEE0D284D),
                    Color(0xEE07142B),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.85),
                  width: 1.4,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.cyanAccent.withValues(alpha: 0.38),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent, width: 1.4),
                      color: const Color(0xFF0A2246),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'W',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.cyanAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'WORDVERSE • GLOBAL BUSINESS HUB',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '🌐 Registro de Empresas Mundiales',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.0,
                            fontWeight: FontWeight.w700,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotspotMarker(HotspotKind spot, Size canvasSize) {
    final Offset pos = projectToScreen(
      spot.normX,
      spot.normZ,
      canvasSize,
      pitch: cameraPitch,
      zoom: cameraZoom,
      yaw: cameraYaw,
    );
    final bool isHighlighted = activeHotspot == spot;
    final Color spotColor = _hotspotColor(spot);
    final String hubZoneLabel = _hubArchitecturalZoneLabel(spot);

    return Positioned(
      left: pos.dx - 68,
      top: pos.dy - 28,
      width: 136,
      child: GestureDetector(
        key: Key('hotspot_${spot.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onHotspotTapped(spot),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHighlighted
                  ? <Color>[
                      spotColor.withValues(alpha: 0.42),
                      const Color(0xEE0B1D3A),
                    ]
                  : const <Color>[
                      Color(0xDD0A1730),
                      Color(0xDD060E1F),
                    ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHighlighted
                  ? Colors.white
                  : spotColor.withValues(alpha: 0.85),
              width: isHighlighted ? 2.0 : 1.3,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: spotColor.withValues(alpha: isHighlighted ? 0.65 : 0.30),
                blurRadius: isHighlighted ? 14 : 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _hotspotIcon(spot),
                    size: 10,
                    color: spotColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    spot.code,
                    style: TextStyle(
                      fontSize: 8.0,
                      fontWeight: FontWeight.w800,
                      color: spotColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Text(
                spot.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                hubZoneLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.cyanAccent.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _hubArchitecturalZoneLabel(HotspotKind spot) {
    switch (spot) {
      case HotspotKind.networking:
        return 'Sala Reuniones Pública • SHES\'T';
      case HotspotKind.createMeeting:
        return 'Holograma Empresas Mundiales';
      case HotspotKind.qr:
        return 'Kiosco • Compañía Privada';
      case HotspotKind.p2p:
        return 'Sala Reuniones Privada • SHES\'T';
      case HotspotKind.escrow:
        return 'Recepción WordVerse • Escrow';
      case HotspotKind.myProfile:
        return 'Tapete WordVerse • Perfil VR';
      case HotspotKind.exit:
        return 'Portal Salida • Shest Hub';
    }
  }

  static IconData _hotspotIcon(HotspotKind spot) {
    switch (spot) {
      case HotspotKind.networking:
        return Icons.public;
      case HotspotKind.createMeeting:
        return Icons.groups_3;
      case HotspotKind.qr:
        return Icons.qr_code_scanner;
      case HotspotKind.p2p:
        return Icons.currency_exchange;
      case HotspotKind.escrow:
        return Icons.verified_user;
      case HotspotKind.myProfile:
        return Icons.vrpano;
      case HotspotKind.exit:
        return Icons.exit_to_app;
    }
  }

  Widget _buildAvatarMarker(AvatarRoomNode node, Size canvasSize, [double clockPhase = 0.0]) {
    final Offset pos = projectToScreen(
      node.normX,
      node.normZ,
      canvasSize,
      pitch: cameraPitch,
      zoom: cameraZoom,
      yaw: cameraYaw,
    );
    final Color avatarColor = Color(node.user.avatarHexColor);
    final int styleVariant = node.user.id.hashCode.abs() % 3;

    return Positioned(
      left: pos.dx - 70,
      top: pos.dy - 142,
      width: 140,
      child: GestureDetector(
        key: Key('avatar_${node.user.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onAvatarTapped(node),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (node.activeEmote != null)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Colors.black54, blurRadius: 6),
                  ],
                ),
                child: Text(
                  '${node.activeEmote!.emoji} ${node.activeEmote!.label}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            // Cápsula Holográfica de Identificación (Estilo "Compañía Privada" en AR)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: node.isLocalPlayer
                      ? const <Color>[Color(0xF0082240), Color(0xF0051224)]
                      : const <Color>[Color(0xEA09162B), Color(0xEA050C17)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: node.isLocalPlayer
                      ? Colors.cyanAccent
                      : (node.user.isFavorite ? Colors.amberAccent : avatarColor.withValues(alpha: 0.85)),
                  width: node.isLocalPlayer ? 1.4 : 1.0,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: (node.isLocalPlayer ? Colors.cyanAccent : avatarColor).withValues(alpha: 0.35),
                    blurRadius: 7,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Etiqueta flotante roja/cian tipo "Compañía Privada" como en el concepto
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    margin: const EdgeInsets.only(bottom: 1.5),
                    decoration: BoxDecoration(
                      color: node.isLocalPlayer
                          ? const Color(0xDD00E5FF).withValues(alpha: 0.25)
                          : const Color(0xDDFF4050).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: node.isLocalPlayer ? Colors.cyanAccent : const Color(0xFFFF5252),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      node.user.company.isNotEmpty ? node.user.company : 'Compañía Privada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        color: node.isLocalPlayer ? Colors.cyanAccent : const Color(0xFFFF7B7B),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (node.user.isFavorite)
                        const Padding(
                          padding: EdgeInsets.only(right: 2.5),
                          child: Text('⭐', style: TextStyle(fontSize: 8)),
                        ),
                      Flexible(
                        child: Text(
                          node.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '●',
                        style: TextStyle(
                          fontSize: 8.0,
                          color: _statusColor(node.user.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Línea de rayo holográfico sutil entre la etiqueta y las gafas inteligentes
            Container(
              width: 1.0,
              height: 4.0,
              color: (node.isLocalPlayer ? Colors.cyanAccent : avatarColor).withValues(alpha: 0.45),
            ),
            // Figura Ejecutiva 3D de alta fidelidad: traje sastre, zapatos pulidos, visor AR y tablet
            SizedBox(
              width: 60,
              height: 94,
              child: CustomPaint(
                painter: _ExecutiveVrAvatarPainter(
                  accentColor: avatarColor,
                  isLocalPlayer: node.isLocalPlayer,
                  isMoving: node.isMoving,
                  initials: node.user.avatarInitials,
                  phase: clockPhase,
                  variant: styleVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(UserPresenceStatus status) {
    switch (status) {
      case UserPresenceStatus.available:
        return Colors.greenAccent;
      case UserPresenceStatus.busy:
        return Colors.amberAccent;
      case UserPresenceStatus.unavailable:
        return Colors.redAccent;
    }
  }

  static Color _hotspotColor(HotspotKind spot) {
    switch (spot) {
      case HotspotKind.networking:
        return Colors.cyanAccent;
      case HotspotKind.createMeeting:
        return Colors.lightBlueAccent;
      case HotspotKind.qr:
        return Colors.amberAccent;
      case HotspotKind.p2p:
        return Colors.greenAccent;
      case HotspotKind.escrow:
        return const Color(0xFFFFD740);
      case HotspotKind.myProfile:
        return Colors.cyanAccent;
      case HotspotKind.exit:
        return Colors.redAccent;
    }
  }

  Widget _buildShestCafeBarMarker(Size canvasSize) {
    final Offset pos = project3DToScreen(
      -0.42,
      0.24,
      -0.58,
      canvasSize,
      pitch: cameraPitch,
      zoom: cameraZoom,
      yaw: cameraYaw,
    );
    const Color gold = Color(0xFFD4AF37);

    return Positioned(
      left: pos.dx - 58,
      top: pos.dy - 20,
      width: 116,
      child: GestureDetector(
        key: const Key('marker_shest_cafe_bar'),
        behavior: HitTestBehavior.opaque,
        onTap: onShestCafeTapped,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xEE120E07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: gold, width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: gold.withValues(alpha: 0.45),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '☕ SHEST COFFEE',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  color: gold,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                'Catálogo & USDT',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dibuja un Avatar Ejecutivo de Cuerpo Completo con Traje Corporativo de Alta Gama,
/// Zapatos Formales de Cuero, Visor AR/VR Inteligente con Escaneo Activo,
/// y Tablet Holográfica con Proyección Luminosa, idéntico a la visión conceptual.
class _ExecutiveVrAvatarPainter extends CustomPainter {
  const _ExecutiveVrAvatarPainter({
    required this.accentColor,
    required this.isLocalPlayer,
    required this.isMoving,
    required this.initials,
    this.phase = 0.0,
    this.variant = 0,
  });

  final Color accentColor;
  final bool isLocalPlayer;
  final bool isMoving;
  final String initials;
  final double phase;
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width * 0.5;
    final double groundY = size.height - 4.0;
    final double walkCycle = isMoving ? math.sin(phase * 2 * math.pi * 4.5) : 0.0;
    final double breath = math.sin(phase * 2 * math.pi) * 0.7;

    // 1. Sombra suave de contacto en el piso pulido
    final Rect footShadow = Rect.fromCenter(
      center: Offset(cx, groundY),
      width: 32,
      height: 7.5,
    );
    canvas.drawOval(
      footShadow,
      Paint()
        ..color = const Color(0x77000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );

    // 2. Anillo de presencia espacial AR con puntos cardinales
    final Rect presenceRing = Rect.fromCenter(
      center: Offset(cx, groundY),
      width: 36,
      height: 10,
    );
    final Color ringColor = isLocalPlayer ? Colors.cyanAccent : accentColor;
    canvas.drawOval(
      presenceRing,
      Paint()
        ..color = ringColor.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      presenceRing,
      Paint()
        ..color = ringColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLocalPlayer ? 1.5 : 1.1,
    );
    // Notches cardinales holográficos
    for (int i = 0; i < 4; i++) {
      final double ang = (i * math.pi / 2) + (phase * math.pi);
      final double nx = cx + (math.cos(ang) * 18);
      final double ny = groundY + (math.sin(ang) * 5);
      canvas.drawCircle(
        Offset(nx, ny),
        1.0,
        Paint()..color = ringColor,
      );
    }

    // 3. Piernas y Zapatos ejecutivos
    final double leftLegOffset = walkCycle * 2.8;
    final double rightLegOffset = -walkCycle * 2.8;

    // Zapatos formales de cuero negro con brillo especular
    final Paint shoePaint = Paint()..color = const Color(0xFF090D17);
    final Paint shoeShine = Paint()..color = const Color(0xFF475569);

    final RRect leftShoe = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 9.0, groundY - 3.5 - leftLegOffset, 6.8, 3.8),
      const Radius.circular(1.5),
    );
    final RRect rightShoe = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + 2.2, groundY - 3.5 - rightLegOffset, 6.8, 3.8),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(leftShoe, shoePaint);
    canvas.drawRRect(rightShoe, shoePaint);
    canvas.drawLine(Offset(cx - 8.5, groundY - 2.8 - leftLegOffset), Offset(cx - 3.5, groundY - 2.8 - leftLegOffset), shoeShine);
    canvas.drawLine(Offset(cx + 2.7, groundY - 2.8 - rightLegOffset), Offset(cx + 7.7, groundY - 2.8 - rightLegOffset), shoeShine);

    // Pantalón sastre oscuro con raya planchada o falda ejecutiva
    final Paint suitFabric = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(Offset.zero & size);

    if (variant == 2) {
      // Falda sastre ejecutiva (diseño ejecutivo femenino formal)
      final Path skirt = Path()
        ..moveTo(cx - 9.5, 46)
        ..lineTo(cx + 9.5, 46)
        ..lineTo(cx + 10.5, 66)
        ..lineTo(cx - 10.5, 66)
        ..close();
      canvas.drawPath(skirt, suitFabric);
      // Piernas con medias ejecutivas
      final Paint legsPaint = Paint()..color = const Color(0xFF262E3D);
      canvas.drawRect(Rect.fromLTWH(cx - 7.5, 66, 4.5, groundY - 70 - leftLegOffset), legsPaint);
      canvas.drawRect(Rect.fromLTWH(cx + 3.0, 66, 4.5, groundY - 70 - rightLegOffset), legsPaint);
    } else {
      // Pantalón de traje formal con caída recta
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - 8.8, 48 - (leftLegOffset * 0.2), cx - 2.0, groundY - 3 - leftLegOffset),
          const Radius.circular(2.0),
        ),
        suitFabric,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cx + 2.0, 48 - (rightLegOffset * 0.2), cx + 8.8, groundY - 3 - rightLegOffset),
          const Radius.circular(2.0),
        ),
        suitFabric,
      );
      // Línea de planchado central sutil
      final Paint creasePaint = Paint()..color = const Color(0x22FFFFFF)..strokeWidth = 0.8;
      canvas.drawLine(Offset(cx - 5.4, 52), Offset(cx - 5.4, groundY - 4 - leftLegOffset), creasePaint);
      canvas.drawLine(Offset(cx + 5.4, 52), Offset(cx + 5.4, groundY - 4 - rightLegOffset), creasePaint);
    }

    // 4. Torso: Saco Ejecutivo formal con solapas (blazer) y hombreras estructuradas
    final Path jacketPath = Path()
      ..moveTo(cx - 13.5, 23.5)
      ..lineTo(cx + 13.5, 23.5)
      ..lineTo(cx + 10.5, 48.0 + (breath * 0.5))
      ..lineTo(cx - 10.5, 48.0 + (breath * 0.5))
      ..close();

    canvas.drawPath(
      jacketPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF1E2D44),
            variant == 1 ? const Color(0xFF131E2E) : const Color(0xFF0F172A),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      jacketPath,
      Paint()
        ..color = const Color(0xFF334155).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Camisa formal blanca en escote V
    final Path shirtPath = Path()
      ..moveTo(cx - 4.5, 23.5)
      ..lineTo(cx + 4.5, 23.5)
      ..lineTo(cx, 38.0)
      ..close();
    canvas.drawPath(shirtPath, Paint()..color = const Color(0xFFF8FAFC));

    // Corbata de seda ejecutiva con pisacorbatas
    final Path tie = Path()
      ..moveTo(cx - 1.8, 24.5)
      ..lineTo(cx + 1.8, 24.5)
      ..lineTo(cx + 2.2, 38.0)
      ..lineTo(cx, 40.5)
      ..lineTo(cx - 2.2, 38.0)
      ..close();
    canvas.drawPath(tie, Paint()..color = ringColor);
    // Pisacorbatas metálico
    canvas.drawLine(Offset(cx - 1.5, 32.0), Offset(cx + 1.5, 32.0), Paint()..color = Colors.white..strokeWidth = 1.0);

    // Solapas del saco (notched lapels)
    final Path leftLapel = Path()
      ..moveTo(cx - 13.5, 23.5)
      ..lineTo(cx - 4.5, 23.5)
      ..lineTo(cx - 1.0, 39.0)
      ..lineTo(cx - 6.5, 33.0)
      ..close();
    final Path rightLapel = Path()
      ..moveTo(cx + 13.5, 23.5)
      ..lineTo(cx + 4.5, 23.5)
      ..lineTo(cx + 1.0, 39.0)
      ..lineTo(cx + 6.5, 33.0)
      ..close();
    final Paint lapelPaint = Paint()..color = const Color(0xFF172338);
    canvas.drawPath(leftLapel, lapelPaint);
    canvas.drawPath(rightLapel, lapelPaint);

    // Pañuelo de bolsillo blanco o pin VIP
    canvas.drawLine(Offset(cx - 9.0, 29.5), Offset(cx - 5.5, 29.5), Paint()..color = Colors.white..strokeWidth = 1.2);

    // Botones del saco
    final Paint btnPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawCircle(Offset(cx, 41.5), 0.9, btnPaint);
    canvas.drawCircle(Offset(cx, 45.0), 0.9, btnPaint);

    // 5. Brazos y Tablet holográfica interactiva en la mano
    // Brazo izquierdo (relajado al costado con puño blanco y mano)
    final Path leftArm = Path()
      ..moveTo(cx - 13.5, 23.5)
      ..lineTo(cx - 10.5, 43.0)
      ..lineTo(cx - 12.8, 43.0)
      ..lineTo(cx - 15.5, 25.5)
      ..close();
    canvas.drawPath(leftArm, suitFabric);
    canvas.drawRect(Rect.fromLTWH(cx - 13.0, 42.5, 2.5, 1.2), Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx - 11.8, 45.0), 1.8, Paint()..color = const Color(0xFFE2B79A));

    // Brazo derecho (levantado sosteniendo la tablet/dispositivo holográfico como en la foto)
    final Path rightArm = Path()
      ..moveTo(cx + 13.5, 23.5)
      ..lineTo(cx + 14.5, 33.0)
      ..lineTo(cx + 8.5, 33.0)
      ..lineTo(cx + 11.5, 24.5)
      ..close();
    canvas.drawPath(rightArm, suitFabric);
    canvas.drawCircle(Offset(cx + 7.5, 32.5), 1.8, Paint()..color = const Color(0xFFE2B79A));

    // Tablet holográfica en perspectiva con datos activos
    final Rect tabletRect = Rect.fromCenter(center: Offset(cx + 11.5, 29.0), width: 13.5, height: 8.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tabletRect, const Radius.circular(2.0)),
      Paint()..color = Colors.cyanAccent.withValues(alpha: 0.38),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tabletRect, const Radius.circular(2.0)),
      Paint()
        ..color = Colors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    // Micro líneas de datos de la tablet
    for (int l = 0; l < 2; l++) {
      final double ly = tabletRect.top + 2.5 + (l * 2.5);
      canvas.drawLine(
        Offset(tabletRect.left + 2.0, ly),
        Offset(tabletRect.right - 2.0, ly),
        Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = 0.8,
      );
    }
    // Haz holográfico sutil proyectándose hacia arriba
    final Path beamPath = Path()
      ..moveTo(tabletRect.left, tabletRect.top)
      ..lineTo(tabletRect.right, tabletRect.top)
      ..lineTo(tabletRect.right + 2.5, tabletRect.top - 6.0)
      ..lineTo(tabletRect.left - 2.5, tabletRect.top - 6.0)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[Colors.cyanAccent.withValues(alpha: 0.28), Colors.cyanAccent.withValues(alpha: 0.0)],
        ).createShader(beamPath.getBounds()),
    );

    // 6. Cuello y Cabeza con Peinado Ejecutivo
    // Cuello
    canvas.drawRect(Rect.fromLTWH(cx - 2.8, 18.0, 5.6, 6.0), Paint()..color = const Color(0xFFE2B79A));
    // Cabeza
    final Offset headCenter = Offset(cx, 13.5);
    canvas.drawCircle(headCenter, 7.0, Paint()..color = const Color(0xFFE2B79A));

    // Cabello corporativo
    final Paint hairPaint = Paint()..color = variant == 1 ? const Color(0xFF1E1B18) : const Color(0xFF0F172A);
    if (variant == 2) {
      // Corte Bob ejecutivo femenino
      final Path hairBob = Path()
        ..addArc(Rect.fromCircle(center: headCenter.translate(0, -0.5), radius: 7.6), math.pi * 0.9, math.pi * 1.2)
        ..lineTo(cx + 7.5, 17.5)
        ..lineTo(cx + 6.0, 18.0)
        ..lineTo(cx - 6.0, 18.0)
        ..lineTo(cx - 7.5, 17.5)
        ..close();
      canvas.drawPath(hairBob, hairPaint);
    } else {
      // Peinado corto clásico con raya lateral
      canvas.drawArc(
        Rect.fromCircle(center: headCenter.translate(0, -0.8), radius: 7.4),
        math.pi * 0.85,
        math.pi * 1.3,
        true,
        hairPaint,
      );
    }

    // 7. Gafas Inteligentes / Visor AR WordVerse (Fiel a la imagen)
    final RRect vrVisor = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 13.6), width: 14.5, height: 4.8),
      const Radius.circular(2.4),
    );
    canvas.drawRRect(vrVisor, Paint()..color = const Color(0xFF030816));
    canvas.drawRRect(
      vrVisor,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    // Línea de brillo cian emisiva del lente AR
    canvas.drawLine(
      Offset(cx - 5.0, 13.6),
      Offset(cx + 5.0, 13.6),
      Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 1.4,
    );
    // Láser de escaneo animado en movimiento
    final double scanX = cx - 4.5 + (((phase * 2.4) % 1.0) * 9.0);
    canvas.drawCircle(
      Offset(scanX, 13.6),
      1.1,
      Paint()..color = Colors.white,
    );
    // LED de estado en la patilla de las gafas
    canvas.drawCircle(
      Offset(cx + 6.5, 13.6),
      0.9,
      Paint()..color = isLocalPlayer ? Colors.greenAccent : Colors.cyanAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _ExecutiveVrAvatarPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.isLocalPlayer != isLocalPlayer ||
        oldDelegate.isMoving != isMoving ||
        oldDelegate.initials != initials ||
        oldDelegate.phase != phase ||
        oldDelegate.variant != variant;
  }
}

/// Reloj de animación compartido (estelas de datos, pulsos de pantallas).
/// Respeta "reducir animaciones" del sistema y se libera con el widget.
class _HubClock extends StatefulWidget {
  const _HubClock({required this.builder});

  final Widget Function(BuildContext context, Animation<double> clock) builder;

  @override
  State<_HubClock> createState() => _HubClockState();
}

class _HubClockState extends State<_HubClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

class _Room3DScenePainter extends CustomPainter {
  _Room3DScenePainter({
    required this.pitch,
    required this.zoom,
    required this.yaw,
    required this.subRoomName,
    required this.activeHotspot,
    required Animation<double> clock,
    this.floorTarget,
    this.glbReport,
    this.hasBackdropImage = false,
  }) : _clock = clock,
       super(repaint: clock);

  final Animation<double> _clock;

  final double pitch;
  final double zoom;
  final double yaw;
  final String subRoomName;
  final HotspotKind? activeHotspot;
  final ({double normX, double normZ})? floorTarget;
  final GlbOptimizationReport? glbReport;
  final bool hasBackdropImage;

  Color _accentForSubRoom() {
    switch (subRoomName) {
      case 'Shest Café':
        return const Color(0xFFD4AF37);
      case 'P2P':
        return Colors.greenAccent;
      case 'Escrow':
        return Colors.amberAccent;
      case 'Negocios':
        return Colors.purpleAccent;
      case 'Networking':
        return Colors.lightBlueAccent;
      default:
        return Colors.cyanAccent;
    }
  }

  List<Color> _bgGradientForSubRoom() {
    if (subRoomName == 'Shest Café') {
      return const <Color>[
        Color(0xFF281E0D),
        Color(0xFF140F07),
        Color(0xFF080603),
      ];
    }
    return const <Color>[
      Color(0xFF1B3058),
      Color(0xFF0C1830),
      Color(0xFF050A14),
    ];
  }

  List<Color> _floorGradientForSubRoom() {
    if (subRoomName == 'Shest Café') {
      return <Color>[
        const Color(0xFF2A2012).withValues(alpha: hasBackdropImage ? 0.28 : 0.92),
        const Color(0xFF120E08).withValues(alpha: hasBackdropImage ? 0.38 : 0.96),
      ];
    }
    return <Color>[
      const Color(0xFF1E325C).withValues(alpha: hasBackdropImage ? 0.22 : 0.88),
      const Color(0xFF0D182E).withValues(alpha: hasBackdropImage ? 0.34 : 0.95),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Color roomAccent = _accentForSubRoom();
    final Rect fullRect = Offset.zero & size;

    // 1. Iluminación ambiental del espacio virtual 3D (transparente cuando el render HD está activo)
    if (!hasBackdropImage) {
      final Paint bgPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.25),
          radius: 1.15,
          colors: _bgGradientForSubRoom(),
        ).createShader(fullRect);
      canvas.drawRect(fullRect, bgPaint);
    }

    // 2. Polígono del piso 3D dentro de los límites de colisión [-0.82 .. 0.82]
    const double b = RoomPhysicsController.maxBound;
    final Offset topLeft = Room3DViewport.projectToScreen(
      -b,
      -b,
      size,
      pitch: pitch,
      zoom: zoom,
      yaw: yaw,
    );
    final Offset topRight = Room3DViewport.projectToScreen(
      b,
      -b,
      size,
      pitch: pitch,
      zoom: zoom,
      yaw: yaw,
    );
    final Offset bottomRight = Room3DViewport.projectToScreen(
      b,
      b,
      size,
      pitch: pitch,
      zoom: zoom,
      yaw: yaw,
    );
    final Offset bottomLeft = Room3DViewport.projectToScreen(
      -b,
      b,
      size,
      pitch: pitch,
      zoom: zoom,
      yaw: yaw,
    );

    final Path floorPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    final Paint floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _floorGradientForSubRoom(),
      ).createShader(fullRect);
    canvas.drawPath(floorPath, floorPaint);

    // 3. Retícula 3D de perspectiva sobre el piso corporativo
    final Paint gridPaint = Paint()
      ..color = roomAccent.withValues(alpha: hasBackdropImage ? 0.12 : 0.20)
      ..strokeWidth = 1.0;

    for (int i = -4; i <= 4; i++) {
      final double t = (i / 4.0) * b;
      final Offset p1 = Room3DViewport.projectToScreen(
        t,
        -b,
        size,
        pitch: pitch,
        zoom: zoom,
        yaw: yaw,
      );
      final Offset p2 = Room3DViewport.projectToScreen(
        t,
        b,
        size,
        pitch: pitch,
        zoom: zoom,
        yaw: yaw,
      );
      canvas.drawLine(p1, p2, gridPaint);

      final Offset q1 = Room3DViewport.projectToScreen(
        -b,
        t,
        size,
        pitch: pitch,
        zoom: zoom,
        yaw: yaw,
      );
      final Offset q2 = Room3DViewport.projectToScreen(
        b,
        t,
        size,
        pitch: pitch,
        zoom: zoom,
        yaw: yaw,
      );
      canvas.drawLine(q1, q2, gridPaint);
    }

    // 3.5. Muros, salas de reuniones y pantallas del Hub (arquitectura procedural)
    final HubArchitecturePainter hub = HubArchitecturePainter(
      project: (double x, double y, double z) => Room3DViewport.project3DToScreen(
        x,
        y,
        z,
        size,
        pitch: pitch,
        zoom: zoom,
        yaw: yaw,
      ),
      yaw: yaw,
      accent: roomAccent,
      opacity: hasBackdropImage ? 0.55 : 1.0,
      phase: _clock.value,
    );
    hub.paintShell(canvas);

    // 4. Renderizado de Malla 3D Real decodificada desde `01_sala_principal.glb`
    final GlbOptimizationReport? report = glbReport;
    if (report != null &&
        report.vertices.isNotEmpty &&
        report.triangles.isNotEmpty) {
      final Paint meshFillPaint = Paint()
        ..color = (subRoomName == 'Shest Café'
                ? const Color(0xFF4A3718)
                : const Color(0xFF1F3A68))
            .withValues(alpha: hasBackdropImage ? 0.14 : 0.42)
        ..style = PaintingStyle.fill;
      final Paint meshWirePaint = Paint()
        ..color = roomAccent.withValues(alpha: hasBackdropImage ? 0.22 : 0.44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Un solo Path para toda la malla: 2 draw calls en vez de 2 por tri?ngulo.
      final Path meshPath = Path();
      final int vertexCount = report.vertices.length;
      final List<Offset> projected = List<Offset>.generate(vertexCount, (int i) {
        final GlbVertex3D v = report.vertices[i];
        return Room3DViewport.project3DToScreen(
          v.x,
          v.y,
          v.z,
          size,
          pitch: pitch,
          zoom: zoom,
          yaw: yaw,
        );
      }, growable: false);
      for (final GlbTriangle tri in report.triangles) {
        if (tri.i0 < vertexCount && tri.i1 < vertexCount && tri.i2 < vertexCount) {
          final Offset s0 = projected[tri.i0];
          final Offset s1 = projected[tri.i1];
          final Offset s2 = projected[tri.i2];
          meshPath
            ..moveTo(s0.dx, s0.dy)
            ..lineTo(s1.dx, s1.dy)
            ..lineTo(s2.dx, s2.dy)
            ..close();
        }
      }
      if (!hasBackdropImage) {
        canvas.drawPath(meshPath, meshFillPaint);
        canvas.drawPath(meshPath, meshWirePaint);
      }
    }

    // 4.5. Mobiliario, cilindro LED y estelas de datos animadas (solo si no hay imagen de fondo HD)
    if (!hasBackdropImage) {
      hub.paintFurnitureAndEffects(canvas);
      // 5. Elementos Arquitectónicos 3D del "WORDVERSE GLOBAL BUSINESS HUB"
      _paintGlobalBusinessHubArchitecture(canvas, size, roomAccent);
    }

    // 6. Borde perimetral de Colisión de la Sala 3D
    final Paint wallPaint = Paint()
      ..color = roomAccent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(floorPath, wallPaint);

    // 7. Tapete Luminoso de Spawn Oficial "WORDVERSE" (0.0, 0.42)
    _paintWordverseSpawnMat(canvas, size, roomAccent);

    // 8. Indicador luminoso de destino Tap-to-Walk en el piso 3D
    if (floorTarget != null) {
      final Offset targetPos = Room3DViewport.projectToScreen(
        floorTarget!.normX,
        floorTarget!.normZ,
        size,
        pitch: pitch,
        zoom: zoom,
        yaw: yaw,
      );
      canvas.drawOval(
        Rect.fromCenter(center: targetPos, width: 34, height: 18),
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      canvas.drawCircle(
        targetPos,
        4.0,
        Paint()..color = Colors.cyanAccent,
      );
    }
  }

  /// Dibuja la arquitectura 3D icónica de la imagen:
  /// - Holograma Cilíndrico Central ("Registro de Empresas Mundiales") con anillos de neón
  /// - Estelas curvas de datos luminosos que fluyen desde las Salas Pública y Privada hacia el centro
  /// - Mostrador curvo de Recepción WordVerse (abajo derecha)
  void _paintGlobalBusinessHubArchitecture(
    Canvas canvas,
    Size size,
    Color roomAccent,
  ) {
    final Offset centerBase = Room3DViewport.project3DToScreen(
      0.0,
      0.0,
      0.0,
      size,
      pitch: pitch,
      zoom: zoom,
      yaw: yaw,
    );
    final Offset centerTop = Room3DViewport.project3DToScreen(
      0.0,
      0.28,
      0.0,
      size,
      pitch: pitch,
      zoom: zoom,
      yaw: yaw,
    );

    final double radiusPx =
        math.min(size.width, size.height) *
        RoomPhysicsController.centerTableRadius *
        0.95 *
        zoom;

    // A) Plataforma escalonada iluminada del Pedestal Central (0,0)
    for (int ring = 3; ring >= 1; ring--) {
      final double rScale = 1.0 + (ring * 0.22);
      final Rect ringRect = Rect.fromCenter(
        center: centerBase,
        width: radiusPx * 2.1 * rScale,
        height: radiusPx * 1.25 * rScale,
      );
      canvas.drawOval(
        ringRect,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.16 / ring)
          ..style = PaintingStyle.fill,
      );
      canvas.drawOval(
        ringRect,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.75 / ring)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring == 1 ? 2.4 : 1.2,
      );
    }

    // B) Globo Terráqueo Holográfico 3D Rotatorio ("Registro de Empresas Mundiales")
    final Offset globeCenter = Offset(centerBase.dx, (centerBase.dy + centerTop.dy) * 0.5);
    final double globeRadius = radiusPx * 0.52;
    final double phaseVal = _clock.value;

    // Resplandor esférico interior
    canvas.drawCircle(
      globeCenter,
      globeRadius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.cyanAccent.withValues(alpha: 0.28),
            const Color(0xFF0284C7).withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: globeCenter, radius: globeRadius)),
    );

    // Paralelos de latitud del globo
    final Paint globeGrid = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (int lat = -2; lat <= 2; lat++) {
      final double yOff = lat * (globeRadius * 0.32);
      final double latRad = math.sqrt(math.max(0.0, (globeRadius * globeRadius) - (yOff * yOff)));
      canvas.drawOval(
        Rect.fromCenter(center: globeCenter.translate(0, yOff), width: latRad * 2.0, height: latRad * 0.65),
        globeGrid,
      );
    }

    // Meridianos de longitud en rotación orbital continua
    for (int lon = 0; lon < 4; lon++) {
      final double angle = (lon * (math.pi / 4)) + (phaseVal * math.pi * 2);
      final double rx = math.cos(angle).abs() * globeRadius;
      canvas.drawOval(
        Rect.fromCenter(center: globeCenter, width: rx * 2.0, height: globeRadius * 2.0),
        globeGrid,
      );
    }

    // Nodos de empresas mundiales en el holograma
    final List<(double, double)> nodes = const <(double, double)>[
      (-0.4, -0.2), (0.2, -0.4), (0.5, 0.1), (-0.2, 0.3), (0.0, 0.0), (0.35, 0.3)
    ];
    for (int i = 0; i < nodes.length; i++) {
      final double nx = globeCenter.dx + (nodes[i].$1 * globeRadius);
      final double ny = globeCenter.dy + (nodes[i].$2 * globeRadius * 0.75);
      final double pulse = 0.5 + (0.5 * math.sin((phaseVal * math.pi * 4) + i));
      canvas.drawCircle(Offset(nx, ny), 2.2 + (pulse * 1.5), Paint()..color = Colors.white);
      canvas.drawCircle(Offset(nx, ny), 4.5 + (pulse * 2.5), Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0);
    }

    // Anillo orbital exterior de datos flotante
    final Rect orbitRing = Rect.fromCenter(center: globeCenter, width: globeRadius * 2.5, height: globeRadius * 0.95);
    canvas.drawOval(
      orbitRing,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5),
    );

    // C) Cilindro Holográfico Translúcido Protector
    final Rect holoBodyRect = Rect.fromLTRB(
      centerBase.dx - radiusPx * 0.95,
      centerTop.dy,
      centerBase.dx + radiusPx * 0.95,
      centerBase.dy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(holoBodyRect, const Radius.circular(14)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.cyanAccent.withValues(alpha: 0.22),
            const Color(0xFF0077FF).withValues(alpha: 0.08),
            Colors.cyanAccent.withValues(alpha: 0.26),
          ],
        ).createShader(holoBodyRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(holoBodyRect, const Radius.circular(14)),
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // D) Cintas holográficas curvas (estelas aéreas de datos) conectando el centro con el Hub
    final Path cyberStream1 = Path()
      ..moveTo(centerBase.dx, centerBase.dy - 10)
      ..cubicTo(
        centerBase.dx - (radiusPx * 1.5), centerBase.dy - 30,
        centerBase.dx - (radiusPx * 2.5), centerBase.dy - 60,
        size.width * 0.12, size.height * 0.44,
      );
    final Path cyberStream2 = Path()
      ..moveTo(centerBase.dx, centerBase.dy - 10)
      ..cubicTo(
        centerBase.dx + (radiusPx * 1.4), centerBase.dy - 20,
        centerBase.dx + (radiusPx * 2.2), centerBase.dy - 35,
        size.width * 0.85, size.height * 0.68,
      );

    final Paint streamGlow = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
    canvas.drawPath(cyberStream1, streamGlow);
    canvas.drawPath(cyberStream2, streamGlow);
  }

  /// Dibuja el tapete luminoso "WORDVERSE" en perspectiva en el punto de Spawn.
  void _paintWordverseSpawnMat(Canvas canvas, Size size, Color roomAccent) {
    final Offset spawnCenter = Room3DViewport.projectToScreen(
      RoomPhysicsController.spawnX,
      RoomPhysicsController.spawnZ,
      size,
      pitch: pitch,
      zoom: zoom,
      yaw: yaw,
    );

    final RRect spawnMat = RRect.fromRectAndRadius(
      Rect.fromCenter(center: spawnCenter, width: 92, height: 42),
      const Radius.circular(10),
    );

    canvas.drawRRect(
      spawnMat,
      Paint()
        ..color = const Color(0xFF08142C).withValues(alpha: 0.82)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      spawnMat,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    final TextPainter matTp = TextPainter(
      text: const TextSpan(
        text: 'Ⓦ WORDVERSE',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          color: Colors.cyanAccent,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    matTp.paint(
      canvas,
      Offset(
        spawnCenter.dx - (matTp.width * 0.5),
        spawnCenter.dy - (matTp.height * 0.5),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _Room3DScenePainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.yaw != yaw ||
        oldDelegate.subRoomName != subRoomName ||
        oldDelegate.activeHotspot != activeHotspot ||
        oldDelegate.floorTarget != floorTarget ||
        oldDelegate.glbReport != glbReport ||
        oldDelegate.hasBackdropImage != hasBackdropImage;
  }
}
