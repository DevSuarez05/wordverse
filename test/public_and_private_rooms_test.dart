import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordverse/core/api_client/shest_api_client.dart';
import 'package:wordverse/core/events/wordverse_events.dart';
import 'package:wordverse/core/theme/wordverse_theme.dart';
import 'package:wordverse/features/wordverse/components/room_status_indicator.dart';
import 'package:wordverse/features/wordverse/models/private_room.dart';
import 'package:wordverse/features/wordverse/models/public_room.dart';
import 'package:wordverse/features/wordverse/screens/private_suites_screen.dart';
import 'package:wordverse/features/wordverse/screens/public_hub_screen.dart';

void main() {
  group('WordVerse Nexus — Public Rooms Domain & Logic', () {
    test('PublicRoom calcula capacidad y disponibilidad adecuadamente', () {
      const PublicRoom available = PublicRoom(
        id: 'r1',
        name: 'Tech Lounge',
        description: 'Discusión WebGL',
        category: 'Tech',
        host: 'Daniel',
        participantCount: 5,
        maxCapacity: 10,
        status: RoomAvailabilityStatus.disponible,
      );
      expect(available.isFull, isFalse);
      expect(available.canEnter, isTrue);

      const PublicRoom full = PublicRoom(
        id: 'r2',
        name: 'Sala Llena',
        description: 'Capacidad tope',
        category: 'Networking',
        host: 'Admin',
        participantCount: 10,
        maxCapacity: 10,
        status: RoomAvailabilityStatus.llena,
      );
      expect(full.isFull, isTrue);
      expect(full.canEnter, isFalse);
    });

    test('sampleCatalog contiene las salas públicas estratégicas', () {
      final List<PublicRoom> catalog = PublicRoom.sampleCatalog();
      expect(catalog.isNotEmpty, isTrue);
      expect(catalog.any((PublicRoom r) => r.category == 'Networking'), isTrue);
      expect(catalog.any((PublicRoom r) => r.category == 'P2P'), isTrue);
      expect(catalog.any((PublicRoom r) => r.category == 'Shest Café'), isTrue);
    });
  });

  group('WordVerse Nexus — Private Suites (The Boardroom) Domain & Verification', () {
    test('PrivateRoom autentica con passcode correcto y rechaza incorrecto', () {
      const PrivateRoom suite = PrivateRoom(
        id: 'boardroom_vip',
        name: 'The Executive Boardroom VIP',
        description: 'Sala de juntas ejecutiva',
        ownerId: 'usr_director',
        ownerName: 'Director VIP',
        passcode: 'SECRET777',
        userRole: RoomRole.guest,
        validTokens: <String>['TOKEN_INVITE_1'],
      );

      // Passcode correcto
      expect(suite.verifyAccess(enteredPasscode: 'SECRET777'), isTrue);

      // Passcode incorrecto
      expect(suite.verifyAccess(enteredPasscode: 'WRONG_CODE'), isFalse);

      // Token de invitación válido
      expect(suite.verifyAccess(enteredToken: 'TOKEN_INVITE_1'), isTrue);

      // Token inválido
      expect(suite.verifyAccess(enteredToken: 'EXPIRED_TOKEN'), isFalse);
    });

    test('Propietario de la sala siempre tiene acceso garantizado', () {
      const PrivateRoom ownedSuite = PrivateRoom(
        id: 'my_suite',
        name: 'Mi Suite',
        description: 'Suite propia',
        ownerId: 'usr_me',
        ownerName: 'Yo',
        passcode: '1234',
        userRole: RoomRole.owner,
      );
      expect(ownedSuite.isOwner, isTrue);
      expect(ownedSuite.verifyAccess(), isTrue);
      expect(ownedSuite.canControlHologram, isTrue);
      expect(ownedSuite.canInviteParticipants, isTrue);
      expect(ownedSuite.canCloseSuite, isTrue);
    });

    test('ShestApiClient persiste salas públicas y privadas, valida roles/invitaciones y cierra suites (WV-204)', () async {
      final WordverseEventBus bus = WordverseEventBus();
      addTearDown(bus.dispose);
      final ShestApiClient client = ShestApiClient(eventBus: bus);

      // 1. Crear Sala Pública persistente
      final PublicRoom pub = await client.createPublicRoom(
        creatorId: 'usr_1',
        creatorName: 'Daniel (Tú)',
        name: 'Cumbre Fintech Latam',
        description: 'Mesa abierta de pagos',
        category: 'Negocios',
        maxCapacity: 60,
      );
      expect(client.publicRooms.first.id, equals(pub.id));
      expect(pub.collaborativeTools, contains('Creación Escrow'));

      // 2. Crear Suite Privada VIP persistente con token automático
      final PrivateRoom suite = await client.createPrivateSuite(
        ownerId: 'usr_1',
        ownerName: 'Daniel (Tú)',
        name: 'Boardroom Sindicado Q4',
        description: 'Acuerdos confidenciales',
        passcode: 'GOLD2026',
        maxCapacity: 8,
      );
      expect(client.privateSuites.first.id, equals(suite.id));
      expect(suite.validTokens, isNotEmpty);

      // 3. Emitir nuevo token de invitación como Owner
      final String newToken = client.generateSuiteInvitationToken(suite.id);
      expect(newToken, startsWith('VIP-'));

      // 4. Validar acceso denegado vs autorizado en la suite de invitados (Investor Syndicate Suite)
      final PrivateRoom guestSuite = client.privateSuites.firstWhere(
        (PrivateRoom s) => s.id == 'priv_investor_circle',
      );
      final ({bool authorized, String message, RoomRole grantedRole}) denied =
          await client.authorizePrivateSuiteAccess(
            suite: guestSuite,
            enteredCredential: 'INVALID_PASS',
          );
      expect(denied.authorized, isFalse);

      final ({bool authorized, String message, RoomRole grantedRole}) accepted =
          await client.authorizePrivateSuiteAccess(
            suite: guestSuite,
            enteredCredential: 'SYNDICATE-TOKEN',
          );
      expect(accepted.authorized, isTrue);
      expect(accepted.grantedRole, equals(RoomRole.member));

      // 5. Cerrar Suite Privada como Owner e impedir nuevos accesos
      final PrivateRoom closed = client.closePrivateSuite(suite.id);
      expect(closed.isClosed, isTrue);
      expect(closed.verifyAccess(enteredPasscode: 'GOLD2026'), isFalse);
    });
  });

  group('WordVerse Nexus — UI Widgets & Flow', () {
    late ShestApiClient apiClient;

    setUp(() {
      apiClient = ShestApiClient(eventBus: WordverseEventBus());
    });

    testWidgets('PublicHubScreen renderiza catálogo de salas y permite buscar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WordVerseTheme.darkTheme,
          home: PublicHubScreen(
            apiClient: apiClient,
            onBackToLobby: () {},
            onEnterRoom: (_) {},
          ),
        ),
      );

      expect(find.text('WORDVERSE PUBLIC HUB'), findsOneWidget);
      expect(find.text('The Grand Nexus Plaza'), findsOneWidget);
      expect(find.text('Terminal P2P & Escrow Hub'), findsOneWidget);

      // Filtrar por texto
      await tester.enterText(find.byType(TextField), 'Terminal P2P');
      await tester.pump();

      expect(find.text('Terminal P2P & Escrow Hub'), findsOneWidget);
      expect(find.text('The Grand Nexus Plaza'), findsNothing);
    });

    testWidgets('PrivateSuitesScreen muestra Boardroom VIP y modal de credenciales', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WordVerseTheme.darkTheme,
          home: PrivateSuitesScreen(
            apiClient: apiClient,
            onBackToLobby: () {},
            onEnterBoardroom: (_) {},
          ),
        ),
      );

      expect(find.text('WORDVERSE PRIVATE SUITES'), findsOneWidget);
      expect(find.text('The Executive Boardroom VIP'), findsOneWidget);
      expect(find.text('Investor Syndicate Suite'), findsOneWidget);

      // Tocar en Desbloquear la sala restringida de inversionistas
      final Finder unlockBtn = find.text('DESBLOQUEAR');
      expect(unlockBtn, findsOneWidget);
      await tester.tap(unlockBtn);
      await tester.pumpAndSettle();

      // Debe aparecer el modal de seguridad
      expect(find.text('DESBLOQUEAR SUITE'), findsOneWidget);
      expect(find.text('VERIFICAR Y ACCEDER'), findsOneWidget);
    });
  });
}
