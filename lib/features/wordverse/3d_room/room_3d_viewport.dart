import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/models/shest_models.dart';
import '../avatar/avatar_node.dart';
import '../movement/room_physics_controller.dart';
import 'glb_inspector.dart';

/// Visor 3D Interactivo de la Sala Principal de WordVerse (Fases 2, 5, 6, 7, 12, 27).
/// Renderiza en perspectiva 3D:
/// - Malla 3D decodificada directamente desde `assets/models/01_sala_principal.glb`
/// - Escenario, piso reticulado, iluminación ambiental y paredes de colisión
/// - Punto de Spawn (`02 — Hotspots, colisiones y spawn`)
/// - Mesa central de negocios con colisión activa
/// - Los 7 Hotspots interactivos (Fases 19 y 27)
/// - Avatares con etiqueta superior (`[Avatar] / Nombre / ● Disponible`) y Emotes
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
    this.glbReport,
  });

  final AvatarRoomNode localAvatar;
  final List<AvatarRoomNode> remoteAvatars;
  final HotspotKind? activeHotspot;
  final double cameraPitch;
  final double cameraZoom;
  final ValueChanged<AvatarRoomNode> onAvatarTapped;
  final ValueChanged<HotspotKind> onHotspotTapped;
  final GlbOptimizationReport? glbReport;

  /// Proyecta una coordenada 3D normalizada (x, z) en el plano del piso al lienzo 2D.
  static Offset projectToScreen(
    double normX,
    double normZ,
    Size size, {
    double pitch = 0.62,
    double zoom = 1.0,
  }) {
    return project3DToScreen(
      normX,
      0.0,
      normZ,
      size,
      pitch: pitch,
      zoom: zoom,
    );
  }

  /// Proyecta un vértice 3D completo (x, y, z) incluyendo su altura `normY` en perspectiva.
  static Offset project3DToScreen(
    double normX,
    double normY,
    double normZ,
    Size size, {
    double pitch = 0.62,
    double zoom = 1.0,
  }) {
    final double cx = size.width * 0.5;
    final double cy = size.height * 0.52;
    final double baseScale = math.min(size.width, size.height) * 0.42 * zoom;

    final double depthFactor = 1.0 + (normZ * 0.28);
    final double screenX = cx + (normX * baseScale * depthFactor);
    final double elevationPx = normY * baseScale * 0.85 * depthFactor;
    final double screenY = cy + (normZ * baseScale * pitch) - elevationPx;
    return Offset(screenX, screenY);
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
        ]..sort((AvatarRoomNode a, AvatarRoomNode b) => a.normZ.compareTo(b.normZ));

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // 1. Escenario 3D + Malla binaria .GLB (Paredes 3D, Mesa Octogonal, Piso, Spawn)
            Positioned.fill(
              child: CustomPaint(
                painter: _Room3DScenePainter(
                  pitch: cameraPitch,
                  zoom: cameraZoom,
                  activeHotspot: activeHotspot,
                  glbReport: glbReport,
                ),
              ),
            ),

            // 2. Los 7 Hotspots Interactivos de la Sala 3D (Fase 27)
            for (final HotspotKind spot in HotspotKind.values)
              _buildHotspotMarker(spot, canvasSize),

            // 3. Avatares (Local + Remotos Multiplayer) con su etiqueta superior (Fase 5)
            for (final AvatarRoomNode avatar in allAvatars)
              _buildAvatarMarker(avatar, canvasSize),
          ],
        );
      },
    );
  }

  Widget _buildHotspotMarker(HotspotKind spot, Size canvasSize) {
    final Offset pos = projectToScreen(
      spot.normX,
      spot.normZ,
      canvasSize,
      pitch: cameraPitch,
      zoom: cameraZoom,
    );
    final bool isHighlighted = activeHotspot == spot;
    final Color spotColor = _hotspotColor(spot);

    return Positioned(
      left: pos.dx - 54,
      top: pos.dy - 22,
      width: 108,
      child: GestureDetector(
        key: Key('hotspot_${spot.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onHotspotTapped(spot),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlighted
                ? spotColor.withValues(alpha: 0.32)
                : const Color(0xCC0D1528),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHighlighted
                  ? Colors.white
                  : spotColor.withValues(alpha: 0.8),
              width: isHighlighted ? 2.0 : 1.2,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: spotColor.withValues(alpha: isHighlighted ? 0.55 : 0.22),
                blurRadius: isHighlighted ? 12 : 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                spot.code,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: spotColor,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                spot.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
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

  Widget _buildAvatarMarker(AvatarRoomNode node, Size canvasSize) {
    final Offset pos = projectToScreen(
      node.normX,
      node.normZ,
      canvasSize,
      pitch: cameraPitch,
      zoom: cameraZoom,
    );
    final Color avatarColor = Color(node.user.avatarHexColor);

    return Positioned(
      left: pos.dx - 65,
      top: pos.dy - 74,
      width: 130,
      child: GestureDetector(
        key: Key('avatar_${node.user.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onAvatarTapped(node),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (node.activeEmote != null)
              Container(
                margin: const EdgeInsets.only(bottom: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${node.activeEmote!.emoji} ${node.activeEmote!.label}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xDD0B1020),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: node.isLocalPlayer
                      ? Colors.cyanAccent
                      : avatarColor.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (node.user.isFavorite)
                        const Padding(
                          padding: EdgeInsets.only(right: 3),
                          child: Text('⭐', style: TextStyle(fontSize: 9)),
                        ),
                      Flexible(
                        child: Text(
                          node.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '● ${node.user.status.label}',
                    style: TextStyle(
                      fontSize: 9,
                      color: _statusColor(node.user.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    avatarColor,
                    avatarColor.withValues(alpha: 0.45),
                  ],
                ),
                border: Border.all(
                  color: node.isLocalPlayer ? Colors.white : Colors.white70,
                  width: node.isLocalPlayer ? 2.5 : 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: avatarColor.withValues(alpha: 0.65),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                node.user.avatarInitials,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
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
        return Colors.purpleAccent;
      case HotspotKind.qr:
        return Colors.amberAccent;
      case HotspotKind.p2p:
        return Colors.greenAccent;
      case HotspotKind.escrow:
        return const Color(0xFFFFD740);
      case HotspotKind.myProfile:
        return Colors.lightBlueAccent;
      case HotspotKind.exit:
        return Colors.redAccent;
    }
  }
}

class _Room3DScenePainter extends CustomPainter {
  _Room3DScenePainter({
    required this.pitch,
    required this.zoom,
    required this.activeHotspot,
    this.glbReport,
  });

  final double pitch;
  final double zoom;
  final HotspotKind? activeHotspot;
  final GlbOptimizationReport? glbReport;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Iluminación ambiental del espacio virtual 3D
    final Rect fullRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.2),
        radius: 1.1,
        colors: <Color>[
          Color(0xFF162447),
          Color(0xFF0A1124),
          Color(0xFF050811),
        ],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, bgPaint);

    // 2. Polígono del piso 3D dentro de los límites de colisión [-0.82 .. 0.82]
    const double b = RoomPhysicsController.maxBound;
    final Offset topLeft = Room3DViewport.projectToScreen(
      -b,
      -b,
      size,
      pitch: pitch,
      zoom: zoom,
    );
    final Offset topRight = Room3DViewport.projectToScreen(
      b,
      -b,
      size,
      pitch: pitch,
      zoom: zoom,
    );
    final Offset bottomRight = Room3DViewport.projectToScreen(
      b,
      b,
      size,
      pitch: pitch,
      zoom: zoom,
    );
    final Offset bottomLeft = Room3DViewport.projectToScreen(
      -b,
      b,
      size,
      pitch: pitch,
      zoom: zoom,
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
        colors: <Color>[
          const Color(0xFF1B2A4A).withValues(alpha: 0.88),
          const Color(0xFF0F1B33).withValues(alpha: 0.95),
        ],
      ).createShader(fullRect);
    canvas.drawPath(floorPath, floorPaint);

    // 3. Retícula 3D de perspectiva sobre el piso
    final Paint gridPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.14)
      ..strokeWidth = 1.0;

    for (int i = -4; i <= 4; i++) {
      final double t = (i / 4.0) * b;
      final Offset p1 = Room3DViewport.projectToScreen(
        t,
        -b,
        size,
        pitch: pitch,
        zoom: zoom,
      );
      final Offset p2 = Room3DViewport.projectToScreen(
        t,
        b,
        size,
        pitch: pitch,
        zoom: zoom,
      );
      canvas.drawLine(p1, p2, gridPaint);

      final Offset q1 = Room3DViewport.projectToScreen(
        -b,
        t,
        size,
        pitch: pitch,
        zoom: zoom,
      );
      final Offset q2 = Room3DViewport.projectToScreen(
        b,
        t,
        size,
        pitch: pitch,
        zoom: zoom,
      );
      canvas.drawLine(q1, q2, gridPaint);
    }

    // 4. Renderizado de Malla 3D Real decodificada desde `01_sala_principal.glb`
    final GlbOptimizationReport? report = glbReport;
    if (report != null &&
        report.vertices.isNotEmpty &&
        report.triangles.isNotEmpty) {
      final Paint meshFillPaint = Paint()
        ..color = const Color(0xFF1F3A68).withValues(alpha: 0.46)
        ..style = PaintingStyle.fill;
      final Paint meshWirePaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      for (final GlbTriangle tri in report.triangles) {
        if (tri.i0 < report.vertices.length &&
            tri.i1 < report.vertices.length &&
            tri.i2 < report.vertices.length) {
          final GlbVertex3D v0 = report.vertices[tri.i0];
          final GlbVertex3D v1 = report.vertices[tri.i1];
          final GlbVertex3D v2 = report.vertices[tri.i2];

          final Offset s0 = Room3DViewport.project3DToScreen(
            v0.x,
            v0.y,
            v0.z,
            size,
            pitch: pitch,
            zoom: zoom,
          );
          final Offset s1 = Room3DViewport.project3DToScreen(
            v1.x,
            v1.y,
            v1.z,
            size,
            pitch: pitch,
            zoom: zoom,
          );
          final Offset s2 = Room3DViewport.project3DToScreen(
            v2.x,
            v2.y,
            v2.z,
            size,
            pitch: pitch,
            zoom: zoom,
          );

          final Path triPath = Path()
            ..moveTo(s0.dx, s0.dy)
            ..lineTo(s1.dx, s1.dy)
            ..lineTo(s2.dx, s2.dy)
            ..close();
          canvas.drawPath(triPath, meshFillPaint);
          canvas.drawPath(triPath, meshWirePaint);
        }
      }
    }

    // 5. Borde perimetral de Colisión de la Sala 3D
    final Paint wallPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(floorPath, wallPaint);

    // 6. Punto de Spawn Oficial (0.0, 0.42)
    final Offset spawnCenter = Room3DViewport.projectToScreen(
      RoomPhysicsController.spawnX,
      RoomPhysicsController.spawnZ,
      size,
      pitch: pitch,
      zoom: zoom,
    );
    final Paint spawnPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: spawnCenter, width: 46, height: 24),
      spawnPaint,
    );

    // 7. Base de Colisión de la Mesa Central de Negocios / Reuniones (0,0)
    final Offset tableCenter = Room3DViewport.project3DToScreen(
      0.0,
      0.14,
      0.0,
      size,
      pitch: pitch,
      zoom: zoom,
    );
    final double tableRadiusPx =
        math.min(size.width, size.height) *
        RoomPhysicsController.centerTableRadius *
        0.85 *
        zoom;
    final Rect tableRect = Rect.fromCenter(
      center: tableCenter,
      width: tableRadiusPx * 2.1,
      height: tableRadiusPx * 1.35,
    );
    canvas.drawOval(
      tableRect,
      Paint()
        ..color = Colors.amberAccent.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _Room3DScenePainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.activeHotspot != activeHotspot ||
        oldDelegate.glbReport != glbReport;
  }
}
