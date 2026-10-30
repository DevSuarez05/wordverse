import 'dart:async';

import '../config/wordverse_env_config.dart';

/// Nivel de severidad para logging y trazabilidad estructurada (Fase 1 — WV-103).
enum WordverseEventSeverity {
  info('INFO'),
  warning('WARN'),
  error('ERROR');

  const WordverseEventSeverity(this.code);
  final String code;
}

/// Catálogo oficial de eventos internos de WordVerse (Fase 32 + Fase 1).
enum WordverseEventType {
  userJoinedRoom('USER_JOINED_ROOM'),
  userLeftRoom('USER_LEFT_ROOM'),
  avatarMoved('AVATAR_MOVED'),
  avatarSelected('AVATAR_SELECTED'),
  createMeeting('CREATE_MEETING'),
  joinMeeting('JOIN_MEETING'),
  qrScanned('QR_SCANNED'),
  connectionRequest('CONNECTION_REQUEST'),
  connectionAccepted('CONNECTION_ACCEPTED'),
  chatOpened('CHAT_OPENED'),
  p2pOpened('P2P_OPENED'),
  escrowCreated('ESCROW_CREATED'),
  escrowUpdated('ESCROW_UPDATED'),
  escrowCompleted('ESCROW_COMPLETED'),
  paymentRequest('PAYMENT_REQUEST'),
  paymentCompleted('PAYMENT_COMPLETED'),
  translationExecuted('TRANSLATION_EXECUTED'),
  roomStateSynced('ROOM_STATE_SYNCED'),
  authSessionChanged('AUTH_SESSION_CHANGED'),
  apiError('API_ERROR');

  const WordverseEventType(this.code);
  final String code;
}

/// Evento emitido dentro del ecosistema WordVerse con correlación `traceId`.
class WordverseEvent {
  WordverseEvent({
    required this.type,
    required this.summary,
    this.payload = const <String, Object?>{},
    this.severity = WordverseEventSeverity.info,
    String? traceId,
    DateTime? timestamp,
  }) : traceId = traceId ?? WordverseEnvConfig.generateTraceId(),
       timestamp = timestamp ?? DateTime.now();

  final WordverseEventType type;
  final String summary;
  final Map<String, Object?> payload;
  final WordverseEventSeverity severity;
  final String traceId;
  final DateTime timestamp;
}

/// Bus reactivo de eventos internos, auditoría y trazabilidad de WordVerse (Fases 1, 31 y 32).
class WordverseEventBus {
  final StreamController<WordverseEvent> _controller =
      StreamController<WordverseEvent>.broadcast();

  final List<WordverseEvent> _history = <WordverseEvent>[];

  Stream<WordverseEvent> get stream => _controller.stream;

  List<WordverseEvent> get history => List<WordverseEvent>.unmodifiable(_history);

  List<WordverseEvent> filterBySeverity(WordverseEventSeverity severity) =>
      _history.where((WordverseEvent e) => e.severity == severity).toList();

  List<WordverseEvent> filterByType(WordverseEventType type) =>
      _history.where((WordverseEvent e) => e.type == type).toList();

  void emit(
    WordverseEventType type,
    String summary, [
    Map<String, Object?> payload = const <String, Object?>{},
    WordverseEventSeverity severity = WordverseEventSeverity.info,
    String? traceId,
  ]) {
    final WordverseEvent event = WordverseEvent(
      type: type,
      summary: summary,
      payload: payload,
      severity: severity,
      traceId: traceId,
    );
    _history.insert(0, event);
    if (_history.length > 100) {
      _history.removeLast();
    }
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}
