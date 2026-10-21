import '../models/shest_models.dart';

/// Servicio de Wallet y Pagos de Shest (Fases 0, 1, 25, 26, 33).
/// Regla de Oro: WordVerse NO tiene wallet propia ni decide si existen fondos.
/// Toda consulta y pago es validado por el backend de Shest.
abstract class ShestWalletService {
  /// Consulta balance USDT TRC20, dirección y últimos movimientos en Shest (Fase 25).
  Future<WalletInfo> getWalletInfo(String userId);

  /// Solicita a Shest procesar un pago directo entre usuarios (Fase 26).
  Future<PaymentRecord> createPayment({
    required String fromUserId,
    required String toUserId,
    required double amountUsdt,
    required String concept,
  });

  /// Obtiene el historial de pagos procesados por Shest.
  Future<List<PaymentRecord>> getPaymentHistory(String userId);
}
