import 'dart:async';

/// Catálogo oficial de eventos internos de WordVerse (Fase 32).
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
  paymentCompleted('PAYMENT_COMPLETED');

  const WordverseEventType(this.code);
  final String code;
}

/// Evento emitido dentro del ecosistema WordVerse.
class WordverseEvent {
  WordverseEvent({
    required this.type,
    required this.summary,
    this.payload = const <String, Object?>{},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final WordverseEventType type;
  final String summary;
  final Map<String, Object?> payload;
  final DateTime timestamp;
}

/// Bus reactivo de eventos internos y notificaciones de WordVerse (Fases 31 y 32).
class WordverseEventBus {
  final StreamController<WordverseEvent> _controller =
      StreamController<WordverseEvent>.broadcast();

  final List<WordverseEvent> _history = <WordverseEvent>[];

  Stream<WordverseEvent> get stream => _controller.stream;

  List<WordverseEvent> get history => List<WordverseEvent>.unmodifiable(_history);

  void emit(
    WordverseEventType type,
    String summary, [
    Map<String, Object?> payload = const <String, Object?>{},
  ]) {
    final WordverseEvent event = WordverseEvent(
      type: type,
      summary: summary,
      payload: payload,
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
