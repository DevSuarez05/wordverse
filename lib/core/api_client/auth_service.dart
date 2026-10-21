import '../models/shest_models.dart';

/// Servicio de Autenticación y Usuarios de Shest (Fases 0, 1, 4, 16, 29, 30).
/// WordVerse reutiliza la sesión de Shest y consulta perfiles vía API.
abstract class ShestAuthService {
  /// Obtiene la sesión activa provista por la app anfitriona Shest Labs.
  Future<ShestAuthSession> loginWithShestSession({required String userId});

  /// Renueva el token de acceso en caso de expiración (Fase 34).
  Future<ShestAuthSession> refreshSession(String refreshToken);

  /// Consulta los usuarios visibles/registrados en Shest para Networking y Búsqueda (Fase 29).
  Future<List<ShestUser>> searchUsers({String query = ''});

  /// Actualiza el estado de presencia del usuario (Disponible, Ocupado, No disponible - Fase 16).
  Future<ShestUser> updateUserStatus({
    required String userId,
    required UserPresenceStatus status,
  });

  /// Alterna el estado de contacto favorito (⭐ Fase 30).
  Future<ShestUser> toggleFavorite({required String targetUserId});

  /// Envía o acepta una solicitud de conexión de Networking (Fase 13).
  Future<ShestUser> connectWithUser({required String targetUserId});
}
