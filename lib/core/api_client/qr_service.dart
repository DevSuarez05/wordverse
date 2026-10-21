import '../models/shest_models.dart';

/// Servicio de Reuniones y validación QR de Shest (Fases 0, 1, 9-11, 24, 28).
abstract class ShestQrService {
  /// Crea una reunión en el backend y genera su código oficial (ej. WV-45821) y QR (Fase 9 y 10).
  Future<WordverseMeeting> createMeeting({
    required String creatorId,
    required String name,
    required MeetingType type,
    required String description,
    required bool isPrivate,
    int durationMinutes = 45,
  });

  /// Lista las reuniones activas en la sala.
  Future<List<WordverseMeeting>> listMeetings();

  /// Valida un código QR o código de invitación (Reunión WV-XXXXX, Escrow o Usuario)
  /// contra Shest API verificando permisos (Fases 11, 24, 28).
  Future<Map<String, Object?>> validateAndResolveQr({
    required String qrOrCode,
    required String scannerUserId,
  });
}
