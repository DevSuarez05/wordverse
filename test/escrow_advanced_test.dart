import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordverse/core/api_client/shest_api_client.dart';
import 'package:wordverse/core/events/wordverse_events.dart';
import 'package:wordverse/core/models/shest_models.dart';
import 'package:wordverse/features/wordverse/3d_room/hub3d/hub3d_protocol.dart';
import 'package:wordverse/features/wordverse/meetings/escrow_sheet.dart';

void main() {
  group('Fase 5: Módulo Escrow Avanzado — Pruebas de Transiciones e Invariantes Financieras', () {
    late WordverseEventBus eventBus;
    late ShestApiClient apiClient;

    setUp(() {
      eventBus = WordverseEventBus();
      apiClient = ShestApiClient(eventBus: eventBus);
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('ESC-D1: Intento de liberar fondos en estado PENDING es rechazado con ESCROW_NOT_FUNDED', () async {
      final EscrowOperation op = await apiClient.escrow.createEscrow(
        creatorId: 'usr_1',
        counterpartyId: 'usr_2',
        amount: 500.0,
        description: 'Auditoría de contratos',
        conditions: 'Informe entregado',
      );
      expect(op.status, equals(EscrowStatus.pending));

      expect(
        () => apiClient.escrow.transitionEscrowState(
          escrowId: op.id,
          actorUserId: 'usr_1',
          targetStatus: EscrowStatus.released,
        ),
        throwsA(
          isA<ShestApiException>().having(
            (ShestApiException e) => e.code,
            'code',
            contains('ESCROW_NOT_FUNDED'),
          ),
        ),
      );
    });

    test('ESC-D2: Depósito y posterior Cancelación reembolsa íntegramente al creador', () async {
      final WalletInfo initialWallet = await apiClient.wallet.getWalletInfo('usr_1');
      final double initialBalance = initialWallet.usdtBalance;

      final EscrowOperation op = await apiClient.escrow.createEscrow(
        creatorId: 'usr_1',
        counterpartyId: 'usr_2',
        amount: 300.0,
        description: 'Servicio de diseño',
        conditions: 'Entrega final',
      );

      // Fondear la operación (debe descontar 300)
      final EscrowOperation funded = await apiClient.escrow.transitionEscrowState(
        escrowId: op.id,
        actorUserId: 'usr_1',
        targetStatus: EscrowStatus.funded,
      );
      expect(funded.status, equals(EscrowStatus.funded));

      final WalletInfo fundedWallet = await apiClient.wallet.getWalletInfo('usr_1');
      expect(fundedWallet.usdtBalance, equals(initialBalance - 300.0));

      // Cancelar la operación (debe reembolsar los 300)
      final EscrowOperation cancelled = await apiClient.escrow.transitionEscrowState(
        escrowId: op.id,
        actorUserId: 'usr_1',
        targetStatus: EscrowStatus.cancelled,
      );
      expect(cancelled.status, equals(EscrowStatus.cancelled));

      final WalletInfo refundedWallet = await apiClient.wallet.getWalletInfo('usr_1');
      expect(refundedWallet.usdtBalance, equals(initialBalance));
    });

    test('ESC-D3: Actor no autorizado es rechazado y contraparte no puede autoliberarse fondos', () async {
      final EscrowOperation op = await apiClient.escrow.createEscrow(
        creatorId: 'usr_1',
        counterpartyId: 'usr_2',
        amount: 250.0,
        description: 'Consultoría legal',
        conditions: 'Revisión técnica',
      );

      // Fondear
      await apiClient.escrow.transitionEscrowState(
        escrowId: op.id,
        actorUserId: 'usr_1',
        targetStatus: EscrowStatus.funded,
      );

      // Tercero no participante ('usr_intruder') intenta cancelar o liberar
      expect(
        () => apiClient.escrow.transitionEscrowState(
          escrowId: op.id,
          actorUserId: 'usr_intruder',
          targetStatus: EscrowStatus.cancelled,
        ),
        throwsA(
          isA<ShestApiException>().having(
            (ShestApiException e) => e.code,
            'code',
            contains('UNAUTHORIZED_ACTOR'),
          ),
        ),
      );

      // Contraparte ('usr_2') intenta liberarse a sí misma sin aprobación del creador
      expect(
        () => apiClient.escrow.transitionEscrowState(
          escrowId: op.id,
          actorUserId: 'usr_2',
          targetStatus: EscrowStatus.released,
        ),
        throwsA(
          isA<ShestApiException>().having(
            (ShestApiException e) => e.code,
            'code',
            contains('CANNOT_SELF_RELEASE'),
          ),
        ),
      );
    });

    test('Idempotencia y estados terminales sellados', () async {
      final EscrowOperation op = await apiClient.escrow.createEscrow(
        creatorId: 'usr_1',
        counterpartyId: 'usr_2',
        amount: 100.0,
        description: 'Prueba idempotencia',
        conditions: 'N/A',
      );

      // Idempotencia: transicionar al mismo estado no genera error ni doble descuento
      final EscrowOperation same = await apiClient.escrow.transitionEscrowState(
        escrowId: op.id,
        actorUserId: 'usr_1',
        targetStatus: EscrowStatus.pending,
      );
      expect(same.status, equals(EscrowStatus.pending));

      // Cancelar
      await apiClient.escrow.transitionEscrowState(
        escrowId: op.id,
        actorUserId: 'usr_1',
        targetStatus: EscrowStatus.cancelled,
      );

      // Intento de mover un estado terminal
      expect(
        () => apiClient.escrow.transitionEscrowState(
          escrowId: op.id,
          actorUserId: 'usr_1',
          targetStatus: EscrowStatus.funded,
        ),
        throwsA(
          isA<ShestApiException>().having(
            (ShestApiException e) => e.code,
            'code',
            contains('TERMINAL_STATE'),
          ),
        ),
      );
    });

    test('Audit Timeline cronológico acumula entradas estructuradas', () async {
      final EscrowOperation op = await apiClient.escrow.createEscrow(
        creatorId: 'usr_1',
        counterpartyId: 'usr_2',
        amount: 150.0,
        description: 'Timeline audit',
        conditions: 'Verificar logs',
      );

      await apiClient.escrow.transitionEscrowState(
        escrowId: op.id,
        actorUserId: 'usr_1',
        targetStatus: EscrowStatus.funded,
      );

      await apiClient.escrow.transitionEscrowState(
        escrowId: op.id,
        actorUserId: 'usr_1',
        targetStatus: EscrowStatus.released,
      );

      final List<EscrowOperation> list = await apiClient.escrow.listEscrows('usr_1');
      final EscrowOperation updated = list.firstWhere((EscrowOperation e) => e.id == op.id);
      expect(updated.historyLog.length, greaterThanOrEqualTo(2));
      expect(updated.historyLog.any((String log) => log.contains('PENDING ➔ FUNDED')), isTrue);
      expect(updated.historyLog.any((String log) => log.contains('FUNDED ➔ RELEASED')), isTrue);
    });

    test('Hub3DProtocol parsea correctamente kioskEscrowPurchase', () {
      final Hub3DEvent? event = Hub3DEvent.parse(<String, Object?>{
        'source': 'hub3d',
        'type': 'kioskEscrowPurchase',
        'escrowId': '#ESC-48210',
        'productId': 'kiosk_mesh_pass',
        'productName': 'Pase Mesh Kiosco',
        'amountUsdt': 180.0,
        'vendor': 'Nova Labs',
      });

      expect(event, isA<Hub3DKioskEscrowPurchase>());
      final Hub3DKioskEscrowPurchase purchase = event! as Hub3DKioskEscrowPurchase;
      expect(purchase.escrowId, equals('#ESC-48210'));
      expect(purchase.productName, equals('Pase Mesh Kiosco'));
      expect(purchase.amountUsdt, equals(180.0));
      expect(purchase.vendor, equals('Nova Labs'));
    });
  });

  group('Fase 5: UI EscrowCenterSheet — Sandbox, Matriz de Roles y Disputas', () {
    late WordverseEventBus eventBus;
    late ShestApiClient apiClient;

    setUp(() {
      eventBus = WordverseEventBus();
      apiClient = ShestApiClient(eventBus: eventBus);
    });

    tearDown(() {
      eventBus.dispose();
    });

    testWidgets('Muestra banner Sandbox Custodia Simulada y matriz contextual de acciones', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ShestAuthSession session = await apiClient.auth.loginWithShestSession(userId: 'usr_1');

      // Crear un escrow previo
      await apiClient.escrow.createEscrow(
        creatorId: session.user.id,
        counterpartyId: 'usr_2',
        amount: 500.0,
        description: 'Custodia Test UI',
        conditions: 'Términos aprobados',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EscrowCenterSheet(
              apiClient: apiClient,
              currentUser: session.user,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificar Banner Sandbox
      expect(find.textContaining('SANDBOX — CUSTODIA SIMULADA'), findsOneWidget);

      // Verificar que el escrow aparece
      expect(find.textContaining('ESCROW #45821'), findsWidgets);

      // Verificar botón de expansión de auditoría
      final Finder auditToggle = find.byKey(const Key('btn_toggle_audit_45821'));
      expect(auditToggle, findsOneWidget);

      // Tocar toggle para ver condiciones y timeline
      await tester.tap(auditToggle);
      await tester.pumpAndSettle();

      expect(find.textContaining('CONDICIONES PACTADAS'), findsWidgets);
      expect(find.textContaining('LÍNEA DE TIEMPO DE AUDITORÍA'), findsWidgets);
    });

    testWidgets('Modal de disputa exige motivo obligatorio antes de confirmar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ShestAuthSession session = await apiClient.auth.loginWithShestSession(userId: 'usr_1');

      // Crear y fondear una operación
      final EscrowOperation op = await apiClient.escrow.createEscrow(
        creatorId: session.user.id,
        counterpartyId: 'usr_2',
        amount: 200.0,
        description: 'Servicio con disputa',
        conditions: 'Contrato A',
      );
      await apiClient.escrow.transitionEscrowState(
        escrowId: op.id,
        actorUserId: session.user.id,
        targetStatus: EscrowStatus.funded,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EscrowCenterSheet(
              apiClient: apiClient,
              currentUser: session.user,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buscar botón de abrir disputa para esta operación
      final Finder disputeBtn = find.byKey(Key('escrow_${op.id}_to_DISPUTED'));
      expect(disputeBtn, findsOneWidget);

      // Abrir modal de disputa
      await tester.tap(disputeBtn);
      await tester.pumpAndSettle();

      // Verificar diálogo
      expect(find.textContaining('Abrir Disputa: Escrow #${op.id}'), findsOneWidget);

      // Intentar confirmar sin escribir motivo -> botón deshabilitado / no cierra
      final Finder confirmBtn = find.byKey(const Key('btn_confirm_dispute'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Sigue abierto porque reason está vacío
      expect(find.textContaining('Abrir Disputa: Escrow #${op.id}'), findsOneWidget);

      // Ingresar motivo
      await tester.enterText(
        find.byKey(const Key('input_dispute_reason')),
        'Incumplimiento de términos en entregable final',
      );
      await tester.pumpAndSettle();

      // Confirmar disputa
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verificar que el diálogo se cerró y ahora está en disputa
      expect(find.textContaining('Abrir Disputa: Escrow #${op.id}'), findsNothing);
      expect(find.textContaining('EN DISPUTA'), findsWidgets);
    });
  });
}
