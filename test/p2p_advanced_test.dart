import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordverse/core/api_client/shest_api_client.dart';
import 'package:wordverse/core/events/wordverse_events.dart';
import 'package:wordverse/core/models/shest_models.dart';
import 'package:wordverse/features/wordverse/meetings/p2p_wallet_sheet.dart';

void main() {
  group('Fase 4 — WV-401: P2POperation Model & Architecture Unit Tests', () {
    test('P2POperation calcula totalFiat, límites automáticos y reputación', () {
      const P2POperation op = P2POperation(
        id: 'P2P-TEST-1',
        makerId: 'usr_maker',
        makerName: 'Valeria Maker',
        amountUsdt: 1200.0,
        rateUsd: 1.005,
        paymentMethod: 'Wire',
        status: 'OPEN',
        type: P2POperationType.buy,
      );

      expect(op.totalFiat, closeTo(1206.0, 0.01));
      expect(op.minAmountUsdt, 50.0);
      expect(op.maxAmountUsdt, 1200.0);
      expect(op.isOpen, isTrue);
      expect(op.isCompleted, isFalse);
      expect(op.isMaker('usr_maker'), isTrue);
      expect(op.isMaker('usr_other'), isFalse);
    });

    test('P2POperation.copyWith preserva o reemplaza propiedades financieras', () {
      const P2POperation op = P2POperation(
        id: 'P2P-TEST-2',
        makerId: 'usr_maker',
        makerName: 'Carlos Maker',
        amountUsdt: 500.0,
        rateUsd: 1.0,
        paymentMethod: 'Zelle',
        status: 'OPEN',
      );

      final P2POperation updated = op.copyWith(
        status: 'COMPLETED',
        takerId: 'usr_taker',
        takerName: 'Daniel Taker',
      );

      expect(updated.status, 'COMPLETED');
      expect(updated.isCompleted, isTrue);
      expect(updated.takerId, 'usr_taker');
      expect(updated.amountUsdt, 500.0);
    });
  });

  group('Fase 4 — WV-401 & WV-403: Reglas Financieras y Seguridad P2P', () {
    late WordverseEventBus eventBus;
    late ShestApiClient client;

    setUp(() {
      eventBus = WordverseEventBus();
      client = ShestApiClient(eventBus: eventBus);
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('Filtros reactivos por tipo (BUY/SELL) y búsqueda de liquidez', () async {
      final List<P2POperation> all = await client.p2p.listOperations();
      expect(all.length, greaterThanOrEqualTo(2));

      final List<P2POperation> buys = await client.p2p.listOperations(
        typeFilter: P2POperationType.buy,
      );
      for (final P2POperation b in buys) {
        expect(b.type, P2POperationType.buy);
      }

      final List<P2POperation> sells = await client.p2p.listOperations(
        typeFilter: P2POperationType.sell,
      );
      for (final P2POperation s in sells) {
        expect(s.type, P2POperationType.sell);
      }

      final List<P2POperation> searched = await client.p2p.listOperations(
        query: 'Carlos',
      );
      expect(searched.any((P2POperation o) => o.makerName.contains('Carlos')), isTrue);
    });

    test('Validación de saldo insuficiente al crear orden de venta', () async {
      expect(
        () => client.p2p.createOperation(
          makerId: 'usr_1',
          amountUsdt: 99999999.0, // Monto exorbitante
          rateUsd: 1.0,
          paymentMethod: 'Wire',
          type: P2POperationType.sell,
        ),
        throwsA(isA<ShestApiException>().having(
          (ShestApiException e) => e.code,
          'code',
          'INSUFFICIENT_FUNDS',
        )),
      );
    });

    test('Regla anti-autonegociación: Maker no puede tomar su propia oferta P2P', () async {
      final P2POperation myOp = await client.p2p.createOperation(
        makerId: 'usr_1',
        amountUsdt: 50.0,
        rateUsd: 1.0,
        paymentMethod: 'Zelle',
        type: P2POperationType.sell,
      );

      expect(
        () => client.p2p.acceptOperation(
          operationId: myOp.id,
          takerId: 'usr_1', // Mismo usuario
        ),
        throwsA(isA<ShestApiException>().having(
          (ShestApiException e) => e.code,
          'code',
          'CANNOT_ACCEPT_OWN_ORDER',
        )),
      );
    });

    test('Cancelación de orden P2P reintegra fondos al balance del maker', () async {
      final WalletInfo beforeW = await client.wallet.getWalletInfo('usr_1');
      final double initialBal = beforeW.usdtBalance;

      // Crear orden de venta por 200 USDT
      final P2POperation created = await client.p2p.createOperation(
        makerId: 'usr_1',
        amountUsdt: 200.0,
        rateUsd: 1.0,
        paymentMethod: 'Wire',
        type: P2POperationType.sell,
      );

      final WalletInfo lockedW = await client.wallet.getWalletInfo('usr_1');
      expect(lockedW.usdtBalance, closeTo(initialBal - 200.0, 0.01));

      // Cancelar la orden
      final P2POperation cancelled = await client.p2p.cancelOperation(created.id);
      expect(cancelled.status, 'CANCELLED');

      final WalletInfo refundedW = await client.wallet.getWalletInfo('usr_1');
      expect(refundedW.usdtBalance, closeTo(initialBal, 0.01));
    });
  });

  group('Fase 4 — WV-402 & WV-403: P2PAndWalletSheet Widget Integration', () {
    late WordverseEventBus eventBus;
    late ShestApiClient client;
    late ShestUser currentUser;

    setUp(() {
      eventBus = WordverseEventBus();
      client = ShestApiClient(eventBus: eventBus);
      currentUser = const ShestUser(
        id: 'usr_1',
        name: 'Daniel Directivo',
        company: 'WordVerse Corp',
        role: 'CEO',
        description: 'Director General',
        avatarInitials: 'DD',
        avatarHexColor: 0xFFD4AF37,
      );
    });

    tearDown(() {
      eventBus.dispose();
    });

    testWidgets('P2PAndWalletSheet renderiza libro de órdenes, filtros y permite aceptar P2P', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: P2PAndWalletSheet(
              apiClient: client,
              currentUser: currentUser,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar encabezado y balance
      expect(find.textContaining('Balance en Shest Wallet'), findsOneWidget);
      expect(find.byKey(const Key('input_search_p2p')), findsOneWidget);
      expect(find.byKey(const Key('btn_open_create_p2p')), findsOneWidget);

      // Verificar filtros de tipo
      expect(find.byKey(const Key('chip_filter_all')), findsOneWidget);
      expect(find.byKey(const Key('chip_filter_buy')), findsOneWidget);
      expect(find.byKey(const Key('chip_filter_sell')), findsOneWidget);

      // Filtrar por ventas
      await tester.tap(find.byKey(const Key('chip_filter_sell')));
      await tester.pumpAndSettle();

      // Buscar por orden P2P-901
      await tester.enterText(find.byKey(const Key('input_search_p2p')), 'P2P-901');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_accept_p2p_P2P-901')), findsOneWidget);

      // Aceptar la orden
      await tester.tap(find.byKey(const Key('btn_accept_p2p_P2P-901')));
      await tester.pumpAndSettle();

      // Debe mostrar estado de éxito
      expect(find.textContaining('ejecutada exitosamente'), findsOneWidget);
    });
  });
}
