import '../api_client/shest_backend_adapter.dart';
import '../events/wordverse_events.dart';
import '../models/shest_models.dart';

/// Implementación Mock completa del backend Java Spring Boot de Shest Labs.
/// Simula las tablas `users`, `wallets`, `meetings` y `escrows` (con el ID #45821
/// y reunión WV-45821 requeridos en el documento maestro).
class MockShestApi implements ShestBackendAdapter {
  MockShestApi({required this.eventBus}) {
    _seedInitialData();
  }

  final WordverseEventBus eventBus;
  @override
  bool simulateOffline = false;
  int _nextEscrowSeq = 45821;
  int _nextMeetingSeq = 45821;

  final Map<String, ShestUser> _users = <String, ShestUser>{};
  final Map<String, double> _walletBalances = <String, double>{};
  final Map<String, List<String>> _walletTxLogs = <String, List<String>>{};
  final List<EscrowOperation> _escrows = <EscrowOperation>[];
  final List<WordverseMeeting> _meetings = <WordverseMeeting>[];
  final List<P2POperation> _p2pOps = <P2POperation>[];
  final List<PaymentRecord> _payments = <PaymentRecord>[];
  final List<WordverseChatMessage> _chatMessages = <WordverseChatMessage>[];

  void _ensureOnline() {
    if (simulateOffline) {
      throw const ShestApiException(
        code: 'NETWORK_OFFLINE',
        userMessage:
            'Sin conexión con Shest API. Verifica tu red o usa Reconectar.',
      );
    }
  }

  void _seedInitialData() {
    _users['usr_1'] = const ShestUser(
      id: 'usr_1',
      name: 'Daniel (Tú)',
      company: 'Shest Labs Partner',
      role: 'Director de Negocios',
      description: 'Cerrando acuerdos B2B con Escrow USDT TRC20 en WordVerse.',
      avatarInitials: 'DN',
      avatarHexColor: 0xFF00E5FF,
      status: UserPresenceStatus.available,
    );
    _users['usr_2'] = const ShestUser(
      id: 'usr_2',
      name: 'Valeria Méndez',
      company: 'Andes FinTech Latam',
      role: 'Head of OTC & Liquidity',
      description: 'Liquidez corporativa USDT/USD y alianzas estratégicas.',
      avatarInitials: 'VM',
      avatarHexColor: 0xFF7C4DFF,
      status: UserPresenceStatus.available,
      isFavorite: true,
      isConnected: true,
    );
    _users['usr_3'] = const ShestUser(
      id: 'usr_3',
      name: 'Carlos Mendoza',
      company: 'BlockBean Trade',
      role: 'Importador Internacional',
      description: 'Contratos comerciales con garantía Escrow en tiempo real.',
      avatarInitials: 'CM',
      avatarHexColor: 0xFF00E676,
      status: UserPresenceStatus.busy,
    );
    _users['usr_4'] = const ShestUser(
      id: 'usr_4',
      name: 'Sofía Herrera',
      company: 'Global Ventures Capital',
      role: 'Managing Partner',
      description: 'Inversión semilla Web3 y rondas privadas en Latinoamérica.',
      avatarInitials: 'SH',
      avatarHexColor: 0xFFFFAB00,
      status: UserPresenceStatus.available,
    );

    _walletBalances['usr_1'] = 12500.00;
    _walletBalances['usr_2'] = 48000.00;
    _walletBalances['usr_3'] = 19200.00;
    _walletBalances['usr_4'] = 85000.00;

    _walletTxLogs['usr_1'] = <String>[
      'Depósito confirmado +5,000.00 USDT (TRC20)',
      'Liberación Escrow #45810 +7,500.00 USDT',
    ];

    _meetings.add(
      const WordverseMeeting(
        id: 'mtg_1',
        code: 'WV-45821',
        name: 'Mesa de Negocios OTC Latam',
        type: MeetingType.negocios,
        description: 'Reunión principal para acuerdos comerciales con Escrow.',
        isPrivate: false,
        creatorId: 'usr_2',
        creatorName: 'Valeria Méndez',
        durationMinutes: 60,
        participantIds: <String>['usr_1', 'usr_2', 'usr_3'],
      ),
    );
    _nextMeetingSeq = 45822;

    _p2pOps.addAll(const <P2POperation>[
      P2POperation(
        id: 'P2P-901',
        makerId: 'usr_2',
        makerName: 'Valeria Méndez (Andes FinTech)',
        amountUsdt: 2500.0,
        rateUsd: 1.001,
        paymentMethod: 'Transferencia Bancaria / Wire',
        status: 'OPEN',
      ),
      P2POperation(
        id: 'P2P-902',
        makerId: 'usr_3',
        makerName: 'Carlos Mendoza (BlockBean)',
        amountUsdt: 800.0,
        rateUsd: 0.999,
        paymentMethod: 'Liquidación Inmediata Shest',
        status: 'OPEN',
      ),
    ]);

    _chatMessages.addAll(<WordverseChatMessage>[
      WordverseChatMessage(
        id: 'msg_1',
        senderId: 'usr_2',
        senderName: 'Valeria Méndez',
        channelId: 'global_room',
        text: '¡Bienvenido a la Sala 3D de WordVerse! Toca mi avatar para abrir un Escrow.',
        sentAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      WordverseChatMessage(
        id: 'msg_2',
        senderId: 'usr_3',
        senderName: 'Carlos Mendoza',
        channelId: 'global_room',
        text: 'Reunión WV-45821 activa en la zona central de negocios.',
        sentAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ]);
  }

  // ===========================================================================
  // AUTH & USERS (Fases 4, 13, 16, 29, 30)
  // ===========================================================================

  @override
  Future<ShestAuthSession> loginWithShestSession({required String userId}) async {
    _ensureOnline();
    final ShestUser user = _users[userId] ?? _users['usr_1']!;
    return ShestAuthSession(
      accessToken: 'shest_jwt_token_${user.id}',
      refreshToken: 'shest_refresh_${user.id}',
      user: user,
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
  }

  @override
  Future<ShestAuthSession> refreshSession(String refreshToken) async {
    _ensureOnline();
    return loginWithShestSession(userId: 'usr_1');
  }

  @override
  Future<List<ShestUser>> searchUsers({String query = ''}) async {
    _ensureOnline();
    final String q = query.trim().toLowerCase();
    return _users.values.where((ShestUser u) {
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.company.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<ShestUser> updateUserStatus({
    required String userId,
    required UserPresenceStatus status,
  }) async {
    _ensureOnline();
    final ShestUser? current = _users[userId];
    if (current == null) {
      throw const ShestApiException(
        code: 'USER_NOT_FOUND',
        userMessage: 'Usuario no encontrado en Shest.',
      );
    }
    final ShestUser updated = current.copyWith(status: status);
    _users[userId] = updated;
    return updated;
  }

  @override
  Future<ShestUser> toggleFavorite({required String targetUserId}) async {
    _ensureOnline();
    final ShestUser? target = _users[targetUserId];
    if (target == null) {
      throw const ShestApiException(
        code: 'USER_NOT_FOUND',
        userMessage: 'Contacto no encontrado.',
      );
    }
    final ShestUser updated = target.copyWith(isFavorite: !target.isFavorite);
    _users[targetUserId] = updated;
    return updated;
  }

  @override
  Future<ShestUser> connectWithUser({required String targetUserId}) async {
    _ensureOnline();
    final ShestUser? target = _users[targetUserId];
    if (target == null) {
      throw const ShestApiException(
        code: 'USER_NOT_FOUND',
        userMessage: 'Usuario destino no existe en Shest.',
      );
    }
    eventBus.emit(
      WordverseEventType.connectionRequest,
      'Solicitud de conexión enviada a ${target.name}',
      <String, Object?>{'targetUserId': targetUserId},
    );
    final ShestUser updated = target.copyWith(isConnected: true);
    _users[targetUserId] = updated;
    eventBus.emit(
      WordverseEventType.connectionAccepted,
      'Conexión establecida con ${target.name} (${target.company})',
      <String, Object?>{'targetUserId': targetUserId},
    );
    return updated;
  }

  // ===========================================================================
  // WALLET & PAGOS (Fases 25, 26, 33)
  // ===========================================================================

  @override
  Future<WalletInfo> getWalletInfo(String userId) async {
    _ensureOnline();
    return WalletInfo(
      userId: userId,
      usdtBalance: _walletBalances[userId] ?? 0.0,
      trc20Address: 'TShestWordVerse9xK2L8mQvP4r7Wz89TRC20',
      recentTransactions: List<String>.unmodifiable(
        _walletTxLogs[userId] ?? const <String>[],
      ),
    );
  }

  @override
  Future<PaymentRecord> createPayment({
    required String fromUserId,
    required String toUserId,
    required double amountUsdt,
    required String concept,
  }) async {
    _ensureOnline();
    eventBus.emit(
      WordverseEventType.paymentRequest,
      'Validando pago de $amountUsdt USDT en Shest Backend...',
    );

    if (amountUsdt <= 0) {
      throw const ShestApiException(
        code: 'INVALID_AMOUNT',
        userMessage: 'El monto debe ser mayor a 0 USDT.',
      );
    }
    final double currentBalance = _walletBalances[fromUserId] ?? 0.0;
    if (currentBalance < amountUsdt) {
      throw const ShestApiException(
        code: 'INSUFFICIENT_FUNDS',
        userMessage:
            'Shest Backend rechazó el pago: Saldo insuficiente en Wallet USDT TRC20.',
      );
    }

    final ShestUser? recipient = _users[toUserId];
    if (recipient == null) {
      throw const ShestApiException(
        code: 'RECIPIENT_NOT_FOUND',
        userMessage: 'Destinatario inválido en Shest.',
      );
    }

    _walletBalances[fromUserId] = currentBalance - amountUsdt;
    _walletBalances[toUserId] = (_walletBalances[toUserId] ?? 0.0) + amountUsdt;

    final String logEntry =
        'Pago enviado -${amountUsdt.toStringAsFixed(2)} USDT a ${recipient.name} ($concept)';
    _walletTxLogs.putIfAbsent(fromUserId, () => <String>[]).insert(0, logEntry);

    final PaymentRecord record = PaymentRecord(
      id: 'PAY-${1000 + _payments.length + 1}',
      fromUserId: fromUserId,
      toUserId: toUserId,
      toUserName: recipient.name,
      amountUsdt: amountUsdt,
      concept: concept,
      status: 'CONFIRMED',
      timestamp: DateTime.now(),
    );
    _payments.insert(0, record);

    eventBus.emit(
      WordverseEventType.paymentCompleted,
      'Pago ${record.id} confirmado por Shest: ${amountUsdt.toStringAsFixed(2)} USDT a ${recipient.name}',
    );
    return record;
  }

  @override
  Future<List<PaymentRecord>> getPaymentHistory(String userId) async {
    _ensureOnline();
    return List<PaymentRecord>.unmodifiable(_payments);
  }

  // ===========================================================================
  // P2P (Fase 18)
  // ===========================================================================

  @override
  Future<List<P2POperation>> listOperations() async {
    _ensureOnline();
    return List<P2POperation>.unmodifiable(_p2pOps);
  }

  @override
  Future<P2POperation> createOperation({
    required String makerId,
    required double amountUsdt,
    required double rateUsd,
    required String paymentMethod,
  }) async {
    _ensureOnline();
    final ShestUser maker = _users[makerId] ?? _users['usr_1']!;
    final P2POperation op = P2POperation(
      id: 'P2P-${900 + _p2pOps.length + 1}',
      makerId: maker.id,
      makerName: '${maker.name} (${maker.company})',
      amountUsdt: amountUsdt,
      rateUsd: rateUsd,
      paymentMethod: paymentMethod,
      status: 'OPEN',
    );
    _p2pOps.insert(0, op);
    return op;
  }

  @override
  Future<P2POperation> acceptOperation({
    required String operationId,
    required String takerId,
  }) async {
    _ensureOnline();
    final int idx = _p2pOps.indexWhere((P2POperation o) => o.id == operationId);
    if (idx == -1) {
      throw const ShestApiException(
        code: 'P2P_NOT_FOUND',
        userMessage: 'La operación P2P no existe.',
      );
    }
    final P2POperation current = _p2pOps[idx];
    final P2POperation updated = P2POperation(
      id: current.id,
      makerId: current.makerId,
      makerName: current.makerName,
      amountUsdt: current.amountUsdt,
      rateUsd: current.rateUsd,
      paymentMethod: current.paymentMethod,
      status: 'COMPLETED',
    );
    _p2pOps[idx] = updated;
    return updated;
  }

  @override
  Future<P2POperation> cancelOperation(String operationId) async {
    _ensureOnline();
    final int idx = _p2pOps.indexWhere((P2POperation o) => o.id == operationId);
    if (idx == -1) {
      throw const ShestApiException(
        code: 'P2P_NOT_FOUND',
        userMessage: 'La operación P2P no existe.',
      );
    }
    final P2POperation current = _p2pOps[idx];
    final P2POperation updated = P2POperation(
      id: current.id,
      makerId: current.makerId,
      makerName: current.makerName,
      amountUsdt: current.amountUsdt,
      rateUsd: current.rateUsd,
      paymentMethod: current.paymentMethod,
      status: 'CANCELLED',
    );
    _p2pOps[idx] = updated;
    return updated;
  }

  // ===========================================================================
  // ESCROW (Fases 19-24, 33)
  // ===========================================================================

  @override
  Future<List<EscrowOperation>> listEscrows(String userId) async {
    _ensureOnline();
    return List<EscrowOperation>.unmodifiable(_escrows);
  }

  @override
  Future<EscrowOperation> createEscrow({
    required String creatorId,
    required String counterpartyId,
    required double amount,
    String currency = 'USDT',
    required String description,
    required String conditions,
  }) async {
    _ensureOnline();
    if (amount <= 0) {
      throw const ShestApiException(
        code: 'ESCROW_INVALID_AMOUNT',
        userMessage: 'El monto del Escrow debe ser mayor a 0 USDT.',
      );
    }
    final ShestUser creator = _users[creatorId] ?? _users['usr_1']!;
    final ShestUser? counterparty = _users[counterpartyId];
    if (counterparty == null) {
      throw const ShestApiException(
        code: 'COUNTERPARTY_NOT_FOUND',
        userMessage: 'La contraparte seleccionada no existe en Shest.',
      );
    }

    final String escrowId = '${_nextEscrowSeq++}';
    final EscrowOperation escrow = EscrowOperation(
      id: escrowId,
      creatorId: creator.id,
      creatorName: creator.name,
      counterpartyId: counterparty.id,
      counterpartyName: counterparty.name,
      amount: amount,
      currency: currency,
      description: description,
      conditions: conditions,
      status: EscrowStatus.pending,
      createdAt: DateTime.now(),
      historyLog: <String>[
        'ESCROW #$escrowId creado por ${creator.name} con ${counterparty.name} (Estado: PENDING)',
      ],
    );
    _escrows.insert(0, escrow);

    eventBus.emit(
      WordverseEventType.escrowCreated,
      'ESCROW #$escrowId PENDIENTE (${amount.toStringAsFixed(2)} $currency) con ${counterparty.name}',
      <String, Object?>{'escrowId': escrowId, 'status': escrow.status.apiValue},
    );

    return escrow;
  }

  @override
  Future<EscrowOperation> transitionEscrowState({
    required String escrowId,
    required String actorUserId,
    required EscrowStatus targetStatus,
  }) async {
    _ensureOnline();
    final int index =
        _escrows.indexWhere((EscrowOperation e) => e.id == escrowId);
    if (index == -1) {
      throw const ShestApiException(
        code: 'ESCROW_NOT_FOUND',
        userMessage: 'El Escrow solicitado no existe en Shest.',
      );
    }

    final EscrowOperation current = _escrows[index];

    // Validación financiera en el "Cerebro Shest" al fondear (Fase 33)
    if (targetStatus == EscrowStatus.funded &&
        current.status == EscrowStatus.pending) {
      final double creatorBalance = _walletBalances[current.creatorId] ?? 0.0;
      if (creatorBalance < current.amount) {
        throw ShestApiException(
          code: 'ESCROW_INSUFFICIENT_FUNDS',
          userMessage:
              'Shest Backend: Saldo USDT insuficiente para fondear el Escrow #${current.id}.',
        );
      }
      _walletBalances[current.creatorId] = creatorBalance - current.amount;
      _walletTxLogs
          .putIfAbsent(current.creatorId, () => <String>[])
          .insert(
            0,
            'Fondeo bloqueado en ESCROW #${current.id}: -${current.amount.toStringAsFixed(2)} USDT',
          );
    }

    // Si se libera o completa, Shest acredita a la contraparte
    if ((targetStatus == EscrowStatus.released ||
            targetStatus == EscrowStatus.completed) &&
        current.status != EscrowStatus.released &&
        current.status != EscrowStatus.completed) {
      _walletBalances[current.counterpartyId] =
          (_walletBalances[current.counterpartyId] ?? 0.0) + current.amount;
      _walletTxLogs
          .putIfAbsent(current.counterpartyId, () => <String>[])
          .insert(
            0,
            'Escrow #${current.id} liberado: +${current.amount.toStringAsFixed(2)} USDT',
          );
    }

    final List<String> updatedHistory = List<String>.from(current.historyLog)
      ..add(
        'Estado actualizado por Shest API → ${targetStatus.apiValue} (${targetStatus.displayLabel})',
      );

    final EscrowOperation updated = current.copyWith(
      status: targetStatus,
      historyLog: updatedHistory,
    );
    _escrows[index] = updated;

    if (targetStatus == EscrowStatus.released ||
        targetStatus == EscrowStatus.completed) {
      eventBus.emit(
        WordverseEventType.escrowCompleted,
        'ESCROW #$escrowId ${targetStatus.displayLabel} por Shest Backend',
        <String, Object?>{'escrowId': escrowId, 'status': targetStatus.apiValue},
      );
    } else {
      eventBus.emit(
        WordverseEventType.escrowUpdated,
        'ESCROW #$escrowId cambió a ${targetStatus.apiValue}',
        <String, Object?>{'escrowId': escrowId, 'status': targetStatus.apiValue},
      );
    }

    return updated;
  }

  // ===========================================================================
  // REUNIONES & QR (Fases 9-11, 24, 28)
  // ===========================================================================

  @override
  Future<WordverseMeeting> createMeeting({
    required String creatorId,
    required String name,
    required MeetingType type,
    required String description,
    required bool isPrivate,
    int durationMinutes = 45,
  }) async {
    _ensureOnline();
    final ShestUser creator = _users[creatorId] ?? _users['usr_1']!;
    final String code = 'WV-${_nextMeetingSeq++}';
    final WordverseMeeting meeting = WordverseMeeting(
      id: 'mtg_${_meetings.length + 1}',
      code: code,
      name: name,
      type: type,
      description: description,
      isPrivate: isPrivate,
      creatorId: creator.id,
      creatorName: creator.name,
      durationMinutes: durationMinutes,
      participantIds: <String>[creator.id],
    );
    _meetings.insert(0, meeting);

    eventBus.emit(
      WordverseEventType.createMeeting,
      'Reunión $code ($name) creada con QR válido en Shest',
      <String, Object?>{'meetingCode': code, 'type': type.label},
    );
    return meeting;
  }

  @override
  Future<List<WordverseMeeting>> listMeetings() async {
    _ensureOnline();
    return List<WordverseMeeting>.unmodifiable(_meetings);
  }

  @override
  Future<Map<String, Object?>> validateAndResolveQr({
    required String qrOrCode,
    required String scannerUserId,
  }) async {
    _ensureOnline();
    final String trimmed = qrOrCode.trim();
    if (trimmed.isEmpty) {
      throw const ShestApiException(
        code: 'QR_INVALID',
        userMessage: 'El código QR o código de reunión está vacío.',
      );
    }

    eventBus.emit(
      WordverseEventType.qrScanned,
      'QR escaneado: $trimmed — Validando con Shest API...',
    );

    // 1. Código directo de reunión tipo WV-45821 o SHEST-MEETING:WV-45821:...
    for (final WordverseMeeting meeting in _meetings) {
      if (trimmed.toUpperCase() == meeting.code.toUpperCase() ||
          trimmed.contains(meeting.code)) {
        eventBus.emit(
          WordverseEventType.joinMeeting,
          'Acceso autorizado por Shest a la reunión ${meeting.code} (${meeting.name})',
        );
        return <String, Object?>{
          'kind': 'MEETING',
          'meeting': meeting,
          'message': 'Entrada autorizada a reunión ${meeting.code}: ${meeting.name}',
        };
      }
    }

    // 2. QR de Escrow tipo SHEST-ESCROW:45821:... o #45821
    for (final EscrowOperation escrow in _escrows) {
      if (trimmed == escrow.id ||
          trimmed == '#${escrow.id}' ||
          trimmed.contains('SHEST-ESCROW:${escrow.id}')) {
        return <String, Object?>{
          'kind': 'ESCROW',
          'escrow': escrow,
          'message':
              'Escrow #${escrow.id} validado (${escrow.amount.toStringAsFixed(2)} ${escrow.currency} - ${escrow.status.apiValue})',
        };
      }
    }

    // 3. QR Personal de Usuario tipo SHEST-USER:usr_2:...
    for (final ShestUser user in _users.values) {
      if (trimmed.contains(user.id)) {
        return <String, Object?>{
          'kind': 'USER',
          'user': user,
          'message': 'Tarjeta digital validada: ${user.name} (${user.company})',
        };
      }
    }

    throw const ShestApiException(
      code: 'QR_NOT_FOUND',
      userMessage:
          'Shest API: El código QR o reunión no existe o no tienes permisos.',
    );
  }

  // ===========================================================================
  // CHAT (Fase 14)
  // ===========================================================================

  @override
  List<WordverseChatMessage> getChatMessages(String channelId) {
    return _chatMessages
        .where((WordverseChatMessage m) => m.channelId == channelId)
        .toList();
  }

  @override
  Future<WordverseChatMessage> sendChatMessage({
    required String senderId,
    required String senderName,
    required String channelId,
    required String text,
  }) async {
    _ensureOnline();
    final WordverseChatMessage msg = WordverseChatMessage(
      id: 'msg_${_chatMessages.length + 1}',
      senderId: senderId,
      senderName: senderName,
      channelId: channelId,
      text: text,
      sentAt: DateTime.now(),
    );
    _chatMessages.add(msg);
    return msg;
  }
}
