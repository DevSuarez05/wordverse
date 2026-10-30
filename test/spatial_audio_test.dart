import 'package:flutter_test/flutter_test.dart';
import 'package:wordverse/core/services/spatial_audio_service.dart';
import 'package:wordverse/features/wordverse/3d_room/hub3d/hub3d_protocol.dart';

void main() {
  group('WV-901: SpatialAudioService — Pruebas de Audio Espacial y Atenuación 3D', () {
    late SpatialAudioService service;

    setUp(() {
      service = SpatialAudioService(
        maxAudibleDistance: 10.0,
        referenceDistance: 1.5,
        rollOffFactor: 1.0,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('calculateDistance3D calcula correctamente la distancia euclidiana tridimensional', () {
      final double distance = SpatialAudioService.calculateDistance3D(
        0.0, 0.0, 0.0,
        3.0, 0.0, 4.0,
      );
      expect(distance, closeTo(5.0, 0.001));

      final double distance3D = SpatialAudioService.calculateDistance3D(
        1.0, 2.0, 3.0,
        4.0, 6.0, 3.0,
      ); // dx=3, dy=4, dz=0 -> 5.0
      expect(distance3D, closeTo(5.0, 0.001));
    });

    test('calculateVolume devuelve 1.0 en distancia de referencia y 0.0 fuera del radio de audibilidad', () {
      // Menor o igual a distancia de referencia (1.5m)
      expect(service.calculateVolume(0.5), equals(1.0));
      expect(service.calculateVolume(1.5), equals(1.0));

      // Fuera del radio máximo (>= 10.0m)
      expect(service.calculateVolume(10.0), equals(0.0));
      expect(service.calculateVolume(15.0), equals(0.0));

      // Punto medio (1.5 + (10 - 1.5) / 2 = 5.75m)
      final double midVolume = service.calculateVolume(5.75);
      expect(midVolume, closeTo(0.5, 0.05));
    });

    test('calculatePanning calcula balance estéreo respecto a la orientación del oyente', () {
      // Oyente en (0,0) mirando hacia +Z (yaw = 0)
      service.updateListener(
        userId: 'usr_local',
        x: 0.0,
        y: 0.0,
        z: 0.0,
        yaw: 0.0,
      );

      // Fuente directamente al frente (+Z) -> paneo centro (0.0)
      final double frontPan = service.calculatePanning(0.0, 5.0);
      expect(frontPan, closeTo(0.0, 0.05));

      // Fuente a la derecha (+X) -> paneo derecha (+1.0)
      final double rightPan = service.calculatePanning(5.0, 0.0);
      expect(rightPan, closeTo(1.0, 0.05));

      // Fuente a la izquierda (-X) -> paneo izquierda (-1.0)
      final double leftPan = service.calculatePanning(-5.0, 0.0);
      expect(leftPan, closeTo(-1.0, 0.05));
    });

    test('Control de micrófono local muta emisión de voz e impide transmitir', () {
      expect(service.isMicrophoneMuted, isFalse);

      service.setLocalSpeaking(true);
      expect(service.isLocalSpeaking, isTrue);

      // Mutear micrófono
      final bool muted = service.toggleMicrophone();
      expect(muted, isTrue);
      expect(service.isMicrophoneMuted, isTrue);
      expect(service.isLocalSpeaking, isFalse);

      // Intentar hablar mientras está muteado es ignorado
      service.setLocalSpeaking(true);
      expect(service.isLocalSpeaking, isFalse);

      // Desmutear
      service.setMicrophoneMuted(false);
      expect(service.isMicrophoneMuted, isFalse);
      service.setLocalSpeaking(true);
      expect(service.isLocalSpeaking, isTrue);
    });

    test('updateRemoteAvatar y activeAudibleSpeakers filtran avatares fuera del rango', () {
      service.updateListener(
        userId: 'usr_me',
        x: 0.0,
        y: 0.0,
        z: 0.0,
        yaw: 0.0,
      );

      // Avatar 1: cercano (3m) y hablando
      service.updateRemoteAvatar(
        userId: 'usr_cercano',
        x: 3.0,
        y: 0.0,
        z: 0.0,
        isSpeaking: true,
      );

      // Avatar 2: lejano (15m) y hablando
      service.updateRemoteAvatar(
        userId: 'usr_lejano',
        x: 15.0,
        y: 0.0,
        z: 0.0,
        isSpeaking: true,
      );

      final List<SpatialAudioNode> active = service.activeAudibleSpeakers;
      expect(active.length, equals(1));
      expect(active.first.userId, equals('usr_cercano'));
      expect(active.first.volume, greaterThan(0.0));

      final SpatialAudioNode? lejanoNode = service.getAudioNode('usr_lejano');
      expect(lejanoNode, isNotNull);
      expect(lejanoNode!.volume, equals(0.0));
      expect(lejanoNode.distance, closeTo(15.0, 0.01));
    });

    test('Stream onSpatialAudioUpdated emite cuando cambia posición o estado de voz', () async {
      service.updateListener(
        userId: 'usr_me',
        x: 0.0,
        y: 0.0,
        z: 0.0,
        yaw: 0.0,
      );

      expectLater(
        service.onSpatialAudioUpdated,
        emits(predicate<SpatialAudioNode>((SpatialAudioNode n) {
          return n.userId == 'usr_stream' && n.isSpeaking == true;
        })),
      );

      service.updateRemoteAvatar(
        userId: 'usr_stream',
        x: 2.0,
        y: 0.0,
        z: 2.0,
        isSpeaking: true,
      );
    });

    test('Hub3DProtocol serializa y deserializa speaking y userSpeaking correctamente', () {
      final Map<String, Object?> dto = Hub3DProtocol.speaking(
        userId: 'usr_alex',
        isSpeaking: true,
      );
      expect(dto['type'], equals('speaking'));
      expect(dto['userId'], equals('usr_alex'));
      expect(dto['isSpeaking'], isTrue);

      final Hub3DEvent? event = Hub3DEvent.parse(<String, Object?>{
        'source': Hub3DProtocol.fromScene,
        'type': 'userSpeaking',
        'userId': 'usr_alex',
        'isSpeaking': true,
      });

      expect(event, isA<Hub3DUserSpeaking>());
      final Hub3DUserSpeaking speakingEvent = event as Hub3DUserSpeaking;
      expect(speakingEvent.userId, equals('usr_alex'));
      expect(speakingEvent.isSpeaking, isTrue);
    });
  });
}
