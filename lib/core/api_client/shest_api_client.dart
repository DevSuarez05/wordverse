import '../../features/wordverse/components/room_status_indicator.dart';
import '../../features/wordverse/models/private_room.dart';
import '../../features/wordverse/models/public_room.dart';
import '../config/wordverse_env_config.dart';
import '../events/wordverse_events.dart';
import '../mocks/mock_shest_api.dart';
import '../models/shest_models.dart';
import 'auth_service.dart';
import 'escrow_service.dart';
import 'http_shest_api.dart';
import 'p2p_service.dart';
import 'qr_service.dart';
import 'shest_backend_adapter.dart';
import 'wallet_service.dart';
import '../services/wordverse_translation_service.dart';

/// Modos de entorno soportados para integración con Shest Labs (Entregable #19).
enum ShestBackendEnvironment {
  /// Modo local/en memoria para desarrollo inmediato sin bloqueos.
  mock('Mock Shest Labs (Simulador Local)', 'mock://shest.local'),

  /// Modo de pruebas para 2 desarrolladores usando tablas en Supabase.
  supabaseStaging(
    'Supabase Staging (Dev 1 + Dev 2)',
    WordverseEnvConfig.defaultSupabaseUrl,
  ),

  /// API productiva en Java Spring Boot de Shest Labs.
  production(
    'Shest Java Spring Boot API',
    WordverseEnvConfig.defaultShestApiUrl,
  );

  const ShestBackendEnvironment(this.label, this.baseUrl);
  final String label;
  final String baseUrl;
}

/// Punto único de comunicación entre WordVerse y Shest Labs (Fase 1).
///
/// Conmuta dinámicamente entre [MockShestApi], Supabase Staging y la API Java
/// de Shest Labs (`https://api.shestlabs.com/v1`) sin modificar la Sala 3D.
class ShestApiClient {
  ShestApiClient({
    required this.eventBus,
    this.environment = ShestBackendEnvironment.mock,
  }) : _mockAdapter = MockShestApi(eventBus: eventBus) {
    _supabaseAdapter = HttpShestApi(
      baseUrl: WordverseEnvConfig.envSupabaseUrl,
      apiKeyOrToken: WordverseEnvConfig.envSupabaseAnonKey,
      environmentName: ShestBackendEnvironment.supabaseStaging.name,
      eventBus: eventBus,
      fallbackMock: _mockAdapter,
    );
    _productionAdapter = HttpShestApi(
      baseUrl: WordverseEnvConfig.envShestApiUrl,
      apiKeyOrToken: WordverseEnvConfig.envShestToken,
      environmentName: ShestBackendEnvironment.production.name,
      eventBus: eventBus,
      fallbackMock: _mockAdapter,
    );
  }

  final WordverseEventBus eventBus;
  ShestBackendEnvironment environment;

  final MockShestApi _mockAdapter;
  late final HttpShestApi _supabaseAdapter;
  late final HttpShestApi _productionAdapter;

  final List<PublicRoom> _publicRooms = List<PublicRoom>.of(
    PublicRoom.sampleCatalog(),
  );
  final List<PrivateRoom> _privateSuites = List<PrivateRoom>.of(
    PrivateRoom.sampleSuites(),
  );

  /// Catálogo persistente de Salas Públicas sincronizado con la sesión actual (WV-204).
  List<PublicRoom> get publicRooms => List<PublicRoom>.unmodifiable(_publicRooms);

  /// Catálogo persistente de Suites Privadas VIP sincronizado con la sesión actual (WV-204).
  List<PrivateRoom> get privateSuites =>
      List<PrivateRoom>.unmodifiable(_privateSuites);

  /// Crea y persiste una nueva Sala Pública en el catálogo y en el servicio de reuniones de Shest.
  Future<PublicRoom> createPublicRoom({
    required String creatorId,
    required String creatorName,
    required String name,
    required String description,
    required String category,
    required int maxCapacity,
  }) async {
    final MeetingType meetingType = switch (category) {
      'P2P' => MeetingType.p2p,
      'Negocios' => MeetingType.negocios,
      'Shest Café' => MeetingType.cafe,
      _ => MeetingType.networking,
    };

    final WordverseMeeting createdMeeting = await qr.createMeeting(
      creatorId: creatorId,
      name: name,
      type: meetingType,
      description: description,
      isPrivate: false,
    );

    final PublicRoom newRoom = PublicRoom(
      id: 'pub_${createdMeeting.id}',
      name: name,
      description: description.trim().isEmpty
          ? 'Sala abierta de la comunidad WordVerse.'
          : description.trim(),
      category: category,
      status: RoomAvailabilityStatus.disponible,
      participantCount: 1,
      maxCapacity: maxCapacity,
      host: creatorName,
      tags: <String>[category, createdMeeting.code, 'Comunidad'],
      subRoomKey: category == 'P2P'
          ? 'P2P'
          : (category == 'Shest Café' ? 'Shest Café' : 'Sala Principal'),
    );

    _publicRooms.insert(0, newRoom);
    eventBus.emit(
      WordverseEventType.roomStateSynced,
      'Sala Pública creada: ${newRoom.name} (${createdMeeting.code})',
      <String, Object?>{'roomId': newRoom.id, 'code': createdMeeting.code},
    );
    return newRoom;
  }

  /// Crea y persiste una nueva Suite Privada VIP con token criptográfico de invitación.
  Future<PrivateRoom> createPrivateSuite({
    required String ownerId,
    required String ownerName,
    required String name,
    required String description,
    String? passcode,
    required int maxCapacity,
  }) async {
    final WordverseMeeting createdMeeting = await qr.createMeeting(
      creatorId: ownerId,
      name: name,
      type: MeetingType.privada,
      description: description,
      isPrivate: true,
    );

    final String inviteToken =
        'INV-VIP-${createdMeeting.code.replaceAll('WV-', '')}';
    final PrivateRoom newSuite = PrivateRoom(
      id: 'priv_${createdMeeting.id}',
      name: name,
      description: description.trim().isEmpty
          ? 'Sala ejecutiva confidencial con hologramas 3D.'
          : description.trim(),
      ownerId: ownerId,
      ownerName: ownerName,
      passcode: (passcode == null || passcode.trim().isEmpty)
          ? null
          : passcode.trim(),
      userRole: RoomRole.owner,
      participantCount: 1,
      maxCapacity: maxCapacity,
      isEncrypted: true,
      meetingCode: createdMeeting.code,
      validTokens: <String>[inviteToken],
      subRoomKey: 'Sala Privada',
    );

    _privateSuites.insert(0, newSuite);
    eventBus.emit(
      WordverseEventType.roomStateSynced,
      'Suite Privada VIP creada: ${newSuite.name} (Token: $inviteToken)',
      <String, Object?>{
        'suiteId': newSuite.id,
        'meetingCode': createdMeeting.code,
        'inviteToken': inviteToken,
      },
    );
    return newSuite;
  }

  /// Genera un nuevo token de invitación para una Suite Privada (requiere rol Owner o Moderator).
  String generateSuiteInvitationToken(String suiteId) {
    final int idx = _privateSuites.indexWhere((PrivateRoom s) => s.id == suiteId);
    if (idx < 0) {
      throw const ShestApiException(
        code: 'SUITE_NOT_FOUND',
        userMessage: 'No se encontró la Suite Privada solicitada.',
        statusCode: 404,
      );
    }
    final PrivateRoom current = _privateSuites[idx];
    if (!current.canInviteParticipants) {
      throw const ShestApiException(
        code: 'FORBIDDEN_ROLE',
        userMessage:
            'Solo el Propietario o Moderador puede emitir invitaciones VIP.',
        statusCode: 403,
      );
    }
    final String token =
        'VIP-${suiteId.hashCode.abs() % 9000 + 1000}-${current.validTokens.length + 1}';
    final PrivateRoom updated = current.copyWith(
      validTokens: <String>[...current.validTokens, token],
    );
    _privateSuites[idx] = updated;
    eventBus.emit(
      WordverseEventType.roomStateSynced,
      'Nuevo token de invitación emitido para ${current.name}: $token',
      <String, Object?>{'suiteId': suiteId, 'token': token},
    );
    return token;
  }

  /// Cierra una Suite Privada VIP (solo permitido al Propietario).
  PrivateRoom closePrivateSuite(String suiteId) {
    final int idx = _privateSuites.indexWhere((PrivateRoom s) => s.id == suiteId);
    if (idx < 0) {
      throw const ShestApiException(
        code: 'SUITE_NOT_FOUND',
        userMessage: 'No se encontró la Suite Privada solicitada.',
        statusCode: 404,
      );
    }
    final PrivateRoom current = _privateSuites[idx];
    if (!current.canCloseSuite) {
      throw const ShestApiException(
        code: 'FORBIDDEN_ROLE',
        userMessage: 'Solo el Propietario de la Suite puede cerrarla.',
        statusCode: 403,
      );
    }
    final PrivateRoom closed = current.copyWith(isClosed: true);
    _privateSuites[idx] = closed;
    eventBus.emit(
      WordverseEventType.roomStateSynced,
      'Suite Privada cerrada por el propietario: ${current.name}',
      <String, Object?>{'suiteId': suiteId},
    );
    return closed;
  }

  /// Valida en la capa de servicios el acceso a una Suite Privada VIP por rol, contraseña o token.
  Future<({bool authorized, String message, RoomRole grantedRole})>
      authorizePrivateSuiteAccess({
    required PrivateRoom suite,
    String? enteredCredential,
  }) async {
    if (suite.isClosed) {
      return (
        authorized: false,
        message: 'Esta Suite Privada ha sido cerrada por el anfitrión.',
        grantedRole: suite.userRole,
      );
    }
    if (suite.isFull) {
      return (
        authorized: false,
        message:
            'La Suite "${suite.name}" ha alcanzado su aforo máximo (${suite.maxCapacity} ejecutivos).',
        grantedRole: suite.userRole,
      );
    }
    final String cred = (enteredCredential ?? '').trim();
    final bool ok = suite.verifyAccess(
      enteredPasscode: cred,
      enteredToken: cred,
    );
    if (!ok) {
      eventBus.emit(
        WordverseEventType.apiError,
        'Intento de acceso denegado a Suite VIP "${suite.name}"',
        <String, Object?>{'suiteId': suite.id},
        WordverseEventSeverity.warning,
      );
      return (
        authorized: false,
        message: 'Credencial o token no válido. Acceso denegado.',
        grantedRole: RoomRole.guest,
      );
    }

    final RoomRole grantedRole = suite.isModerator
        ? suite.userRole
        : RoomRole.member;
    final int idx = _privateSuites.indexWhere((PrivateRoom s) => s.id == suite.id);
    if (idx >= 0) {
      _privateSuites[idx] = _privateSuites[idx].copyWith(userRole: grantedRole);
    }
    eventBus.emit(
      WordverseEventType.joinMeeting,
      'Acceso autorizado a Suite VIP "${suite.name}" (${grantedRole.label})',
      <String, Object?>{'suiteId': suite.id, 'role': grantedRole.name},
    );
    return (
      authorized: true,
      message: 'Acceso autorizado (${grantedRole.label}).',
      grantedRole: grantedRole,
    );
  }

  /// Permite configurar en caliente la URL y el `ANON_KEY` / Token JWT de
  /// Supabase o del Backend Java de Shest desde la interfaz de acceso.
  void configureRemoteCredentials({
    required String baseUrl,
    required String apiKeyOrToken,
  }) {
    if (environment == ShestBackendEnvironment.supabaseStaging) {
      if (baseUrl.trim().isNotEmpty) {
        _supabaseAdapter.baseUrl = baseUrl.trim();
      }
      _supabaseAdapter.apiKeyOrToken = apiKeyOrToken.trim();
    } else if (environment == ShestBackendEnvironment.production) {
      if (baseUrl.trim().isNotEmpty) {
        _productionAdapter.baseUrl = baseUrl.trim();
      }
      _productionAdapter.apiKeyOrToken = apiKeyOrToken.trim();
    }
  }

  String get currentRemoteUrl {
    switch (environment) {
      case ShestBackendEnvironment.mock:
        return ShestBackendEnvironment.mock.baseUrl;
      case ShestBackendEnvironment.supabaseStaging:
        return _supabaseAdapter.baseUrl;
      case ShestBackendEnvironment.production:
        return _productionAdapter.baseUrl;
    }
  }

  String get currentRemoteKey {
    switch (environment) {
      case ShestBackendEnvironment.mock:
        return '';
      case ShestBackendEnvironment.supabaseStaging:
        return _supabaseAdapter.apiKeyOrToken;
      case ShestBackendEnvironment.production:
        return _productionAdapter.apiKeyOrToken;
    }
  }

  ShestBackendAdapter get activeAdapter {
    switch (environment) {
      case ShestBackendEnvironment.mock:
        return _mockAdapter;
      case ShestBackendEnvironment.supabaseStaging:
        return _supabaseAdapter;
      case ShestBackendEnvironment.production:
        return _productionAdapter;
    }
  }

  ShestAuthService get auth => activeAdapter;
  ShestWalletService get wallet => activeAdapter;
  ShestP2PService get p2p => activeAdapter;
  ShestEscrowService get escrow => activeAdapter;
  ShestQrService get qr => activeAdapter;

  /// Sincroniza la presencia del avatar local en la sala correspondiente (WV-601).
  Future<void> syncRoomPresence({
    required String userId,
    required String roomName,
    required double posX,
    required double posZ,
    required double rotation,
    String? emote,
    bool online = true,
  }) async {
    if (activeAdapter is HttpShestApi) {
      await (activeAdapter as HttpShestApi).updateRoomPresence(
        userId: userId,
        roomName: roomName,
        posX: posX,
        posZ: posZ,
        rotation: rotation,
        emote: emote,
        online: online,
      );
    }
  }

  /// Consulta la lista de avatares presentes en una sala (WV-601).
  Future<List<Map<String, Object?>>> getRoomPresence({
    required String roomName,
  }) async {
    if (activeAdapter is HttpShestApi) {
      return (activeAdapter as HttpShestApi).getRoomPresence(roomName: roomName);
    }
    return const <Map<String, Object?>>[];
  }

  /// Permite simular caídas de red o errores del backend para validar Fase 34 y 35.
  bool get simulateOffline => activeAdapter.simulateOffline;
  set simulateOffline(bool value) => activeAdapter.simulateOffline = value;

  /// Verifica en vivo la conectividad con Supabase PostgREST o el Backend Java de Shest.
  Future<({bool ok, String message})> verifyRemoteConnection() async {
    switch (environment) {
      case ShestBackendEnvironment.mock:
        return (
          ok: true,
          message:
              'Simulador Mock Shest Labs activo en memoria (4 usuarios, reunión WV-45821 y Escrow #45821 listos).',
        );
      case ShestBackendEnvironment.supabaseStaging:
        return _supabaseAdapter.verifyRemoteConnection();
      case ShestBackendEnvironment.production:
        return _productionAdapter.verifyRemoteConnection();
    }
  }

  /// Mensajes de chat almacenados en la sesión o reunión (Fase 14).
  List<WordverseChatMessage> getChatMessages(String channelId) =>
      activeAdapter.getChatMessages(channelId);

  Future<WordverseChatMessage> sendChatMessage({
    required String senderId,
    required String senderName,
    required String channelId,
    required String text,
  }) =>
      activeAdapter.sendChatMessage(
        senderId: senderId,
        senderName: senderName,
        channelId: channelId,
        text: text,
      );

  /// Servicio centralizado de traducción asistida por IA (Fase 3 — WV-301 / WV-303).
  late final WordverseTranslationService translationService =
      WordverseTranslationService(
        eventBus: eventBus,
        remoteTranslator: ({
          required String text,
          required String targetLanguage,
          String? sourceLanguage,
        }) => activeAdapter.translateText(
          text: text,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        ),
      );

  /// Traduce texto entre idiomas soportados usando caché y adaptadores activos.
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final TranslationResult res = await translationService.translate(
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
    );
    return res.translatedText;
  }
}
