import '../api_client/shest_backend_adapter.dart';
import '../events/wordverse_events.dart';
import '../models/shest_models.dart';
import '../services/wordverse_translation_service.dart';

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
        type: P2POperationType.sell,
        minAmountUsdt: 100.0,
        maxAmountUsdt: 2500.0,
        reputationScore: 99.8,
        completedTradesCount: 142,
      ),
      P2POperation(
        id: 'P2P-902',
        makerId: 'usr_3',
        makerName: 'Carlos Mendoza (BlockBean)',
        amountUsdt: 800.0,
        rateUsd: 0.999,
        paymentMethod: 'Liquidación Inmediata Shest',
        status: 'OPEN',
        type: P2POperationType.buy,
        minAmountUsdt: 50.0,
        maxAmountUsdt: 800.0,
        reputationScore: 99.4,
        completedTradesCount: 88,
      ),
      P2POperation(
        id: 'P2P-903',
        makerId: 'usr_4',
        makerName: 'Elena Rostova (Global Escrow)',
        amountUsdt: 5000.0,
        rateUsd: 1.002,
        paymentMethod: 'Zelle / ACH',
        status: 'OPEN',
        type: P2POperationType.sell,
        minAmountUsdt: 250.0,
        maxAmountUsdt: 5000.0,
        reputationScore: 100.0,
        completedTradesCount: 215,
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
    if (refreshToken.isEmpty || !refreshToken.startsWith('refresh_')) {
      throw const ShestApiException(
        code: 'INVALID_REFRESH_TOKEN',
        userMessage: 'Token de refresco inválido o expirado.',
        statusCode: 401,
      );
    }
    final String userId = refreshToken.replaceFirst('refresh_', '');
    final ShestUser user = _users[userId] ?? _users.values.first;
    return ShestAuthSession(
      accessToken: 'shest_jwt_refreshed_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'refresh_${user.id}',
      user: user,
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
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
  Future<List<P2POperation>> listOperations({
    P2POperationType? typeFilter,
    String? paymentMethodFilter,
    String? query,
  }) async {
    _ensureOnline();
    Iterable<P2POperation> filtered = _p2pOps;

    if (typeFilter != null) {
      filtered = filtered.where((P2POperation o) => o.type == typeFilter);
    }
    if (paymentMethodFilter != null &&
        paymentMethodFilter.isNotEmpty &&
        paymentMethodFilter != 'ALL') {
      filtered = filtered.where(
        (P2POperation o) => o.paymentMethod.toLowerCase().contains(
          paymentMethodFilter.toLowerCase(),
        ),
      );
    }
    if (query != null && query.trim().isNotEmpty) {
      final String q = query.trim().toLowerCase();
      filtered = filtered.where(
        (P2POperation o) =>
            o.makerName.toLowerCase().contains(q) ||
            o.id.toLowerCase().contains(q) ||
            o.paymentMethod.toLowerCase().contains(q),
      );
    }

    return List<P2POperation>.unmodifiable(filtered);
  }

  @override
  Future<P2POperation> createOperation({
    required String makerId,
    required double amountUsdt,
    required double rateUsd,
    required String paymentMethod,
    P2POperationType type = P2POperationType.sell,
    double? minAmountUsdt,
    double? maxAmountUsdt,
    String? notes,
  }) async {
    _ensureOnline();
    if (amountUsdt <= 0) {
      throw const ShestApiException(
        code: 'INVALID_AMOUNT',
        userMessage: 'El monto en USDT debe ser estrictamente mayor a 0.',
      );
    }
    if (rateUsd <= 0) {
      throw const ShestApiException(
        code: 'INVALID_RATE',
        userMessage: 'La tasa USD/USDT debe ser mayor a 0.',
      );
    }

    // Validación de saldos en caso de venta (escrow/bloqueo de liquidez)
    final double makerBalance = _walletBalances[makerId] ?? 0.0;
    if (type == P2POperationType.sell && makerBalance < amountUsdt) {
      throw ShestApiException(
        code: 'INSUFFICIENT_FUNDS',
        userMessage:
            'Saldo insuficiente (${makerBalance.toStringAsFixed(2)} USDT) para publicar orden de venta por ${amountUsdt.toStringAsFixed(2)} USDT.',
      );
    }

    final ShestUser maker = _users[makerId] ?? _users['usr_1']!;
    final double minLimit = minAmountUsdt ?? (amountUsdt > 50 ? 50.0 : 10.0);
    final double maxLimit = maxAmountUsdt ?? amountUsdt;

    final P2POperation op = P2POperation(
      id: 'P2P-${900 + _p2pOps.length + 1}',
      makerId: maker.id,
      makerName: '${maker.name} (${maker.company})',
      amountUsdt: amountUsdt,
      rateUsd: rateUsd,
      paymentMethod: paymentMethod,
      status: 'OPEN',
      type: type,
      minAmountUsdt: minLimit,
      maxAmountUsdt: maxLimit,
      reputationScore: 100.0,
      completedTradesCount: 1,
      createdAt: DateTime.now(),
      notes: notes,
    );

    // En venta, reservamos el balance del maker
    if (type == P2POperationType.sell) {
      _walletBalances[makerId] = makerBalance - amountUsdt;
    }

    _p2pOps.insert(0, op);

    eventBus.emit(
      WordverseEventType.p2pOpened,
      'Nueva orden P2P creada: ${op.id} (${type.label} ${op.amountUsdt} USDT)',
      <String, Object?>{
        'operationId': op.id,
        'makerId': maker.id,
        'amountUsdt': amountUsdt,
        'type': type.code,
      },
    );

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
        userMessage: 'La operación P2P no existe o fue retirada.',
      );
    }
    final P2POperation current = _p2pOps[idx];

    if (!current.isOpen) {
      throw ShestApiException(
        code: 'P2P_NOT_OPEN',
        userMessage:
            'La operación ${current.id} ya no está abierta (Estado: ${current.status}).',
      );
    }

    // Control financiero de auto-transacción
    if (current.makerId == takerId) {
      throw const ShestApiException(
        code: 'CANNOT_ACCEPT_OWN_ORDER',
        userMessage:
            'Integridad Financiera: No puedes tomar tu propia oferta P2P.',
      );
    }

    final ShestUser taker = _users[takerId] ?? _users['usr_1']!;
    final double takerBalance = _walletBalances[takerId] ?? 0.0;

    // Si la orden es de COMPRA para el maker, el taker debe vender y por ende tener fondos
    if (current.type == P2POperationType.buy && takerBalance < current.amountUsdt) {
      throw ShestApiException(
        code: 'INSUFFICIENT_FUNDS',
        userMessage:
            'Saldo insuficiente (${takerBalance.toStringAsFixed(2)} USDT) para completar la venta P2P al comprador.',
      );
    }

    // Ejecución atómica de saldos
    if (current.type == P2POperationType.sell) {
      // Maker ya había aportado; Taker recibe los USDT
      _walletBalances[takerId] = takerBalance + current.amountUsdt;
    } else {
      // Taker vende; Taker descuenta, Maker recibe
      _walletBalances[takerId] = takerBalance - current.amountUsdt;
      final double makerBal = _walletBalances[current.makerId] ?? 0.0;
      _walletBalances[current.makerId] = makerBal + current.amountUsdt;
    }

    final P2POperation updated = current.copyWith(
      status: 'COMPLETED',
      takerId: taker.id,
      takerName: '${taker.name} (${taker.company})',
    );
    _p2pOps[idx] = updated;

    eventBus.emit(
      WordverseEventType.paymentCompleted,
      'Operación P2P completada: ${current.id} entre ${current.makerId} y $takerId',
      <String, Object?>{
        'operationId': current.id,
        'makerId': current.makerId,
        'takerId': takerId,
        'amountUsdt': current.amountUsdt,
        'rateUsd': current.rateUsd,
      },
    );

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

    if (!current.isOpen) {
      throw ShestApiException(
        code: 'CANNOT_CANCEL',
        userMessage:
            'Solo se pueden cancelar órdenes en estado OPEN (Estado actual: ${current.status}).',
      );
    }

    // Si era venta, reembolsamos el balance retenido al maker
    if (current.type == P2POperationType.sell) {
      final double currentBal = _walletBalances[current.makerId] ?? 0.0;
      _walletBalances[current.makerId] = currentBal + current.amountUsdt;
    }

    final P2POperation updated = current.copyWith(
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

    // 1. Idempotencia: si ya está en el estado solicitado, retornar sin repetir efectos
    if (current.status == targetStatus) {
      return current;
    }

    // 2. Control de estados terminales
    if (current.isTerminal) {
      throw ShestApiException(
        code: 'ESCROW_TERMINAL_STATE',
        userMessage:
            'Integridad: El Escrow #${current.id} ya se encuentra en estado terminal (${current.status.displayLabel}).',
      );
    }

    // 3. Autorización de actores (Fase 5 — WV-500.1 / ESC-D3)
    final bool isCreator = current.isCreator(actorUserId);
    final bool isCounterparty = current.counterpartyId == actorUserId;
    final bool isArbiterOrAdmin = actorUserId.contains('arbiter') ||
        actorUserId.contains('admin') ||
        actorUserId == 'system';

    if (!isCreator && !isCounterparty && !isArbiterOrAdmin) {
      throw ShestApiException(
        code: 'UNAUTHORIZED_ACTOR',
        userMessage:
            'Seguridad: El usuario $actorUserId no está autorizado para modificar el Escrow #${current.id}.',
      );
    }

    // 4. Reglas financieras y validación de transiciones de estado
    switch (targetStatus) {
      case EscrowStatus.pending:
        break;

      case EscrowStatus.funded:
        if (current.status != EscrowStatus.pending) {
          throw ShestApiException(
            code: 'INVALID_TRANSITION',
            userMessage:
                'Solo se puede fondear un Escrow en estado PENDIENTE (Estado actual: ${current.status.displayLabel}).',
          );
        }
        if (!isCreator && !isArbiterOrAdmin) {
          throw const ShestApiException(
            code: 'CREATOR_ONLY_ACTION',
            userMessage: 'Solo el creador/depositante puede fondear el Escrow.',
          );
        }
        final double creatorBalance = _walletBalances[current.creatorId] ?? 0.0;
        if (creatorBalance < current.amount) {
          throw ShestApiException(
            code: 'ESCROW_INSUFFICIENT_FUNDS',
            userMessage:
                'Shest Backend: Saldo USDT insuficiente (${creatorBalance.toStringAsFixed(2)} USDT) para fondear el Escrow #${current.id} (${current.amount.toStringAsFixed(2)} USDT).',
          );
        }
        _walletBalances[current.creatorId] = creatorBalance - current.amount;
        _walletTxLogs
            .putIfAbsent(current.creatorId, () => <String>[])
            .insert(
              0,
              'Fondeo bloqueado en custodia ESCROW #${current.id}: -${current.amount.toStringAsFixed(2)} USDT',
            );
        break;

      case EscrowStatus.inProgress:
        if (current.status == EscrowStatus.pending) {
          throw const ShestApiException(
            code: 'ESCROW_NOT_FUNDED',
            userMessage:
                'Integridad: El Escrow debe ser fondeado antes de iniciar la entrega de servicios.',
          );
        }
        break;

      case EscrowStatus.releaseRequested:
        if (current.status == EscrowStatus.pending) {
          throw const ShestApiException(
            code: 'ESCROW_NOT_FUNDED',
            userMessage:
                'Integridad: No se puede solicitar liberación sobre un Escrow no fondeado.',
          );
        }
        break;

      case EscrowStatus.released:
      case EscrowStatus.completed:
        // ESC-D1: Prohibir liberación si nunca fue fondeado
        if (current.status == EscrowStatus.pending) {
          throw const ShestApiException(
            code: 'ESCROW_NOT_FUNDED',
            userMessage:
                'Integridad Financiera (ESC-D1): No se pueden liberar fondos de un Escrow que no ha sido fondeado.',
          );
        }
        // ESC-D3: Solo el creador o árbitro puede ordenar liberación (la contraparte no puede autoliberarse fondos)
        if (isCounterparty && !isArbiterOrAdmin && !isCreator) {
          throw const ShestApiException(
            code: 'CANNOT_SELF_RELEASE',
            userMessage:
                'Control Financiero: La contraparte beneficiaria no puede ordenar la liberación unilateral a su favor.',
          );
        }
        // Acreditar fondos a la contraparte solo si no se había liberado previamente
        if (current.status != EscrowStatus.released &&
            current.status != EscrowStatus.completed) {
          _walletBalances[current.counterpartyId] =
              (_walletBalances[current.counterpartyId] ?? 0.0) + current.amount;
          _walletTxLogs
              .putIfAbsent(current.counterpartyId, () => <String>[])
              .insert(
                0,
                'Custodia Escrow #${current.id} liberada a favor: +${current.amount.toStringAsFixed(2)} USDT',
              );
        }
        break;

      case EscrowStatus.cancelled:
        // ESC-D2: Si el escrow ya había sido fondeado, reembolsar al creador
        if (current.status != EscrowStatus.pending) {
          _walletBalances[current.creatorId] =
              (_walletBalances[current.creatorId] ?? 0.0) + current.amount;
          _walletTxLogs
              .putIfAbsent(current.creatorId, () => <String>[])
              .insert(
                0,
                'Reembolso íntegro por cancelación de ESCROW #${current.id}: +${current.amount.toStringAsFixed(2)} USDT',
              );
        }
        break;

      case EscrowStatus.disputed:
        if (current.status == EscrowStatus.pending) {
          throw const ShestApiException(
            code: 'ESCROW_NOT_FUNDED',
            userMessage:
                'No se puede abrir disputa sobre un contrato que aún no tiene fondos depositados.',
          );
        }
        break;
    }

    final String timeStr = DateTime.now().toIso8601String().substring(11, 19);
    final ShestUser actor = _users[actorUserId] ??
        ShestUser(
          id: actorUserId,
          name: actorUserId,
          company: 'Shest Arbitration',
          role: 'Audit',
          description: '',
          avatarInitials: 'SH',
          avatarHexColor: 0xFFD4AF37,
        );

    final List<String> updatedHistory = List<String>.from(current.historyLog)
      ..add(
        '[$timeStr] ${actor.name} (${actor.id}): ${current.status.apiValue} ➔ ${targetStatus.apiValue} (${targetStatus.displayLabel})',
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

  final WordverseTranslationService _translationEngine =
      WordverseTranslationService();

  @override
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    _ensureOnline();
    final TranslationResult res = await _translationEngine.translate(
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
    );
    return res.translatedText;
  }
}
