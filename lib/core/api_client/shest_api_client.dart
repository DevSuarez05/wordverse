import '../events/wordverse_events.dart';
import '../mocks/mock_shest_api.dart';
import '../models/shest_models.dart';
import 'auth_service.dart';
import 'escrow_service.dart';
import 'p2p_service.dart';
import 'qr_service.dart';
import 'wallet_service.dart';

/// Modos de entorno soportados para integración con Shest Labs (Entregable #19).
enum ShestBackendEnvironment {
  /// Modo local/en memoria para desarrollo inmediato sin bloqueos.
  mock('Mock Shest Labs (Simulador Local)', 'mock://shest.local'),

  /// Modo de pruebas para 2 desarrolladores usando tablas en Supabase.
  supabaseStaging('Supabase Staging (Dev 1 + Dev 2)', 'https://your-project.supabase.co'),

  /// API productiva en Java Spring Boot de Shest Labs.
  production('Shest Java Spring Boot API', 'https://api.shestlabs.com/v1');

  const ShestBackendEnvironment(this.label, this.baseUrl);
  final String label;
  final String baseUrl;
}

/// Punto único de comunicación entre WordVerse y Shest Labs (Fase 1).
///
/// Cuando Shest Labs entregue acceso al backend Java Spring Boot,
/// únicamente se cambia el adaptador aquí sin tocar ni una sola línea de la Sala 3D.
class ShestApiClient {
  ShestApiClient({
    required this.eventBus,
    this.environment = ShestBackendEnvironment.mock,
  }) : _backend = MockShestApi(eventBus: eventBus);

  final WordverseEventBus eventBus;
  ShestBackendEnvironment environment;
  final MockShestApi _backend;

  ShestAuthService get auth => _backend;
  ShestWalletService get wallet => _backend;
  ShestP2PService get p2p => _backend;
  ShestEscrowService get escrow => _backend;
  ShestQrService get qr => _backend;

  /// Permite simular caídas de red o errores del backend para validar Fase 34 y 35.
  bool get simulateOffline => _backend.simulateOffline;
  set simulateOffline(bool value) => _backend.simulateOffline = value;

  /// Mensajes de chat almacenados en la sesión o reunión (Fase 14).
  List<WordverseChatMessage> getChatMessages(String channelId) =>
      _backend.getChatMessages(channelId);

  Future<WordverseChatMessage> sendChatMessage({
    required String senderId,
    required String senderName,
    required String channelId,
    required String text,
  }) =>
      _backend.sendChatMessage(
        senderId: senderId,
        senderName: senderName,
        channelId: channelId,
        text: text,
      );
}
