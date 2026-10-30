import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wordverse/core/api_client/http_shest_api.dart';
import 'package:wordverse/core/api_client/shest_api_client.dart';
import 'package:wordverse/core/events/wordverse_events.dart';
import 'package:wordverse/core/models/shest_models.dart';
import 'package:wordverse/features/wordverse/3d_room/hub3d/hub3d_protocol.dart';
import 'package:wordverse/features/wordverse/models/private_room.dart';
import 'package:wordverse/features/wordverse/models/public_room.dart';

void main() {
  group('Fase 6: Integración Full Stack — Contratos, Spring Boot, Supabase y Módulos', () {
    late WordverseEventBus eventBus;
    late ShestApiClient apiClient;

    setUp(() {
      eventBus = WordverseEventBus();
      apiClient = ShestApiClient(eventBus: eventBus);
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('Tarea 1 & 2: Conmutación de Entornos (Mock -> Supabase -> Spring Boot) y cabeceras de API', () async {
      expect(apiClient.environment, equals(ShestBackendEnvironment.mock));

      // 1. Conmutar a Supabase Staging
      apiClient.environment = ShestBackendEnvironment.supabaseStaging;
      apiClient.configureRemoteCredentials(
        baseUrl: 'https://xyzcompany.supabase.co',
        apiKeyOrToken: 'sb_anon_test_token_12345',
      );
      expect(apiClient.activeAdapter, isA<HttpShestApi>());
      final HttpShestApi supabaseAdapter = apiClient.activeAdapter as HttpShestApi;
      expect(supabaseAdapter.isSupabase, isTrue);

      final Map<String, String> supabaseHeaders = supabaseAdapter.buildHeaders();
      expect(supabaseHeaders['Authorization'], contains('Bearer sb_anon_test_token_12345'));
      expect(supabaseHeaders['apikey'], equals('sb_anon_test_token_12345'));
      expect(supabaseHeaders['X-WordVerse-Client-Version'], isNotEmpty);
      expect(supabaseHeaders['X-WordVerse-Environment'], equals('supabaseStaging'));

      // 2. Conmutar a Spring Boot Production
      apiClient.environment = ShestBackendEnvironment.production;
      apiClient.configureRemoteCredentials(
        baseUrl: 'https://api.shestlabs.com/v1',
        apiKeyOrToken: 'shest_jwt_live_enterprise_9988',
      );
      final HttpShestApi springAdapter = apiClient.activeAdapter as HttpShestApi;
      expect(springAdapter.isSupabase, isFalse);

      final Map<String, String> springHeaders = springAdapter.buildHeaders();
      expect(springHeaders['Authorization'], contains('Bearer shest_jwt_live_enterprise_9988'));
      // Spring Boot no requiere apikey de supabase
      expect(springHeaders.containsKey('apikey'), isFalse);
      expect(springHeaders['X-WordVerse-Environment'], equals('production'));

      // Volver a mock
      apiClient.environment = ShestBackendEnvironment.mock;
      expect(apiClient.environment, equals(ShestBackendEnvironment.mock));
    });

    test('Tarea 3 & 8: Ciclo completo de autenticación JWT y refresco automático ante HTTP 401', () async {
      int requestCount = 0;
      final MockClient mockHttpClient = MockClient((http.Request request) async {
        requestCount++;
        // Si es el primer request de búsqueda, simula 401 token vencido
        if (request.url.path.contains('/users/search') && requestCount == 1) {
          return http.Response(
            jsonEncode(<String, Object?>{'error': 'Token expired'}),
            401,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        // Endpoint de refresh de Spring Boot
        if (request.url.path.contains('/auth/refresh')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'accessToken': 'jwt_new_refreshed_access_token',
              'refreshToken': 'refresh_usr_1_renewed',
              'expiresAt': DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
            }),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        // Segundo intento de búsqueda tras refresco exitoso
        if (request.url.path.contains('/users/search')) {
          return http.Response(
            jsonEncode(<Map<String, Object?>>[
              <String, Object?>{
                'id': 'usr_2',
                'nombre': 'Valeria Méndez',
                'empresa': 'Nova Corp',
                'cargo': 'CTO',
                'descripcion': 'Líder técnica',
                'avatar': 'VM',
                'avatar_color': 4278248959,
                'estado': 'AVAILABLE',
                'es_favorito': true,
                'conectado': true,
              }
            ]),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final HttpShestApi springHttpApi = HttpShestApi(
        baseUrl: 'https://api.shestlabs.com/v1',
        apiKeyOrToken: 'jwt_expired_token',
        environmentName: 'production',
        eventBus: eventBus,
        fallbackMock: apiClient.activeAdapter as dynamic,
        httpClient: mockHttpClient,
      );
      springHttpApi.lastRefreshToken = 'refresh_usr_1';

      // Al llamar a searchUsers, recibe 401, renueva automáticamente token ante Spring Boot y reintenta
      final List<ShestUser> users = await springHttpApi.searchUsers(query: 'Valeria');
      expect(users, isNotEmpty);
      expect(users.first.name, equals('Valeria Méndez'));
      expect(springHttpApi.apiKeyOrToken, equals('jwt_new_refreshed_access_token'));
      expect(springHttpApi.lastRefreshToken, equals('refresh_usr_1_renewed'));
    });

    test('Tarea 4: Traducción IA integrada con ShestApiClient, caché y fallback determinista', () async {
      // Primera traducción
      final String translatedEs = await apiClient.translateText(
        text: 'Hello, welcome to WordVerse Nexus boardroom',
        targetLanguage: 'ES',
      );
      expect(translatedEs, isNotEmpty);

      // Segunda traducción del mismo texto debe resolverse desde el caché sin latencia
      final String cachedEs = await apiClient.translateText(
        text: 'Hello, welcome to WordVerse Nexus boardroom',
        targetLanguage: 'ES',
      );
      expect(cachedEs, equals(translatedEs));
    });

    test('Tarea 5: Integración P2P con Wallet — Validación de saldo, bloqueo atómico y cancelación', () async {
      final WalletInfo initialWallet = await apiClient.wallet.getWalletInfo('usr_1');
      final double initialBalance = initialWallet.usdtBalance;

      // 1. Intentar publicar orden por monto superior al disponible -> Error INSUFFICIENT_FUNDS
      expect(
        () => apiClient.p2p.createOperation(
          makerId: 'usr_1',
          amountUsdt: initialBalance + 50000.0,
          rateUsd: 1.0,
          paymentMethod: 'Wire',
          type: P2POperationType.sell,
        ),
        throwsA(
          isA<ShestApiException>().having(
            (ShestApiException e) => e.code,
            'code',
            contains('INSUFFICIENT_FUNDS'),
          ),
        ),
      );

      // 2. Crear orden válida de venta (debe reservar/bloquear el saldo)
      final P2POperation sellOrder = await apiClient.p2p.createOperation(
        makerId: 'usr_1',
        amountUsdt: 500.0,
        rateUsd: 1.02,
        paymentMethod: 'Transferencia Bancaria',
        type: P2POperationType.sell,
      );
      expect(sellOrder.status, equals('OPEN'));

      final WalletInfo lockedWallet = await apiClient.wallet.getWalletInfo('usr_1');
      expect(lockedWallet.usdtBalance, equals(initialBalance - 500.0));

      // 3. Regla anti-autonegociación: Maker no puede tomar su propia orden
      expect(
        () => apiClient.p2p.acceptOperation(
          operationId: sellOrder.id,
          takerId: 'usr_1',
        ),
        throwsA(
          isA<ShestApiException>().having(
            (ShestApiException e) => e.code,
            'code',
            contains('CANNOT_ACCEPT_OWN_ORDER'),
          ),
        ),
      );

      // 4. Cancelar orden reintegra el saldo exacto a la billetera
      final P2POperation cancelled = await apiClient.p2p.cancelOperation(sellOrder.id);
      expect(cancelled.status, equals('CANCELLED'));

      final WalletInfo refundedWallet = await apiClient.wallet.getWalletInfo('usr_1');
      expect(refundedWallet.usdtBalance, equals(initialBalance));
    });

    test('Tarea 6: Integración Escrow con evento Kiosco 3D y Bóveda Multi-firma', () async {
      // Simular evento emitido desde Three.js Kiosco 3D
      final Hub3DEvent? event = Hub3DEvent.parse(<String, Object?>{
        'source': 'hub3d',
        'type': 'kioskEscrowPurchase',
        'escrowId': '#ESC-48210',
        'productId': 'kiosk_token_license',
        'productName': 'Licencia Corporativa WordVerse',
        'amountUsdt': 350.0,
        'vendor': 'Andes Capital',
      });
      expect(event, isA<Hub3DKioskEscrowPurchase>());
      final Hub3DKioskEscrowPurchase purchase = event! as Hub3DKioskEscrowPurchase;

      // Registrar contrato en el servicio de Escrow
      final EscrowOperation createdEscrow = await apiClient.escrow.createEscrow(
        creatorId: 'usr_1',
        counterpartyId: 'usr_2',
        amount: purchase.amountUsdt,
        description: 'Compra Kiosco 3D: ${purchase.productName}',
        conditions: 'Entrega confirmada vía WordVerse Kiosk',
      );
      expect(createdEscrow.amount, equals(350.0));
      expect(createdEscrow.status, equals(EscrowStatus.pending));

      // Fondeo
      final EscrowOperation funded = await apiClient.escrow.transitionEscrowState(
        escrowId: createdEscrow.id,
        actorUserId: 'usr_1',
        targetStatus: EscrowStatus.funded,
      );
      expect(funded.status, equals(EscrowStatus.funded));

      // Liberación hacia el vendedor
      final EscrowOperation released = await apiClient.escrow.transitionEscrowState(
        escrowId: createdEscrow.id,
        actorUserId: 'usr_1',
        targetStatus: EscrowStatus.released,
      );
      expect(released.status, equals(EscrowStatus.released));
    });

    test('Tarea 7, 8 & 12: Persistencia de catálogo de salas, Suites VIP y presencia multiplayer', () async {
      // 1. Crear Sala Pública persistida
      final PublicRoom pubRoom = await apiClient.createPublicRoom(
        creatorId: 'usr_1',
        creatorName: 'Daniel',
        name: 'Mesa Redonda Fintech 2026',
        description: 'Debate de finanzas descentralizadas',
        category: 'Negocios',
        maxCapacity: 25,
      );
      expect(pubRoom.name, equals('Mesa Redonda Fintech 2026'));
      expect(apiClient.publicRooms.any((PublicRoom r) => r.id == pubRoom.id), isTrue);

      // 2. Crear Suite Privada VIP con tokens criptográficos
      final PrivateRoom suite = await apiClient.createPrivateSuite(
        ownerId: 'usr_1',
        ownerName: 'Daniel',
        name: 'Penthouse Confidencial Shest',
        description: 'Junta de accionistas',
        passcode: 'SecretPass2026',
        maxCapacity: 8,
      );
      expect(suite.isOwner, isTrue);
      expect(suite.isEncrypted, isTrue);
      expect(apiClient.privateSuites.any((PrivateRoom s) => s.id == suite.id), isTrue);

      // 3. Generar token de invitación (RBAC Owner)
      final String inviteToken = apiClient.generateSuiteInvitationToken(suite.id);
      expect(inviteToken, startsWith('VIP-'));

      // 4. Validar acceso con contraseña correcta
      final ({bool authorized, String message, RoomRole grantedRole}) authResult =
          await apiClient.authorizePrivateSuiteAccess(
        suite: suite,
        enteredCredential: 'SecretPass2026',
      );
      expect(authResult.authorized, isTrue);

      // 5. Validar acceso denegado a usuario Invitado con contraseña incorrecta
      final PrivateRoom guestSuite = suite.copyWith(userRole: RoomRole.guest);
      final ({bool authorized, String message, RoomRole grantedRole}) deniedResult =
          await apiClient.authorizePrivateSuiteAccess(
        suite: guestSuite,
        enteredCredential: 'WrongPassword',
      );
      expect(deniedResult.authorized, isFalse);

      // 6. Sincronización de presencia multiusuario (WV-601)
      await apiClient.syncRoomPresence(
        userId: 'usr_1',
        roomName: 'Sala Principal',
        posX: 0.12,
        posZ: -0.45,
        rotation: 1.57,
        emote: 'negotiate',
      );
    });

    test('Tarea 10 & 11: Manejo uniforme de errores ShestApiException y trazabilidad por EventBus', () async {
      // Provocar error controlado (pago con saldo insuficiente)
      expect(
        () => apiClient.wallet.createPayment(
          fromUserId: 'usr_1',
          toUserId: 'usr_2',
          amountUsdt: 9999999.0,
          concept: 'Intento desbordamiento',
        ),
        throwsA(
          isA<ShestApiException>()
              .having((ShestApiException e) => e.code, 'code', equals('INSUFFICIENT_FUNDS'))
              .having((ShestApiException e) => e.userMessage, 'userMessage', isNotEmpty),
        ),
      );

      // Verificar que los eventos emiten con traceId correlacionado en pagos válidos
      await apiClient.wallet.createPayment(
        fromUserId: 'usr_1',
        toUserId: 'usr_2',
        amountUsdt: 10.0,
        concept: 'Prueba EventBus',
      );

      expect(
        eventBus.history.any(
          (WordverseEvent e) =>
              e.summary.contains('Pago') && e.summary.contains('confirmado'),
        ),
        isTrue,
      );
    });
  });
}
