import 'dart:math' as math;

import '../../../core/models/shest_models.dart';

/// Controlador de Movimiento, Spawn, Colisiones y Proximidad a Hotspots (Fases 2 y 6).
/// Basado en la referencia `02 — Hotspots, colisiones y spawn`.
class RoomPhysicsController {
  /// Punto oficial de Spawn al entrar a la sala principal.
  static const double spawnX = 0.0;
  static const double spawnZ = 0.42;

  /// Límites de colisión perimetral de las paredes de la Sala 3D.
  static const double minBound = -0.82;
  static const double maxBound = 0.82;

  /// Radio de la mesa redonda central de negocios (obstáculo con colisión).
  static const double centerTableRadius = 0.19;

  /// Radio de activación al acercarse caminando a un Hotspot.
  static const double hotspotTriggerRadius = 0.18;

  /// Calcula la nueva posición aplicando velocidad, límites de pared y colisión
  /// con el mobiliario central.
  static ({double x, double z, double rotation, bool collided}) computeStep({
    required double currentX,
    required double currentZ,
    required double currentRotation,
    required double joyDx,
    required double joyDy,
    double stepSpeed = 0.024,
  }) {
    if (joyDx.abs() < 0.02 && joyDy.abs() < 0.02) {
      return (
        x: currentX,
        z: currentZ,
        rotation: currentRotation,
        collided: false,
      );
    }

    double nextX = currentX + (joyDx * stepSpeed);
    double nextZ = currentZ + (joyDy * stepSpeed);
    bool collided = false;

    // 1. Colisión con paredes perimetrales de la Sala 3D
    if (nextX < minBound) {
      nextX = minBound;
      collided = true;
    } else if (nextX > maxBound) {
      nextX = maxBound;
      collided = true;
    }

    if (nextZ < minBound) {
      nextZ = minBound;
      collided = true;
    } else if (nextZ > maxBound) {
      nextZ = maxBound;
      collided = true;
    }

    // 2. Colisión cilíndrica con la mesa central de negocios (0, 0)
    final double distFromCenter = math.sqrt(nextX * nextX + nextZ * nextZ);
    if (distFromCenter < centerTableRadius) {
      final double safeDist = distFromCenter == 0 ? 0.001 : distFromCenter;
      nextX = (nextX / safeDist) * centerTableRadius;
      nextZ = (nextZ / safeDist) * centerTableRadius;
      collided = true;
    }

    final double rotation = math.atan2(joyDy, joyDx);
    return (x: nextX, z: nextZ, rotation: rotation, collided: collided);
  }

  /// Detecta si el avatar local se encuentra sobre alguno de los 7 Hotspots (Fase 27).
  static HotspotKind? detectNearbyHotspot(double x, double z) {
    for (final HotspotKind spot in HotspotKind.values) {
      final double dx = x - spot.normX;
      final double dz = z - spot.normZ;
      final double dist = math.sqrt(dx * dx + dz * dz);
      if (dist <= hotspotTriggerRadius) {
        return spot;
      }
    }
    return null;
  }
}
