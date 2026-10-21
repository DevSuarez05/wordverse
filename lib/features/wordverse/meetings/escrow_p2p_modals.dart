import 'package:flutter/material.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/events/wordverse_events.dart';
import '../../../core/models/shest_models.dart';
import 'escrow_sheet.dart';
import 'networking_chat_sheet.dart';
import 'p2p_wallet_sheet.dart';
import 'profile_card_sheet.dart';

/// Coordinador de modales de Perfil 3D, Networking, Chat, P2P, Wallet, Pagos y Escrow (Fases 12-26, 29-30).
/// Cada vista está desacoplada en su propio archivo para permitir el trabajo en paralelo
/// entre Dev 1 (3D/UI) y Dev 2 (Integración Financiera Shest) sin conflictos de merge.
class EscrowAndProfileModals {
  /// Fase 12 y 17: Al tocar un avatar en la Sala 3D muestra su Tarjeta de Perfil 3D.
  static Future<void> showAvatarProfileSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
    required ShestUser targetUser,
    required ValueChanged<ShestUser> onUserUpdated,
  }) async {
    apiClient.eventBus.emit(
      WordverseEventType.avatarSelected,
      'Perfil 3D abierto: ${targetUser.name} (${targetUser.company})',
      <String, Object?>{'targetUserId': targetUser.id},
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return AvatarProfileCardSheet(
          apiClient: apiClient,
          currentUser: currentUser,
          initialTargetUser: targetUser,
          onUserUpdated: onUserUpdated,
        );
      },
    );
  }

  /// Fases 19-24: Abre el módulo central de ESCROW de WordVerse conectado a Shest API.
  static Future<void> showEscrowSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
    ShestUser? preselectedCounterparty,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return EscrowCenterSheet(
          apiClient: apiClient,
          currentUser: currentUser,
          preselectedCounterparty: preselectedCounterparty,
        );
      },
    );
  }

  /// Fases 18, 25, 26: Abre el panel de P2P, Wallet USDT TRC20 y Pagos validados por Shest.
  static Future<void> showP2PAndWalletSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
  }) async {
    apiClient.eventBus.emit(
      WordverseEventType.p2pOpened,
      'Módulo P2P / Wallet USDT TRC20 consultado vía Shest API',
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return P2PAndWalletSheet(
          apiClient: apiClient,
          currentUser: currentUser,
        );
      },
    );
  }

  /// Fases 13, 14, 29, 30: Abre el Hub de Networking, Búsqueda por Nombre/Empresa,
  /// Contactos Favoritos ⭐ y Chat de la sala.
  static Future<void> showNetworkingAndChatSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
    required ValueChanged<ShestUser> onUserUpdated,
    String initialChannelId = 'global_room',
  }) async {
    apiClient.eventBus.emit(
      WordverseEventType.chatOpened,
      'Hub de Networking & Chat abierto ($initialChannelId)',
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return NetworkingAndChatSheet(
          apiClient: apiClient,
          currentUser: currentUser,
          onUserUpdated: onUserUpdated,
          channelId: initialChannelId,
        );
      },
    );
  }
}
