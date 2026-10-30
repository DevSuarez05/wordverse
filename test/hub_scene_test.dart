import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordverse/core/models/shest_models.dart';
import 'package:wordverse/features/wordverse/3d_room/room_3d_viewport.dart';
import 'package:wordverse/features/wordverse/avatar/avatar_node.dart';
import 'package:wordverse/features/wordverse/movement/room_physics_controller.dart';

void main() {
  const ShestUser user = ShestUser(
    id: 'u1',
    name: 'Ana',
    company: 'Shest',
    role: 'CEO',
    description: '',
    avatarInitials: 'AN',
    avatarHexColor: 0xFF22D3EE,
  );

  Widget scene(double yaw) => MaterialApp(
    home: Scaffold(
      body: RepaintBoundary(
        key: const Key('scene'),
        child: Room3DViewport(
          localAvatar: AvatarRoomNode(
            user: user,
            normX: RoomPhysicsController.spawnX,
            normZ: RoomPhysicsController.spawnZ,
            isLocalPlayer: true,
          ),
          remoteAvatars: const <AvatarRoomNode>[],
          activeHotspot: null,
          cameraPitch: 0.62,
          cameraZoom: 1.0,
          cameraYaw: yaw,
          showArchitecturalBackdrop: false,
          onAvatarTapped: (_) {},
          onHotspotTapped: (_) {},
        ),
      ),
    ),
  );

  testWidgets('Hub 3D se dibuja sin errores en una órbita completa (0..2π)', (
    WidgetTester tester,
  ) async {
    for (int i = 0; i < 12; i++) {
      await tester.pumpWidget(scene(i * 0.5236));
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull, reason: 'yaw paso $i');
    }
  });

  testWidgets('El reloj de animación se libera al desmontar el visor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(scene(0));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Golden de referencia visual del Hub (vista frontal)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(scene(0));
    await tester.pump(const Duration(milliseconds: 1500));
    await expectLater(
      find.byKey(const Key('scene')),
      matchesGoldenFile('goldens/hub_front.png'),
    );
  }, tags: 'golden');
}
