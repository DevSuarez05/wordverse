import '../models/shest_models.dart';

/// Servicio P2P de Shest (Fases 0, 1, 18).
/// NO duplica el motor P2P de Shest; consume sus endpoints para listar,
/// crear, aceptar o cancelar órdenes P2P USDT TRC20.
abstract class ShestP2PService {
  /// Lista las órdenes P2P activas en Shest.
  Future<List<P2POperation>> listOperations();

  /// Crea una nueva orden P2P en el backend de Shest.
  Future<P2POperation> createOperation({
    required String makerId,
    required double amountUsdt,
    required double rateUsd,
    required String paymentMethod,
  });

  /// Acepta una orden P2P existente (validado por Shest).
  Future<P2POperation> acceptOperation({
    required String operationId,
    required String takerId,
  });

  /// Cancela una orden P2P existente.
  Future<P2POperation> cancelOperation(String operationId);
}
