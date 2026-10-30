import '../../../../core/models/shest_models.dart';
import '../../avatar/avatar_node.dart';
import '../../movement/room_physics_controller.dart';

/// Protocolo Flutter <-> escena Three.js (`web/hub3d`).
///
/// Mensajes JSON: `{source: 'wordverse' | 'hub3d', type: ..., ...}`.
/// Este archivo es Dart puro (sin dart:html) para poder probarse en la VM.
abstract final class Hub3DProtocol {
  static const String fromFlutter = 'wordverse';
  static const String fromScene = 'hub3d';

  /// Subtítulo, color y código visibles en cada hotspot dentro de la escena 3D.
  static const Map<HotspotKind, ({String subtitle, String color})> _hotspotStyle =
      <HotspotKind, ({String subtitle, String color})>{
        HotspotKind.networking: (subtitle: "Sala Pública • SHES'T", color: '#22d3ee'),
        HotspotKind.createMeeting: (subtitle: 'Empresas Mundiales', color: '#38bdf8'),
        HotspotKind.qr: (subtitle: 'Kiosco • Compañía Privada', color: '#fbbf24'),
        HotspotKind.p2p: (subtitle: 'Mercado Shest', color: '#4ade80'),
        HotspotKind.escrow: (subtitle: 'Recepción WordVerse', color: '#fbbf24'),
        HotspotKind.myProfile: (subtitle: 'Tarjeta VR', color: '#22d3ee'),
        HotspotKind.exit: (subtitle: 'Portal Shest Hub', color: '#f87171'),
      };

  /// Id reservado para el hotspot de la barra Shest Coffee.
  static const String cafeKind = 'cafe';

  static List<Map<String, Object?>> hotspots({required bool includeCafe}) {
    return <Map<String, Object?>>[
      for (final HotspotKind spot in HotspotKind.values)
        <String, Object?>{
          'kind': spot.name,
          'code': spot.code,
          'title': spot.title,
          'subtitle': _hotspotStyle[spot]!.subtitle,
          'color': _hotspotStyle[spot]!.color,
          'x': spot.normX,
          'z': spot.normZ,
        },
      if (includeCafe)
        <String, Object?>{
          'kind': cafeKind,
          'code': 'SHEST COFFEE',
          'title': 'Café',
          'subtitle': 'Catálogo & USDT',
          'color': '#d4af37',
          'x': -0.24,
          'z': -0.50,
        },
    ];
  }

  static Map<String, Object?> avatarDto(AvatarRoomNode node) => <String, Object?>{
    'id': node.user.id,
    'name': node.user.name,
    'company': node.user.company,
    'status': node.user.status.label,
    'color': node.user.avatarHexColor & 0xFFFFFF,
    'x': node.normX,
    'z': node.normZ,
    'rot': node.rotationRadians,
    'moving': node.isMoving,
    if (node.activeEmote != null)
      'emote': '${node.activeEmote!.emoji} ${node.activeEmote!.label}',
  };

  static Map<String, Object?> init({
    required AvatarRoomNode local,
    required List<AvatarRoomNode> remotes,
    required String subRoom,
    required bool includeCafe,
  }) => <String, Object?>{
    'type': 'init',
    'hotspots': hotspots(includeCafe: includeCafe),
    'local': <String, Object?>{
      ...avatarDto(local),
      'x': local.normX,
      'z': local.normZ,
    },
    'remotes': remotes.map(avatarDto).toList(),
    'subRoom': subRoom,
    'world': <String, Object?>{
      'bound': RoomPhysicsController.maxBound,
      'spawnX': RoomPhysicsController.spawnX,
      'spawnZ': RoomPhysicsController.spawnZ,
    },
  };

  static Map<String, Object?> remotes(List<AvatarRoomNode> list) => <String, Object?>{
    'type': 'remotes',
    'list': list.map(avatarDto).toList(),
  };

  static Map<String, Object?> input(double x, double y) => <String, Object?>{
    'type': 'input',
    'x': x,
    'y': y,
  };

  static Map<String, Object?> camera({double? yaw, double? zoom, double? pitch}) => <String, Object?>{
    'type': 'camera',
    'yaw': ?yaw,
    'zoom': ?zoom,
    'pitch': ?pitch,
  };

  static Map<String, Object?> subRoom(String name) => <String, Object?>{
    'type': 'subRoom',
    'name': name,
  };

  static Map<String, Object?> emote(String text) => <String, Object?>{
    'type': 'emote',
    'text': text,
  };

  static Map<String, Object?> speaking({required String userId, required bool isSpeaking}) => <String, Object?>{
    'type': 'speaking',
    'userId': userId,
    'isSpeaking': isSpeaking,
  };

  static Map<String, Object?> teleport({double? x, double? z, String? zone, double? rot}) => <String, Object?>{
    'type': 'teleport',
    'x': ?x,
    'z': ?z,
    'zone': ?zone,
    'rot': ?rot,
  };

  /// Traduce `kind` recibido de la escena a un [HotspotKind] (null si es `cafe` o desconocido).
  static HotspotKind? hotspotFromKind(Object? kind) {
    for (final HotspotKind spot in HotspotKind.values) {
      if (spot.name == kind) return spot;
    }
    return null;
  }
}

/// Evento tipado emitido por la escena 3D.
sealed class Hub3DEvent {
  const Hub3DEvent();

  static Hub3DEvent? parse(Map<String, Object?> json) {
    if (json['source'] != Hub3DProtocol.fromScene) return null;
    switch (json['type']) {
      case 'ready':
        return const Hub3DReady();
      case 'error':
        return Hub3DError('${json['message'] ?? 'Error desconocido'}');
      case 'moved':
        final Object? x = json['x'], z = json['z'], rot = json['rot'];
        if (x is! num || z is! num) return null;
        return Hub3DMoved(
          x: x.toDouble(),
          z: z.toDouble(),
          rotation: rot is num ? rot.toDouble() : 0.0,
          moving: json['moving'] == true,
        );
      case 'interact':
        final Object? kind = json['kind'];
        return kind is String ? Hub3DInteract(kind) : null;
      case 'avatarTapped':
        final Object? id = json['id'];
        return id is String ? Hub3DAvatarTapped(id, json['isLocal'] == true) : null;
      case 'subRoomChanged':
        final Object? name = json['name'];
        return name is String ? Hub3DSubRoomChanged(name) : null;
      case 'kioskEscrowPurchase':
        return Hub3DKioskEscrowPurchase(
          escrowId: '${json['escrowId'] ?? ''}',
          productId: '${json['productId'] ?? ''}',
          productName: '${json['productName'] ?? 'Activo Kiosco'}',
          amountUsdt: (json['amountUsdt'] is num) ? (json['amountUsdt'] as num).toDouble() : 0.0,
          vendor: '${json['vendor'] ?? ''}',
        );
      case 'userSpeaking':
        final Object? userId = json['userId'];
        return userId is String
            ? Hub3DUserSpeaking(
                userId: userId,
                isSpeaking: json['isSpeaking'] == true,
              )
            : null;
    }
    return null;
  }
}

final class Hub3DReady extends Hub3DEvent {
  const Hub3DReady();
}

final class Hub3DError extends Hub3DEvent {
  const Hub3DError(this.message);
  final String message;
}

final class Hub3DMoved extends Hub3DEvent {
  const Hub3DMoved({
    required this.x,
    required this.z,
    required this.rotation,
    required this.moving,
  });
  final double x;
  final double z;
  final double rotation;
  final bool moving;
}

final class Hub3DInteract extends Hub3DEvent {
  const Hub3DInteract(this.kind);
  final String kind;
}

final class Hub3DAvatarTapped extends Hub3DEvent {
  const Hub3DAvatarTapped(this.id, this.isLocal);
  final String id;
  final bool isLocal;
}

final class Hub3DSubRoomChanged extends Hub3DEvent {
  const Hub3DSubRoomChanged(this.name);
  final String name;
}

final class Hub3DKioskEscrowPurchase extends Hub3DEvent {
  const Hub3DKioskEscrowPurchase({
    required this.escrowId,
    required this.productId,
    required this.productName,
    required this.amountUsdt,
    required this.vendor,
  });

  final String escrowId;
  final String productId;
  final String productName;
  final double amountUsdt;
  final String vendor;
}

final class Hub3DUserSpeaking extends Hub3DEvent {
  const Hub3DUserSpeaking({
    required this.userId,
    required this.isSpeaking,
  });

  final String userId;
  final bool isSpeaking;
}
