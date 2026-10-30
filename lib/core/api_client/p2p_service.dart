import '../models/shest_models.dart';

/// Servicio P2P de Shest (Fases 0, 1, 18 y Fase 4 — WV-401..WV-403).
/// NO duplica el motor P2P de Shest; consume sus endpoints para listar,
/// crear, aceptar o cancelar órdenes P2P USDT TRC20 con controles de seguridad.
abstract class ShestP2PService {
  /// Lista las órdenes P2P activas en Shest con filtros opcionales.
  Future<List<P2POperation>> listOperations({
    P2POperationType? typeFilter,
    String? paymentMethodFilter,
    String? query,
  });

  /// Crea una nueva orden P2P en el backend de Shest.
  Future<P2POperation> createOperation({
    required String makerId,
    required double amountUsdt,
    required double rateUsd,
    required String paymentMethod,
    P2POperationType type = P2POperationType.sell,
    double? minAmountUsdt,
    double? maxAmountUsdt,
    String? notes,
  });

  /// Acepta una orden P2P existente (validado por Shest).
  Future<P2POperation> acceptOperation({
    required String operationId,
    required String takerId,
  });

  /// Cancela una orden P2P existente (solo si está OPEN y es solicitada por el maker).
  Future<P2POperation> cancelOperation(String operationId);
}
