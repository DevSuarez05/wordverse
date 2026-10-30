import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../movement/room_physics_controller.dart';

/// Proyector 3D -> pantalla (x, y, z normalizados) inyectado por el visor.
/// Evita acoplar este archivo con `Room3DViewport` (sin imports circulares).
typedef HubProjector = Offset Function(double x, double y, double z);

/// Arquitectura procedural del "WORDVERSE — GLOBAL BUSINESS HUB".
///
/// Dibuja (todo con proyección real, respetando `yaw`/`pitch`/`zoom`):
/// - Muros perimetrales lejanos con luminaria neón
/// - Sala de Reuniones Pública (cristal + figuras) y Privada (puerta esmerilada)
/// - Cilindro LED suspendido con anillos de domo y rótulo del Hub
/// - Kiosco "Compañía Privada" y Recepción WordVerse
/// - Estelas de datos animadas (flujo continuo sobre el piso)
class HubArchitecturePainter {
  HubArchitecturePainter({
    required this.project,
    required this.yaw,
    required this.accent,
    required this.opacity,
    required this.phase,
  });

  final HubProjector project;
  final double yaw;
  final Color accent;

  /// Multiplicador global de opacidad (se reduce si hay render HD de fondo).
  final double opacity;

  /// Fase de animación en [0, 1) para estelas y parpadeos.
  final double phase;

  static const double _b = RoomPhysicsController.maxBound;
  static const double _wallHeight = 0.62;
  static const Color _navy = Color(0xFF07142B);
  static const Color _navyLight = Color(0xFF0D2A52);

  Color _a(Color c, double alpha) => c.withValues(alpha: alpha * opacity);

  /// Un muro es "lejano" (se dibuja detrás de la acción) si su centro queda
  /// por detrás del origen según la rotación orbital actual.
  bool _isFar(double cx, double cz) =>
      (cx * math.sin(yaw)) + (cz * math.cos(yaw)) < -0.05;

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  /// Muros + salas + paneles (se pinta ANTES de objetos del piso).
  void paintShell(Canvas canvas) {
    const List<(double, double, double, double)> walls =
        <(double, double, double, double)>[
          (-_b, -_b, _b, -_b), // fondo (norte)
          (_b, -_b, _b, _b), // derecha (este)
          (_b, _b, -_b, _b), // frente (sur)
          (-_b, _b, -_b, -_b), // izquierda (oeste)
        ];
    for (final (double ax, double az, double bx, double bz) in walls) {
      if (_isFar((ax + bx) / 2, (az + bz) / 2)) {
        _paintWall(canvas, ax, az, bx, bz);
      }
    }

    if (_isFar(0, -_b)) {
      _paintBackWallContent(canvas);
    }
    if (_isFar(_b, 0)) {
      _paintSideWallContent(canvas, wallX: _b, fromZ: -_b + 0.1, toZ: _b - 0.1);
    }
    if (_isFar(-_b, 0)) {
      _paintSideWallContent(canvas, wallX: -_b, fromZ: _b - 0.1, toZ: -_b + 0.1);
    }
  }

  /// Mobiliario + cilindro LED + estelas + kioscos (se pinta DESPUÉS del piso).
  void paintFurnitureAndEffects(Canvas canvas) {
    _paintLightTrails(canvas);
    _paintInteractiveKiosk(canvas);
    _paintBox(
      canvas,
      cx: 0.58,
      cz: -0.38,
      w: 0.09,
      d: 0.07,
      h: 0.2,
      body: const Color(0xFF1B2B45),
      glow: Colors.cyanAccent,
    );
    _paintReceptionDesk(canvas);
    _paintLedDrum(canvas);
  }

  // ---------------------------------------------------------------------------
  // Muros
  // ---------------------------------------------------------------------------

  void _paintWall(Canvas canvas, double ax, double az, double bx, double bz) {
    final Offset bl = project(ax, 0, az);
    final Offset br = project(bx, 0, bz);
    final Offset tr = project(bx, _wallHeight, bz);
    final Offset tl = project(ax, _wallHeight, az);
    final Path quad = Path()
      ..moveTo(bl.dx, bl.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(tl.dx, tl.dy)
      ..close();
    final Rect bounds = quad.getBounds();
    canvas.drawPath(
      quad,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.bottomCenter,
          bounds.topCenter,
          <Color>[_a(_navyLight, 0.78), _a(_navy, 0.92)],
        ),
    );
    // Paneles verticales sutiles
    final Paint seam = Paint()
      ..color = _a(accent, 0.10)
      ..strokeWidth = 1.0;
    for (int i = 1; i < 8; i++) {
      final double t = i / 8.0;
      final double x = ax + (bx - ax) * t;
      final double z = az + (bz - az) * t;
      canvas.drawLine(project(x, 0, z), project(x, _wallHeight, z), seam);
    }
    // Neón superior e inferior
    final Paint neon = Paint()
      ..color = _a(accent, 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.5);
    canvas.drawLine(tl, tr, neon);
    canvas.drawLine(bl, br, neon);
  }

  void _paintBackWallContent(Canvas canvas) {
    const double z = -_b;
    // Nivel 2 (Superior Izquierda): Sala de Reuniones Pública
    _paintPublicRoom(canvas, z, -0.78, -0.22, 0.35, 0.58);

    // Mezzanine / Entrepiso estructural con barandilla de cristal y borde LED
    _paintMezzanineSlab(canvas, z, -0.80, -0.20, 0.29, 0.34);
    _paintMezzanineSlab(canvas, z, 0.20, 0.80, 0.29, 0.34);

    // Nivel 1 (Inferior Izquierda): Sala de Reuniones Privada SHES'T
    _paintPrivateRoom(canvas, z, -0.78, -0.22, 0.02, 0.28);

    // Nivel 2 (Superior Derecha): Galería ejecutiva con barandilla y vista al Atrio
    _paintUpperExecutiveMezzanine(canvas, z, 0.22, 0.78, 0.35, 0.58);

    // Logo central (detrás del cilindro LED suspendido)
    _onPlane(
      canvas,
      -0.12,
      z,
      0.12,
      z,
      0.22,
      0.46,
      100,
      100,
      (Canvas c) => _drawLogo(c, const Offset(50, 50), 44),
    );
  }

  void _paintMezzanineSlab(
    Canvas canvas,
    double z,
    double x0,
    double x1,
    double y0,
    double y1,
  ) {
    final Path slab = _planeQuad(x0, z, x1, z, y0, y1);
    canvas.drawPath(
      slab,
      Paint()
        ..shader = ui.Gradient.linear(
          slab.getBounds().topCenter,
          slab.getBounds().bottomCenter,
          <Color>[_a(const Color(0xFF1E293B), 0.95), _a(const Color(0xFF0F172A), 0.98)],
        ),
    );
    // Borde LED cian en la arista de la losa
    final Paint railNeon = Paint()
      ..color = _a(Colors.cyanAccent, 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
    canvas.drawLine(project(x0, y1, z), project(x1, y1, z), railNeon);
    canvas.drawLine(project(x0, y0, z), project(x1, y0, z), Paint()
      ..color = _a(Colors.cyanAccent, 0.45)
      ..strokeWidth = 1.2);

    // Barandilla de cristal templado en el balcón
    final Path glassRail = _planeQuad(x0, z, x1, z, y1, y1 + 0.08);
    canvas.drawPath(
      glassRail,
      Paint()
        ..color = _a(const Color(0xFF67E8F9), 0.22),
    );
    canvas.drawLine(
      project(x0, y1 + 0.08, z),
      project(x1, y1 + 0.08, z),
      Paint()
        ..color = _a(Colors.white, 0.85)
        ..strokeWidth = 1.4,
    );
  }

  void _paintPublicRoom(
    Canvas canvas,
    double z,
    double x0,
    double x1,
    double y0,
    double y1,
  ) {
    final Path glass = _planeQuad(x0, z, x1, z, y0, y1);
    canvas.drawPath(
      glass,
      Paint()
        ..shader = ui.Gradient.linear(
          glass.getBounds().topLeft,
          glass.getBounds().bottomRight,
          <Color>[_a(const Color(0xFF60A5FA), 0.22), _a(const Color(0xFF1E3A8A), 0.32)],
        ),
    );

    // Marca de agua SHES'T sobre el cristal de la sala
    _onPlane(
      canvas,
      x0 + 0.03,
      z,
      x0 + 0.16,
      z,
      y0 + 0.04,
      y0 + 0.12,
      120,
      50,
      (Canvas c) {
        _drawText(c, "SHES'T", const Offset(60, 25), 18, Colors.white.withValues(alpha: 0.45), bold: true, spacing: 2.5);
      },
    );

    // Mesa de juntas y ejecutivos sentados con visores VR y HUDs flotantes
    final double tz = z + 0.08;
    final double tableCenter = (x0 + x1) * 0.5;
    final Offset tableC = project(tableCenter, y0 + 0.04, tz);
    final double unit = (project(tableCenter + 0.1, y0 + 0.04, tz) - tableC).distance;
    canvas.drawOval(
      Rect.fromCenter(center: tableC, width: unit * 3.6, height: unit * 0.95),
      Paint()..color = _a(const Color(0xFF334155), 0.85),
    );

    // 5 ejecutivos sentados con trajes oscuros y visores VR cian
    for (int i = 0; i < 5; i++) {
      final double fx = x0 + 0.08 + (i * 0.09);
      final Offset head = project(fx, y0 + 0.14, tz);
      final Offset torso = project(fx, y0 + 0.07, tz);
      canvas.drawLine(
        head,
        torso,
        Paint()
          ..color = _a(const Color(0xFF0F172A), 0.95)
          ..strokeWidth = unit * 0.52
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(head, unit * 0.28, Paint()..color = _a(const Color(0xFFE2E8F0), 0.95));
      // Visor VR cian en cada ejecutivo
      canvas.drawLine(
        head.translate(-unit * 0.24, 0),
        head.translate(unit * 0.24, 0),
        Paint()
          ..color = Colors.cyanAccent
          ..strokeWidth = unit * 0.16,
      );
    }

    // HUD flotante / Pantalla holográfica de la reunión
    final Offset hudPos = project(x0 + 0.12, y0 + 0.16, tz);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: hudPos, width: unit * 1.8, height: unit * 0.9),
        const Radius.circular(3),
      ),
      Paint()..color = _a(Colors.cyanAccent, 0.25),
    );

    // Marco exterior con neón
    canvas.drawPath(
      glass,
      Paint()
        ..color = _a(Colors.cyanAccent, 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    // Rótulo luminoso exacto al concepto: "Sala de Reuniones Pública"
    _wallLabel(canvas, 'Sala de Reuniones Pública', x0, z, x1, z, y1 + 0.02, y1 + 0.09);
  }

  void _paintPrivateRoom(
    Canvas canvas,
    double z,
    double x0,
    double x1,
    double y0,
    double y1,
  ) {
    final Path door = _planeQuad(x0, z, x1, z, y0, y1);
    // Cristal esmerilado de alta privacidad con gradiente translúcido
    canvas.drawPath(
      door,
      Paint()
        ..shader = ui.Gradient.linear(
          door.getBounds().topCenter,
          door.getBounds().bottomCenter,
          <Color>[_a(const Color(0xFFCBD5E1), 0.42), _a(const Color(0xFF475569), 0.48)],
        ),
    );

    // Marca de agua corporativa SHES'T en puerta esmerilada
    _onPlane(
      canvas,
      x0 + 0.04,
      z,
      x0 + 0.18,
      z,
      y0 + 0.16,
      y0 + 0.24,
      120,
      50,
      (Canvas c) {
        _drawText(c, "SHES'T", const Offset(60, 25), 20, Colors.white.withValues(alpha: 0.55), bold: true, spacing: 3.0);
      },
    );

    // Puerta corrediza automática con manija metálica y lector biométrico
    final double xm = (x0 + x1) * 0.5;
    canvas.drawLine(
      project(xm, y0, z),
      project(xm, y1, z),
      Paint()
        ..color = _a(Colors.white, 0.7)
        ..strokeWidth = 1.8,
    );
    canvas.drawLine(
      project(xm - 0.02, y0 + 0.08, z),
      project(xm - 0.02, y0 + 0.18, z),
      Paint()
        ..color = _a(Colors.white, 0.95)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    // Lector biométrico de acceso con luz cian/verde
    canvas.drawCircle(
      project(xm + 0.03, y0 + 0.13, z),
      2.5,
      Paint()..color = Colors.greenAccent,
    );

    // Borde iluminado
    canvas.drawPath(
      door,
      Paint()
        ..color = _a(const Color(0xFF67E8F9), 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    // Rótulo luminoso exacto al concepto: "Sala de Reuniones Privada"
    _wallLabel(canvas, 'Sala de Reuniones Privada', x0, z, x1, z, y1 + 0.02, y1 + 0.09);
  }

  void _paintUpperExecutiveMezzanine(
    Canvas canvas,
    double z,
    double x0,
    double x1,
    double y0,
    double y1,
  ) {
    // Cristal panorámico del corredor superior
    final Path glass = _planeQuad(x0, z, x1, z, y0, y1);
    canvas.drawPath(
      glass,
      Paint()..color = _a(const Color(0xFF031024), 0.75),
    );
    // Figuras de ejecutivos de pie observando el atrio desde el segundo piso
    for (int i = 0; i < 4; i++) {
      final double fx = x0 + 0.08 + (i * 0.14);
      final Offset head = project(fx, y0 + 0.16, z + 0.05);
      final Offset body = project(fx, y0 + 0.05, z + 0.05);
      canvas.drawLine(
        head,
        body,
        Paint()
          ..color = _a(const Color(0xFF0F172A), 0.95)
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(head, 3.2, Paint()..color = _a(const Color(0xFFE2E8F0), 0.95));
      // Visor inteligente AR
      canvas.drawLine(head.translate(-3, 0), head.translate(3, 0), Paint()
        ..color = Colors.cyanAccent
        ..strokeWidth = 1.5);
    }
  }

  /// Muros laterales: pantallas de mapa mundial con puntos de empresas.
  void _paintSideWallContent(
    Canvas canvas, {
    required double wallX,
    required double fromZ,
    required double toZ,
  }) {
    final Path screen = _planeQuad(wallX, fromZ, wallX, toZ, 0.14, 0.50);
    canvas.drawPath(
      screen,
      Paint()..color = _a(const Color(0xFF03101F), 0.85),
    );
    canvas.drawPath(
      screen,
      Paint()
        ..color = _a(accent, 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    final math.Random rnd = math.Random(wallX > 0 ? 7 : 11);
    final Paint dot = Paint()..color = _a(Colors.cyanAccent, 0.9);
    for (int i = 0; i < 46; i++) {
      final double t = 0.06 + rnd.nextDouble() * 0.88;
      final double y = 0.17 + rnd.nextDouble() * 0.30;
      final double pulse = 0.5 + 0.5 * math.sin((phase * 2 * math.pi) + i);
      canvas.drawCircle(
        project(wallX, y, fromZ + (toZ - fromZ) * t),
        1.1 + pulse * 0.9,
        dot,
      );
    }
    _wallLabel(canvas, 'Registro de Empresas Mundiales', wallX, fromZ, wallX, toZ, 0.52, 0.60);
  }

  // ---------------------------------------------------------------------------
  // Cilindro LED central
  // ---------------------------------------------------------------------------

  void _paintLedDrum(Canvas canvas) {
    const double r = 0.21;
    const double yBottom = 0.50;
    const double yTop = 0.74;

    // Anillos de domo suspendidos
    for (int i = 0; i < 3; i++) {
      final double ry = yTop + 0.06 + i * 0.05;
      final double rr = r + 0.10 + i * 0.09;
      canvas.drawPath(
        _circlePath(rr, ry),
        Paint()
          ..color = _a(Colors.cyanAccent, 0.55 - i * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 - i * 0.4
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0),
      );
    }
    // Tirantes
    final Paint rod = Paint()
      ..color = _a(const Color(0xFF94A3B8), 0.65)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 4; i++) {
      final double ang = i * math.pi / 2 + math.pi / 4;
      canvas.drawLine(
        project(math.cos(ang) * r, yTop, math.sin(ang) * r),
        project(math.cos(ang) * (r + 0.1), yTop + 0.06, math.sin(ang) * (r + 0.1)),
        rod,
      );
    }

    // Cuerpo
    final List<Offset> bottomPts = _circlePoints(r, yBottom);
    final List<Offset> topPts = _circlePoints(r, yTop);
    Offset leftB = bottomPts.first, rightB = bottomPts.first;
    Offset leftT = topPts.first, rightT = topPts.first;
    for (final Offset p in bottomPts) {
      if (p.dx < leftB.dx) leftB = p;
      if (p.dx > rightB.dx) rightB = p;
    }
    for (final Offset p in topPts) {
      if (p.dx < leftT.dx) leftT = p;
      if (p.dx > rightT.dx) rightT = p;
    }
    final Path body = Path()
      ..moveTo(leftB.dx, leftB.dy)
      ..lineTo(leftT.dx, leftT.dy)
      ..lineTo(rightT.dx, rightT.dy)
      ..lineTo(rightB.dx, rightB.dy)
      ..close()
      ..addPolygon(bottomPts, true);
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(leftB.dx, 0),
          Offset(rightB.dx, 0),
          <Color>[
            _a(const Color(0xFF020817), 0.98),
            _a(const Color(0xFF0B2A5B), 0.98),
            _a(const Color(0xFF020817), 0.98),
          ],
          <double>[0.0, 0.5, 1.0],
        ),
    );
    canvas.drawPath(
      Path()..addPolygon(topPts, true),
      Paint()..color = _a(const Color(0xFF123A73), 0.95),
    );
    final Paint rim = Paint()
      ..color = _a(Colors.cyanAccent, 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.8);
    canvas.drawPath(Path()..addPolygon(topPts, true), rim);
    canvas.drawPath(Path()..addPolygon(bottomPts, true), rim);
    canvas.drawLine(leftB, leftT, rim);
    canvas.drawLine(rightB, rightT, rim);

    // Rótulo sobre la cara frontal (plano tangente al frente de cámara)
    final double fx = math.sin(yaw);
    final double fz = math.cos(yaw);
    final double tx = math.cos(yaw);
    final double tz = -math.sin(yaw);
    const double a = 0.62;
    final double ca = math.cos(a) * r;
    final double sa = math.sin(a) * r;
    _onPlane(
      canvas,
      fx * ca - tx * sa,
      fz * ca - tz * sa,
      fx * ca + tx * sa,
      fz * ca + tz * sa,
      yBottom + 0.01,
      yTop - 0.01,
      240,
      100,
      (Canvas c) {
        _drawLogo(c, const Offset(120, 28), 20);
        _drawText(c, 'WORDVERSE', const Offset(120, 58), 26, Colors.white, bold: true, spacing: 2.0);
        _drawText(c, 'GLOBAL BUSINESS HUB', const Offset(120, 82), 11, Colors.cyanAccent, spacing: 1.2);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Recepción y cajas
  // ---------------------------------------------------------------------------

  void _paintReceptionDesk(Canvas canvas) {
    // Mostrador curvo de recepción ejecutiva WordVerse
    _paintBox(
      canvas,
      cx: 0.62,
      cz: 0.28,
      w: 0.10,
      d: 0.26,
      h: 0.11,
      body: const Color(0xFF0F1B2E),
      glow: Colors.cyanAccent,
    );
    // Borde de neón bajo el mostrador (underglow al piso)
    final Offset r1 = project(0.52, 0.005, 0.02);
    final Offset r2 = project(0.52, 0.005, 0.54);
    canvas.drawLine(
      r1,
      r2,
      Paint()
        ..color = _a(Colors.cyanAccent, 0.95)
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.5),
    );

    // Rótulo frontal en el mostrador: "(W) WordVerse"
    _onPlane(
      canvas,
      0.518,
      0.14,
      0.518,
      0.42,
      0.02,
      0.09,
      140,
      40,
      (Canvas c) {
        _drawLogo(c, const Offset(20, 20), 12);
        _drawText(c, 'WordVerse', const Offset(80, 20), 16, Colors.white, bold: true, spacing: 1.0);
      },
    );

    // Monitores de control y recepcionista con visor VR
    for (final double dz in <double>[0.20, 0.36]) {
      final Offset base = project(0.62, 0.11, dz);
      final Offset top = project(0.62, 0.18, dz);
      canvas.drawLine(
        base,
        top,
        Paint()
          ..color = _a(const Color(0xFF020617), 1)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        top.translate(0, 1),
        top.translate(0, 1),
        Paint()
          ..color = _a(Colors.cyanAccent, 0.9)
          ..strokeWidth = 3,
      );
    }

    // Recepcionista corporativo con visor VR tras el mostrador
    final Offset recHead = project(0.66, 0.21, 0.28);
    final Offset recTorso = project(0.66, 0.11, 0.28);
    canvas.drawLine(
      recTorso,
      recHead,
      Paint()
        ..color = _a(const Color(0xFF0F172A), 0.95)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(recHead, 4.5, Paint()..color = _a(const Color(0xFFE2E8F0), 0.95));
    canvas.drawLine(recHead.translate(-4, 0), recHead.translate(4, 0), Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.0);
  }

  void _paintInteractiveKiosk(Canvas canvas) {
    // Pedestal de Kiosco "Compañía Privada" con pantalla táctil vertical
    const double kx = -0.32;
    const double kz = 0.40;
    _paintBox(
      canvas,
      cx: kx,
      cz: kz,
      w: 0.05,
      d: 0.05,
      h: 0.18,
      body: const Color(0xFF111E33),
      glow: Colors.cyanAccent,
    );
    // Pantalla táctil vertical inclinada
    _onPlane(
      canvas,
      kx - 0.04,
      kz - 0.04,
      kx + 0.04,
      kz - 0.04,
      0.08,
      0.22,
      80,
      120,
      (Canvas c) {
        c.drawRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(4, 4, 72, 112), const Radius.circular(6)),
          Paint()..color = const Color(0xDD0077FF),
        );
        _drawLogo(c, const Offset(40, 28), 14);
        _drawText(c, 'COMPAÑÍA', const Offset(40, 60), 8.5, Colors.white, bold: true);
        _drawText(c, 'PRIVADA', const Offset(40, 74), 8.0, Colors.cyanAccent, bold: true);
        c.drawRect(const Rect.fromLTWH(14, 90, 52, 14), Paint()..color = Colors.white.withValues(alpha: 0.35));
      },
    );
  }

  /// Caja 3D con caras ordenadas por profundidad y borde neón.
  void _paintBox(
    Canvas canvas, {
    required double cx,
    required double cz,
    required double w,
    required double d,
    required double h,
    required Color body,
    required Color glow,
  }) {
    final double x0 = cx - w, x1 = cx + w, z0 = cz - d, z1 = cz + d;
    final List<List<(double, double, double)>> faces =
        <List<(double, double, double)>>[
          <(double, double, double)>[(x0, 0, z0), (x1, 0, z0), (x1, h, z0), (x0, h, z0)],
          <(double, double, double)>[(x1, 0, z0), (x1, 0, z1), (x1, h, z1), (x1, h, z0)],
          <(double, double, double)>[(x1, 0, z1), (x0, 0, z1), (x0, h, z1), (x1, h, z1)],
          <(double, double, double)>[(x0, 0, z1), (x0, 0, z0), (x0, h, z0), (x0, h, z1)],
          <(double, double, double)>[(x0, h, z0), (x1, h, z0), (x1, h, z1), (x0, h, z1)],
        ];
    double depth(List<(double, double, double)> f) {
      double sx = 0, sz = 0;
      for (final (double x, double _, double z) in f) {
        sx += x;
        sz += z;
      }
      return (sx / f.length) * math.sin(yaw) + (sz / f.length) * math.cos(yaw);
    }

    final List<List<(double, double, double)>> sorted =
        List<List<(double, double, double)>>.of(faces)
          ..sort((a, b) => depth(a).compareTo(depth(b)));
    for (int i = 0; i < sorted.length; i++) {
      final Path p = Path();
      for (int k = 0; k < 4; k++) {
        final (double x, double y, double z) = sorted[i][k];
        final Offset o = project(x, y, z);
        k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      p.close();
      final bool isTop = sorted[i][0].$2 == h && sorted[i][2].$2 == h;
      canvas.drawPath(
        p,
        Paint()..color = _a(isTop ? Color.lerp(body, Colors.white, 0.18)! : body, 0.96),
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = _a(glow, isTop ? 0.95 : 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isTop ? 1.8 : 1.0,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Estelas de datos animadas
  // ---------------------------------------------------------------------------

  void _paintLightTrails(Canvas canvas) {
    final List<List<(double, double)>> routes = <List<(double, double)>>[
      <(double, double)>[(-0.60, -0.45), (-0.30, -0.10), (0.0, 0.0), (0.30, 0.15), (0.62, 0.28)],
      <(double, double)>[(0.60, -0.45), (0.30, -0.10), (0.0, 0.0), (-0.22, 0.30), (0.0, 0.42)],
      <(double, double)>[(-0.68, 0.20), (-0.40, 0.45), (0.0, 0.56), (0.40, 0.45), (0.62, 0.28)],
    ];
    for (int r = 0; r < routes.length; r++) {
      final List<Offset> pts = _catmullRom(routes[r], 14);
      final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final Offset p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      // Riel tenue
      canvas.drawPath(
        path,
        Paint()
          ..color = _a(Colors.cyanAccent, 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0,
      );
      // Paquetes de luz en movimiento
      for (final ui.PathMetric m in path.computeMetrics()) {
        const double seg = 26;
        const double gap = 46;
        final double shift = ((phase + r * 0.33) % 1.0) * (seg + gap);
        for (double d = -shift; d < m.length; d += seg + gap) {
          final double s = math.max(0, d);
          final double e = math.min(m.length, d + seg);
          if (e <= s) continue;
          canvas.drawPath(
            m.extractPath(s, e),
            Paint()
              ..color = _a(Colors.lightBlueAccent, 0.95)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.6),
          );
        }
      }
    }
  }

  List<Offset> _catmullRom(List<(double, double)> pts, int steps) {
    final List<Offset> out = <Offset>[];
    (double, double) at(int i) => pts[i.clamp(0, pts.length - 1)];
    for (int i = 0; i < pts.length - 1; i++) {
      final (double, double) p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      for (int s = 0; s < steps; s++) {
        final double t = s / steps;
        final double t2 = t * t, t3 = t2 * t;
        double c(double a, double b, double c0, double d) =>
            0.5 *
            ((2 * b) +
                (-a + c0) * t +
                (2 * a - 5 * b + 4 * c0 - d) * t2 +
                (-a + 3 * b - 3 * c0 + d) * t3);
        out.add(project(c(p0.$1, p1.$1, p2.$1, p3.$1), 0.012, c(p0.$2, p1.$2, p2.$2, p3.$2)));
      }
    }
    final (double, double) last = pts.last;
    out.add(project(last.$1, 0.012, last.$2));
    return out;
  }

  // ---------------------------------------------------------------------------
  // Utilidades de geometría / texto en plano
  // ---------------------------------------------------------------------------

  List<Offset> _circlePoints(double r, double y, {int n = 40}) =>
      List<Offset>.generate(n, (int i) {
        final double a = (i / n) * math.pi * 2;
        return project(math.cos(a) * r, y, math.sin(a) * r);
      });

  Path _circlePath(double r, double y) =>
      Path()..addPolygon(_circlePoints(r, y, n: 56), true);

  Path _planeQuad(double ax, double az, double bx, double bz, double y0, double y1) {
    final Offset bl = project(ax, y0, az);
    final Offset br = project(bx, y0, bz);
    final Offset tr = project(bx, y1, bz);
    final Offset tl = project(ax, y1, az);
    return Path()
      ..moveTo(bl.dx, bl.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(tl.dx, tl.dy)
      ..close();
  }

  /// Dibuja contenido 2D lógico (`lw` x `lh`) mapeado afinmente sobre un plano
  /// vertical definido por dos puntos de suelo (a -> b) y un rango de alturas.
  void _onPlane(
    Canvas canvas,
    double ax,
    double az,
    double bx,
    double bz,
    double y0,
    double y1,
    double lw,
    double lh,
    void Function(Canvas) draw,
  ) {
    final Offset origin = project(ax, y1, az);
    final Offset u = project(bx, y1, bz) - origin;
    final Offset v = project(ax, y0, az) - origin;
    // Muro casi de canto o espejado: no se dibuja texto ilegible.
    if (u.dx < 6) return;
    canvas.save();
    canvas.transform(
      Float64List.fromList(<double>[
        u.dx / lw, u.dy / lw, 0, 0,
        v.dx / lh, v.dy / lh, 0, 0,
        0, 0, 1, 0,
        origin.dx, origin.dy, 0, 1,
      ]),
    );
    draw(canvas);
    canvas.restore();
  }

  /// Rótulo luminoso centrado y sin distorsión de aspecto sobre un muro.
  void _wallLabel(
    Canvas canvas,
    String text,
    double ax,
    double az,
    double bx,
    double bz,
    double y0,
    double y1,
  ) {
    const double fontSize = 40;
    final TextPainter tp = _layoutText(text, fontSize, Colors.white, bold: true, spacing: 0.6);
    const double padX = 36, padY = 18;
    final double lw = tp.width + padX * 2;
    const double lh = fontSize * 1.25 + padY;
    final double wallLen = math.sqrt((bx - ax) * (bx - ax) + (bz - az) * (bz - az));
    final double worldH = y1 - y0;
    // Escala el rótulo a la anchura del muro conservando el aspecto.
    final double worldW = math.min(wallLen, worldH * (lw / lh));
    final double fitH = worldW * (lh / lw);
    final double t0 = ((wallLen - worldW) / 2) / wallLen;
    final double t1 = 1 - t0;
    final double ya = y0 + (worldH - fitH) / 2;
    _onPlane(
      canvas,
      ax + (bx - ax) * t0,
      az + (bz - az) * t0,
      ax + (bx - ax) * t1,
      az + (bz - az) * t1,
      ya,
      ya + fitH,
      lw,
      lh,
      (Canvas c) {
        final RRect plate = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, lw, lh),
          const Radius.circular(10),
        );
        c.drawRRect(plate, Paint()..color = _a(const Color(0xFF020B1C), 0.92));
        c.drawRRect(
          plate,
          Paint()
            ..color = _a(Colors.cyanAccent, 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
        );
        tp.paint(c, Offset(padX, (lh - tp.height) / 2));
      },
    );
  }

  void _drawLogo(Canvas canvas, Offset c, double radius) {
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..color = _a(Colors.cyanAccent, 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.1
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, radius * 0.06),
    );
    canvas.drawCircle(c, radius * 0.9, Paint()..color = _a(const Color(0xFF06152D), 0.9));
    _drawText(canvas, 'W', c, radius * 1.1, Colors.cyanAccent, bold: true);
  }

  TextPainter _layoutText(
    String text,
    double size,
    Color color, {
    bool bold = false,
    double spacing = 0,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: _a(color, 1),
          fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color color, {
    bool bold = false,
    double spacing = 0,
  }) {
    final TextPainter tp = _layoutText(text, size, color, bold: bold, spacing: spacing);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
