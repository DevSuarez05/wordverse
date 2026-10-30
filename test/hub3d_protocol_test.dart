import 'package:flutter_test/flutter_test.dart';
import 'package:wordverse/core/models/shest_models.dart';
import 'package:wordverse/features/wordverse/3d_room/hub3d/hub3d_protocol.dart';
import 'package:wordverse/features/wordverse/avatar/avatar_node.dart';

void main() {
  const ShestUser user = ShestUser(
    id: 'u1',
    name: 'Ana',
    company: 'Shest',
    role: 'CEO',
    description: '',
    avatarInitials: 'AN',
    avatarHexColor: 0xFF22D3EE,
    status: UserPresenceStatus.busy,
  );
  const AvatarRoomNode node = AvatarRoomNode(
    user: user,
    normX: 0.1,
    normZ: -0.2,
    rotationRadians: 1.5,
    isMoving: true,
  );

  group('Hub3DProtocol', () {
    test('expone los 7 hotspots oficiales + café con coordenadas de Dart', () {
      final List<Map<String, Object?>> list = Hub3DProtocol.hotspots(
        includeCafe: true,
      );
      expect(list.length, HotspotKind.values.length + 1);
      for (final HotspotKind spot in HotspotKind.values) {
        final Map<String, Object?> dto = list.firstWhere(
          (Map<String, Object?> h) => h['kind'] == spot.name,
        );
        expect(dto['x'], spot.normX);
        expect(dto['z'], spot.normZ);
        expect(dto['title'], spot.title);
      }
      expect(
        Hub3DProtocol.hotspots(includeCafe: false).length,
        HotspotKind.values.length,
      );
    });

    test('avatarDto envía color sin alfa y estado legible', () {
      final Map<String, Object?> dto = Hub3DProtocol.avatarDto(node);
      expect(dto['color'], 0x22D3EE);
      expect(dto['status'], 'Ocupado');
      expect(dto['moving'], true);
      expect(dto.containsKey('emote'), false);
    });

    test('hotspotFromKind resuelve nombres y descarta cafe/desconocidos', () {
      expect(Hub3DProtocol.hotspotFromKind('escrow'), HotspotKind.escrow);
      expect(Hub3DProtocol.hotspotFromKind(Hub3DProtocol.cafeKind), isNull);
      expect(Hub3DProtocol.hotspotFromKind(42), isNull);
    });

    test('camera omite valores nulos', () {
      expect(Hub3DProtocol.camera(zoom: 1.2), <String, Object?>{
        'type': 'camera',
        'zoom': 1.2,
      });
    });
  });

  group('Hub3DEvent.parse', () {
    test('moved válido', () {
      final Hub3DEvent? e = Hub3DEvent.parse(<String, Object?>{
        'source': 'hub3d',
        'type': 'moved',
        'x': 0.3,
        'z': -0.1,
        'rot': 2,
        'moving': true,
      });
      expect(e, isA<Hub3DMoved>());
      expect((e! as Hub3DMoved).x, 0.3);
      expect((e as Hub3DMoved).rotation, 2.0);
    });

    test('ignora mensajes ajenos o malformados', () {
      expect(Hub3DEvent.parse(<String, Object?>{'type': 'moved'}), isNull);
      expect(
        Hub3DEvent.parse(<String, Object?>{
          'source': 'hub3d',
          'type': 'moved',
          'x': 'a',
        }),
        isNull,
      );
      expect(
        Hub3DEvent.parse(<String, Object?>{'source': 'hub3d', 'type': '???'}),
        isNull,
      );
    });

    test('interact, avatarTapped, ready y error', () {
      expect(
        Hub3DEvent.parse(<String, Object?>{
          'source': 'hub3d',
          'type': 'interact',
          'kind': 'qr',
        }),
        isA<Hub3DInteract>(),
      );
      expect(
        Hub3DEvent.parse(<String, Object?>{
          'source': 'hub3d',
          'type': 'avatarTapped',
          'id': 'usr_2',
        }),
        isA<Hub3DAvatarTapped>(),
      );
      expect(
        Hub3DEvent.parse(<String, Object?>{'source': 'hub3d', 'type': 'ready'}),
        isA<Hub3DReady>(),
      );
      expect(
        Hub3DEvent.parse(<String, Object?>{
          'source': 'hub3d',
          'type': 'error',
          'message': 'x',
        }),
        isA<Hub3DError>(),
      );
      expect(
        Hub3DEvent.parse(<String, Object?>{
          'source': 'hub3d',
          'type': 'kioskEscrowPurchase',
          'escrowId': '#ESC-100',
          'productId': 'p1',
          'productName': 'Item 1',
          'amountUsdt': 50.0,
          'vendor': 'Vendor 1',
        }),
        isA<Hub3DKioskEscrowPurchase>(),
      );
      expect(
        Hub3DEvent.parse(<String, Object?>{
          'source': 'hub3d',
          'type': 'userSpeaking',
          'userId': 'usr_1',
          'isSpeaking': true,
        }),
        isA<Hub3DUserSpeaking>(),
      );
    });

    test('speaking genera payload válido para el puente 3D', () {
      final Map<String, Object?> payload = Hub3DProtocol.speaking(
        userId: 'usr_2',
        isSpeaking: true,
      );
      expect(payload['type'], 'speaking');
      expect(payload['userId'], 'usr_2');
      expect(payload['isSpeaking'], true);
    });

    test('teleport genera payload correcto por zona o coordenadas', () {
      final Map<String, Object?> byZone = Hub3DProtocol.teleport(zone: 'boardroom');
      expect(byZone['type'], 'teleport');
      expect(byZone['zone'], 'boardroom');
      expect(byZone.containsKey('x'), false);

      final Map<String, Object?> byCoords = Hub3DProtocol.teleport(x: 0.5, z: -0.2, rot: 1.57);
      expect(byCoords['type'], 'teleport');
      expect(byCoords['x'], 0.5);
      expect(byCoords['z'], -0.2);
      expect(byCoords['rot'], 1.57);
      expect(byCoords.containsKey('zone'), false);
    });
  });
}
