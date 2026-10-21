import '../models/shest_models.dart';
import 'auth_service.dart';
import 'escrow_service.dart';
import 'p2p_service.dart';
import 'qr_service.dart';
import 'wallet_service.dart';

/// Contrato unificado para cualquier adaptador de backend de Shest Labs:
/// - `MockShestApi` (Desarrollo local / Pruebas automatizadas)
/// - `HttpShestApi` (Supabase Staging REST o Shest Java Spring Boot API)
abstract class ShestBackendAdapter
    implements
        ShestAuthService,
        ShestWalletService,
        ShestP2PService,
        ShestEscrowService,
        ShestQrService {
  bool get simulateOffline;
  set simulateOffline(bool value);

  List<WordverseChatMessage> getChatMessages(String channelId);

  Future<WordverseChatMessage> sendChatMessage({
    required String senderId,
    required String senderName,
    required String channelId,
    required String text,
  });
}
