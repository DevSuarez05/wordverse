import '../../../core/models/shest_models.dart';

/// Estado espacial y visual de un Avatar dentro de la Sala 3D (Fases 5, 6, 7, 15, 16).
class AvatarRoomNode {
  const AvatarRoomNode({
    required this.user,
    required this.normX,
    required this.normZ,
    this.rotationRadians = 0.0,
    this.isMoving = false,
    this.activeEmote,
    this.isLocalPlayer = false,
  });

  final ShestUser user;

  /// Coordenada X normalizada en la sala [-0.85 .. 0.85].
  final double normX;

  /// Coordenada Z normalizada en la sala [-0.85 .. 0.85].
  final double normZ;

  /// Orientación en radianes en el plano XZ.
  final double rotationRadians;

  /// Indica si el avatar está caminando actualmente (animación de paso).
  final bool isMoving;

  /// Emote temporal sobre el avatar (👋, 👍, 🤝, ☕, 💬, 💰).
  final WordverseEmote? activeEmote;

  /// True si corresponde al jugador local controlado con el Joystick.
  final bool isLocalPlayer;

  AvatarRoomNode copyWith({
    ShestUser? user,
    double? normX,
    double? normZ,
    double? rotationRadians,
    bool? isMoving,
    WordverseEmote? activeEmote,
    bool clearEmote = false,
  }) {
    return AvatarRoomNode(
      user: user ?? this.user,
      normX: normX ?? this.normX,
      normZ: normZ ?? this.normZ,
      rotationRadians: rotationRadians ?? this.rotationRadians,
      isMoving: isMoving ?? this.isMoving,
      activeEmote: clearEmote ? null : (activeEmote ?? this.activeEmote),
      isLocalPlayer: isLocalPlayer,
    );
  }
}
