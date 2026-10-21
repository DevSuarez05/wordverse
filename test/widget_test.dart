import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordverse/core/api_client/shest_api_client.dart';
import 'package:wordverse/core/events/wordverse_events.dart';
import 'package:wordverse/core/models/shest_models.dart';
import 'package:wordverse/features/wordverse/movement/room_physics_controller.dart';
import 'package:wordverse/main.dart';

void main() {
  group('WordVerse Nivel 1+ — Suite de 14 Pruebas (Fase 37) y Negocio (Fase 38)', () {
    late WordverseEventBus eventBus;
    late ShestApiClient apiClient;

    setUp(() {
      eventBus = WordverseEventBus();
      apiClient = ShestApiClient(eventBus: eventBus);
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('Pruebas 1 a 14 en Capa API + Física + Eventos (Fases 0 a 37)', () async {
      // PRUEBA 1 y 4: Sesión de usuario desde Shest y Movimiento con Colisiones
      final ShestAuthSession session =
          await apiClient.auth.loginWithShestSession(userId: 'usr_1');
      expect(session.user.name, contains('Daniel'));

      final ({double x, double z, double rotation, bool collided}) moveStep =
          RoomPhysicsController.computeStep(
            currentX: RoomPhysicsController.spawnX,
            currentZ: RoomPhysicsController.spawnZ,
            currentRotation: 0,
            joyDx: 0.8,
            joyDy: -0.5,
          );
      expect(moveStep.x, greaterThan(RoomPhysicsController.spawnX));
      expect(moveStep.z, lessThan(RoomPhysicsController.spawnZ));

      // PRUEBA 5 y 6: Crear reunión y generar código/QR
      final WordverseMeeting meeting = await apiClient.qr.createMeeting(
        creatorId: session.user.id,
        name: 'Reunión Inversión Latam',
        type: MeetingType.negocios,
        description: 'Cierre de trato B2B',
        isPrivate: false,
      );
      expect(meeting.code, startsWith('WV-'));
      expect(meeting.qrPayload, contains(meeting.code));

      // PRUEBA 7: Entrar / Validar por QR (WV-45821)
      final Map<String, Object?> qrValidation =
          await apiClient.qr.validateAndResolveQr(
            qrOrCode: 'WV-45821',
            scannerUserId: session.user.id,
          );
      expect(qrValidation['kind'], equals('MEETING'));

      // PRUEBA 8: Enviar conexión de Networking
      final ShestUser connectedPeer =
          await apiClient.auth.connectWithUser(targetUserId: 'usr_3');
      expect(connectedPeer.isConnected, isTrue);

      // PRUEBA 9: Chat
      final WordverseChatMessage msg = await apiClient.sendChatMessage(
        senderId: session.user.id,
        senderName: session.user.name,
        channelId: 'global_room',
        text: 'Listos para crear el Escrow #45821',
      );
      expect(apiClient.getChatMessages('global_room'), contains(msg));

      // PRUEBA 10: Abrir y aceptar orden P2P
      final List<P2POperation> p2pList = await apiClient.p2p.listOperations();
      expect(p2pList, isNotEmpty);
      final P2POperation acceptedP2p = await apiClient.p2p.acceptOperation(
        operationId: p2pList.first.id,
        takerId: session.user.id,
      );
      expect(acceptedP2p.status, equals('COMPLETED'));

      // PRUEBA 11: Crear Escrow #45821 en estado PENDING
      final EscrowOperation escrow = await apiClient.escrow.createEscrow(
        creatorId: session.user.id,
        counterpartyId: 'usr_2',
        amount: 1500.0,
        description: 'Suministro tecnológico',
        conditions: 'Entrega confirmada',
      );
      expect(escrow.id, equals('45821'));
      expect(escrow.status, equals(EscrowStatus.pending));

      // PRUEBA 12: Actualizar estados del Escrow (FUNDED -> RELEASED)
      final EscrowOperation funded =
          await apiClient.escrow.transitionEscrowState(
            escrowId: '45821',
            actorUserId: session.user.id,
            targetStatus: EscrowStatus.funded,
          );
      expect(funded.status, equals(EscrowStatus.funded));

      final EscrowOperation released =
          await apiClient.escrow.transitionEscrowState(
            escrowId: '45821',
            actorUserId: session.user.id,
            targetStatus: EscrowStatus.released,
          );
      expect(released.status, equals(EscrowStatus.released));

      // PRUEBA 13: Realizar flujo de pago validado por Shest Wallet API
      final PaymentRecord payment = await apiClient.wallet.createPayment(
        fromUserId: session.user.id,
        toUserId: 'usr_2',
        amountUsdt: 200.0,
        concept: 'Comisión acuerdo',
      );
      expect(payment.status, equals('CONFIRMED'));

      // PRUEBA 14: Manejo de error offline y recuperación (Fases 34 y 35)
      apiClient.simulateOffline = true;
      expect(
        () => apiClient.wallet.getWalletInfo(session.user.id),
        throwsA(isA<ShestApiException>()),
      );
      apiClient.simulateOffline = false;
      final WalletInfo recoveredWallet =
          await apiClient.wallet.getWalletInfo(session.user.id);
      expect(recoveredWallet.usdtBalance, greaterThan(0));
    });

    testWidgets(
      'Fase 38: Escenario UI Completo (Entrar a Sala 3D -> Ver Avatar -> Abrir Perfil -> Crear ESCROW #45821 PENDIENTE)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(WordverseApp(apiClient: apiClient));
        await tester.pump();

        // 1. Verificar puerta de entrada de sesión Shest y pulsar para entrar a la Sala 3D
        expect(find.text('SHEST LABS → WORDVERSE 3D'), findsOneWidget);
        await tester.tap(find.byKey(const Key('btn_enter_wordverse')));
        await tester.pump(const Duration(milliseconds: 250));

        // 2. Verificar que estamos en la Sala 3D viendo los 7 Hotspots y los Avatares conectados
        expect(find.text('HOTSPOT 05'), findsOneWidget);
        expect(find.byKey(const Key('avatar_usr_2')), findsOneWidget);

        // 3. Tocar otro avatar en la sala (Valeria Méndez) -> Abre Tarjeta de Perfil 3D (Fase 12)
        await tester.tap(find.byKey(const Key('avatar_usr_2')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Valeria Méndez'), findsWidgets);
        expect(find.byKey(const Key('profile_btn_escrow')), findsOneWidget);

        // 4. Pulsar el botón ESCROW en la tarjeta del avatar (Fase 20)
        await tester.tap(find.byKey(const Key('profile_btn_escrow')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // 5. Crear la operación de Escrow mediante Shest API y verificar "ESCROW #45821 PENDIENTE"
        await tester.tap(find.byKey(const Key('btn_submit_create_escrow')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.textContaining('ESCROW #45821 PENDIENTE'), findsWidgets);
      },
    );
  });
}
