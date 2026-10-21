import '../models/shest_models.dart';

/// Servicio de Escrow de Shest (Fases 0, 1, 19-24, 33).
/// Función central de negocios en WordVerse. Toda validación de saldo,
/// bloqueo de fondos y liberación ocurre exclusivamente en Shest Backend.
abstract class ShestEscrowService {
  /// Lista los escrows en los que participa el usuario.
  Future<List<EscrowOperation>> listEscrows(String userId);

  /// Crea un nuevo Escrow mediante la API de Shest (Fases 20 y 21).
  /// El primer escrow de demostración genera el ID #45821 en estado PENDING.
  Future<EscrowOperation> createEscrow({
    required String creatorId,
    required String counterpartyId,
    required double amount,
    String currency = 'USDT',
    required String description,
    required String conditions,
  });

  /// Ejecuta una acción sobre un Escrow según permisos del backend de Shest (Fase 23):
  /// FUNDED, IN_PROGRESS, RELEASE_REQUESTED, RELEASED, DISPUTED, CANCELLED, COMPLETED.
  Future<EscrowOperation> transitionEscrowState({
    required String escrowId,
    required String actorUserId,
    required EscrowStatus targetStatus,
  });
}
