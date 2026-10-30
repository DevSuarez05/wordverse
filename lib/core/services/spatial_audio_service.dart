import 'dart:async';
import 'dart:math' as math;

/// Representa el estado acústico espacial de un avatar en el espacio 3D.
class SpatialAudioNode {
  const SpatialAudioNode({
    required this.userId,
    required this.x,
    required this.y,
    required this.z,
    required this.isSpeaking,
    required this.volume,
    required this.panning,
    required this.distance,
  });

  final String userId;
  final double x;
  final double y;
  final double z;
  final bool isSpeaking;

  /// Volumen normalizado entre 0.0 (inaudible) y 1.0 (volumen máximo).
  final double volume;

  /// Paneo estéreo entre -1.0 (totalmente a la izquierda) y +1.0 (totalmente a la derecha).
  /// 0.0 representa el centro exacto.
  final double panning;

  /// Distancia euclidiana en metros respecto al usuario local (oyente).
  final double distance;

  SpatialAudioNode copyWith({
    String? userId,
    double? x,
    double? y,
    double? z,
    bool? isSpeaking,
    double? volume,
    double? panning,
    double? distance,
  }) {
    return SpatialAudioNode(
      userId: userId ?? this.userId,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      volume: volume ?? this.volume,
      panning: panning ?? this.panning,
      distance: distance ?? this.distance,
    );
  }
}

/// Servicio desacoplado para cálculo de audio espacial 3D y atenuación acústica.
///
/// Implementa modelo de caída cuadrática inversa / logarítmica suave con
/// corte de audibilidad y paneo estéreo basado en la orientación azimutal del oyente.
class SpatialAudioService {
  SpatialAudioService({
    this.maxAudibleDistance = 10.0,
    this.referenceDistance = 1.5,
    this.rollOffFactor = 1.0,
  });

  /// Distancia máxima en metros más allá de la cual el audio es completamente inaudible (volumen = 0.0).
  final double maxAudibleDistance;

  /// Distancia de referencia en metros dentro de la cual el volumen es pleno (1.0).
  final double referenceDistance;

  /// Factor de caída de atenuación sonora.
  final double rollOffFactor;

  // Estado del oyente (usuario local)
  String _listenerId = 'local';
  double _listenerX = 0.0;
  double _listenerY = 0.0;
  double _listenerZ = 0.0;
  double _listenerYaw = 0.0; // En radianes

  bool _isMicrophoneMuted = false;
  bool _isLocalSpeaking = false;

  final Map<String, SpatialAudioNode> _nodes = <String, SpatialAudioNode>{};
  final StreamController<SpatialAudioNode> _nodeUpdateController =
      StreamController<SpatialAudioNode>.broadcast();

  Stream<SpatialAudioNode> get onSpatialAudioUpdated =>
      _nodeUpdateController.stream;

  bool get isMicrophoneMuted => _isMicrophoneMuted;
  bool get isLocalSpeaking => _isLocalSpeaking && !_isMicrophoneMuted;
  String get listenerId => _listenerId;

  /// Alterna el estado del micrófono local (Mute / Un-mute).
  bool toggleMicrophone() {
    _isMicrophoneMuted = !_isMicrophoneMuted;
    if (_isMicrophoneMuted) {
      _isLocalSpeaking = false;
    }
    return _isMicrophoneMuted;
  }

  /// Establece el estado de micrófono local explícitamente.
  void setMicrophoneMuted(bool muted) {
    _isMicrophoneMuted = muted;
    if (muted) {
      _isLocalSpeaking = false;
    }
  }

  /// Actualiza si el usuario local está emitiendo voz.
  void setLocalSpeaking(bool speaking) {
    if (_isMicrophoneMuted) {
      _isLocalSpeaking = false;
      return;
    }
    _isLocalSpeaking = speaking;
  }

  /// Actualiza la posición y orientación del oyente local en el mundo 3D.
  void updateListener({
    required String userId,
    required double x,
    required double y,
    required double z,
    required double yaw,
  }) {
    _listenerId = userId;
    _listenerX = x;
    _listenerY = y;
    _listenerZ = z;
    _listenerYaw = yaw;

    // Recalcular todos los nodos remotos respecto a la nueva posición del oyente
    for (final String remoteId in _nodes.keys.toList()) {
      final SpatialAudioNode current = _nodes[remoteId]!;
      _recalculateAndNotify(current.userId, current.x, current.y, current.z, current.isSpeaking);
    }
  }

  /// Actualiza o registra la posición 3D de un avatar remoto.
  void updateRemoteAvatar({
    required String userId,
    required double x,
    required double y,
    required double z,
    bool? isSpeaking,
  }) {
    final bool speaking = isSpeaking ?? _nodes[userId]?.isSpeaking ?? false;
    _recalculateAndNotify(userId, x, y, z, speaking);
  }

  /// Cambia el estado de habla de un avatar remoto.
  void setRemoteSpeaking(String userId, bool speaking) {
    final SpatialAudioNode? current = _nodes[userId];
    if (current != null) {
      final SpatialAudioNode updated = current.copyWith(isSpeaking: speaking);
      _nodes[userId] = updated;
      _nodeUpdateController.add(updated);
    }
  }

  /// Elimina un avatar del registro cuando abandona la sala.
  void removeRemoteAvatar(String userId) {
    _nodes.remove(userId);
  }

  /// Retorna el nodo espacial de audio para un avatar dado.
  SpatialAudioNode? getAudioNode(String userId) => _nodes[userId];

  /// Lista de nodos que están actualmente emitiendo sonido dentro del rango audible.
  List<SpatialAudioNode> get activeAudibleSpeakers => _nodes.values
      .where((SpatialAudioNode node) => node.isSpeaking && node.volume > 0.0)
      .toList();

  /// Calcula la distancia euclidiana 3D entre dos puntos.
  static double calculateDistance3D(
    double x1, double y1, double z1,
    double x2, double y2, double z2,
  ) {
    final double dx = x2 - x1;
    final double dy = y2 - y1;
    final double dz = z2 - z1;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Calcula el volumen atenuado según la distancia euclidiana y el radio de corte.
  double calculateVolume(double distance) {
    if (distance >= maxAudibleDistance) {
      return 0.0;
    }
    if (distance <= referenceDistance) {
      return 1.0;
    }
    // Modelo de decaimiento suave inverso
    final double distanceRatio = (distance - referenceDistance) /
        (maxAudibleDistance - referenceDistance);
    final double attenuation = 1.0 - (distanceRatio * rollOffFactor);
    return attenuation.clamp(0.0, 1.0);
  }

  /// Calcula el paneo estéreo (-1.0 a +1.0) relativo al ángulo de visión (yaw) del oyente.
  double calculatePanning(double sourceX, double sourceZ) {
    final double dx = sourceX - _listenerX;
    final double dz = sourceZ - _listenerZ;

    // Si están prácticamente en el mismo punto, el paneo es neutral al centro
    if (dx.abs() < 0.001 && dz.abs() < 0.001) {
      return 0.0;
    }

    // Ángulo absoluto en el plano horizontal (X-Z)
    final double angleToSource = math.atan2(dx, dz);

    // Ángulo relativo respecto al yaw del oyente
    double relativeAngle = angleToSource - _listenerYaw;

    // Normalizar a [-pi, pi]
    while (relativeAngle > math.pi) {
      relativeAngle -= 2 * math.pi;
    }
    while (relativeAngle < -math.pi) {
      relativeAngle += 2 * math.pi;
    }

    // El paneo es proporcional al seno del ángulo relativo
    final double pan = math.sin(relativeAngle);
    return pan.clamp(-1.0, 1.0);
  }

  void _recalculateAndNotify(
    String userId,
    double x,
    double y,
    double z,
    bool speaking,
  ) {
    final double distance = calculateDistance3D(
      _listenerX, _listenerY, _listenerZ,
      x, y, z,
    );
    final double volume = calculateVolume(distance);
    final double panning = calculatePanning(x, z);

    final SpatialAudioNode node = SpatialAudioNode(
      userId: userId,
      x: x,
      y: y,
      z: z,
      isSpeaking: speaking,
      volume: volume,
      panning: panning,
      distance: distance,
    );

    _nodes[userId] = node;
    _nodeUpdateController.add(node);
  }

  void dispose() {
    _nodeUpdateController.close();
  }
}
