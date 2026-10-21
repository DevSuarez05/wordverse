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

/// Modos de entorno soportados para integración con Shest Labs (Entregable #19).
enum ShestBackendEnvironment {
  /// Modo local/en memoria para desarrollo inmediato sin bloqueos.
  mock('Mock Shest Labs (Simulador Local)', 'mock://shest.local'),

  /// Modo de pruebas para 2 desarrolladores usando tablas en Supabase.
  supabaseStaging(
    'Supabase Staging (Dev 1 + Dev 2)',
    'https://your-project.supabase.co/rest/v1',
  ),

  /// API productiva en Java Spring Boot de Shest Labs.
  production('Shest Java Spring Boot API', 'https://api.shestlabs.com/v1');

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
    const String envSupabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://your-project.supabase.co/rest/v1',
    );
    const String envSupabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
    );
    const String envShestApiUrl = String.fromEnvironment(
      'SHEST_API_URL',
      defaultValue: 'https://api.shestlabs.com/v1',
    );
    const String envShestToken = String.fromEnvironment('SHEST_API_TOKEN');

    _supabaseAdapter = HttpShestApi(
      baseUrl: envSupabaseUrl,
      apiKeyOrToken: envSupabaseAnonKey,
      eventBus: eventBus,
      fallbackMock: _mockAdapter,
    );
    _productionAdapter = HttpShestApi(
      baseUrl: envShestApiUrl,
      apiKeyOrToken: envShestToken,
      eventBus: eventBus,
      fallbackMock: _mockAdapter,
    );
  }

  final WordverseEventBus eventBus;
  ShestBackendEnvironment environment;

  final MockShestApi _mockAdapter;
  late final HttpShestApi _supabaseAdapter;
  late final HttpShestApi _productionAdapter;

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

  /// Permite simular caídas de red o errores del backend para validar Fase 34 y 35.
  bool get simulateOffline => activeAdapter.simulateOffline;
  set simulateOffline(bool value) => activeAdapter.simulateOffline = value;

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
}
