/// Modelos de dominio compartidos entre WordVerse y la capa Shest API Client.
/// Regla Fundamental: WordVerse NO duplica la lógica financiera; estos modelos
/// representan las respuestas y contratos oficiales de Shest Labs.
library;

/// Estados del usuario dentro de Shest / WordVerse (Fase 16).
enum UserPresenceStatus {
  available('AVAILABLE', 'Disponible', '🟢'),
  busy('BUSY', 'Ocupado', '🟡'),
  unavailable('UNAVAILABLE', 'No disponible', '🔴');

  const UserPresenceStatus(this.code, this.label, this.emoji);
  final String code;
  final String label;
  final String emoji;
}

/// Emotes rápidos disponibles en la sala (Fase 15).
enum WordverseEmote {
  wave('👋', 'Saludar'),
  like('👍', 'Like'),
  negotiate('🤝', 'Negociar'),
  coffee('☕', 'Café'),
  talk('💬', 'Hablar'),
  p2p('💰', 'P2P');

  const WordverseEmote(this.emoji, this.label);
  final String emoji;
  final String label;
}

/// Estados oficiales de un Escrow soportados por el backend de Shest (Fase 22).
enum EscrowStatus {
  pending('PENDING', 'PENDIENTE'),
  funded('FUNDED', 'FONDEADO'),
  inProgress('IN_PROGRESS', 'EN PROGRESO'),
  releaseRequested('RELEASE_REQUESTED', 'LIBERACIÓN SOLICITADA'),
  released('RELEASED', 'LIBERADO'),
  disputed('DISPUTED', 'EN DISPUTA'),
  cancelled('CANCELLED', 'CANCELADO'),
  completed('COMPLETED', 'COMPLETADO');

  const EscrowStatus(this.apiValue, this.displayLabel);
  final String apiValue;
  final String displayLabel;
}

/// Tipos de reunión soportados en WordVerse (Fase 9).
enum MeetingType {
  networking('Networking'),
  negocios('Negocios'),
  p2p('P2P'),
  cafe('Café'),
  privada('Privada');

  const MeetingType(this.label);
  final String label;
}

/// Hotspots oficiales de la Sala 3D (Fase 27).
enum HotspotKind {
  networking('HOTSPOT 01', 'Networking', -0.60, -0.45),
  createMeeting('HOTSPOT 02', 'Crear reunión', 0.00, -0.65),
  qr('HOTSPOT 03', 'QR', 0.60, -0.45),
  p2p('HOTSPOT 04', 'P2P', -0.68, 0.20),
  escrow('HOTSPOT 05', 'ESCROW', 0.68, 0.20),
  myProfile('HOTSPOT 06', 'Mi perfil', -0.45, 0.68),
  exit('HOTSPOT 07', 'Salir', 0.45, 0.68);

  const HotspotKind(this.code, this.title, this.normX, this.normZ);
  final String code;
  final String title;
  final double normX;
  final double normZ;
}

/// Perfil de usuario proveniente de Shest (Fases 4, 5, 12, 17).
class ShestUser {
  const ShestUser({
    required this.id,
    required this.name,
    required this.company,
    required this.role,
    required this.description,
    required this.avatarInitials,
    required this.avatarHexColor,
    this.status = UserPresenceStatus.available,
    this.isFavorite = false,
    this.isConnected = false,
  });

  final String id;
  final String name;
  final String company;
  final String role;
  final String description;
  final String avatarInitials;
  final int avatarHexColor;
  final UserPresenceStatus status;
  final bool isFavorite;
  final bool isConnected;

  String get personalQrData => 'SHEST-USER:$id:$name:$company';

  ShestUser copyWith({
    UserPresenceStatus? status,
    bool? isFavorite,
    bool? isConnected,
  }) {
    return ShestUser(
      id: id,
      name: name,
      company: company,
      role: role,
      description: description,
      avatarInitials: avatarInitials,
      avatarHexColor: avatarHexColor,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// Sesión autenticada recibida desde Shest (Fases 0 y 4).
class ShestAuthSession {
  const ShestAuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final ShestUser user;
  final DateTime expiresAt;
}

/// Información de Wallet consultada a Shest API (Fases 0 y 25).
class WalletInfo {
  const WalletInfo({
    required this.userId,
    required this.usdtBalance,
    required this.trc20Address,
    required this.recentTransactions,
  });

  final String userId;
  final double usdtBalance;
  final String trc20Address;
  final List<String> recentTransactions;

  WalletInfo copyWith({
    String? userId,
    double? usdtBalance,
    String? trc20Address,
    List<String>? recentTransactions,
  }) {
    return WalletInfo(
      userId: userId ?? this.userId,
      usdtBalance: usdtBalance ?? this.usdtBalance,
      trc20Address: trc20Address ?? this.trc20Address,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }
}

/// Operación de Escrow gestionada por Shest API (Fases 19-24).
class EscrowOperation {
  const EscrowOperation({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.counterpartyId,
    required this.counterpartyName,
    required this.amount,
    required this.currency,
    required this.description,
    required this.conditions,
    required this.status,
    required this.createdAt,
    required this.historyLog,
  });

  final String id;
  final String creatorId;
  final String creatorName;
  final String counterpartyId;
  final String counterpartyName;
  final double amount;
  final String currency;
  final String description;
  final String conditions;
  final EscrowStatus status;
  final DateTime createdAt;
  final List<String> historyLog;

  String get qrPayload => 'SHEST-ESCROW:$id:$amount:$currency:${status.apiValue}';

  bool isCreator(String userId) => creatorId == userId;
  bool isCounterparty(String userId) => counterpartyId == userId;
  bool isParticipant(String userId) => isCreator(userId) || isCounterparty(userId);

  bool get isPending => status == EscrowStatus.pending;
  bool get isFunded => status == EscrowStatus.funded;
  bool get isInProgress => status == EscrowStatus.inProgress;
  bool get isReleaseRequested => status == EscrowStatus.releaseRequested;
  bool get isReleased => status == EscrowStatus.released;
  bool get isCompleted => status == EscrowStatus.completed;
  bool get isDisputed => status == EscrowStatus.disputed;
  bool get isCancelled => status == EscrowStatus.cancelled;
  bool get isTerminal => isCompleted || isCancelled;

  EscrowOperation copyWith({
    EscrowStatus? status,
    List<String>? historyLog,
  }) {
    return EscrowOperation(
      id: id,
      creatorId: creatorId,
      creatorName: creatorName,
      counterpartyId: counterpartyId,
      counterpartyName: counterpartyName,
      amount: amount,
      currency: currency,
      description: description,
      conditions: conditions,
      status: status ?? this.status,
      createdAt: createdAt,
      historyLog: historyLog ?? this.historyLog,
    );
  }
}

/// Reunión creada en WordVerse (Fases 9-11, 28).
class WordverseMeeting {
  const WordverseMeeting({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.description,
    required this.isPrivate,
    required this.creatorId,
    required this.creatorName,
    this.durationMinutes = 45,
    this.participantIds = const <String>[],
  });

  final String id;
  final String code; // Ej: WV-45821
  final String name;
  final MeetingType type;
  final String description;
  final bool isPrivate;
  final String creatorId;
  final String creatorName;
  final int durationMinutes;
  final List<String> participantIds;

  String get qrPayload => 'SHEST-MEETING:$code:$id:${type.label}';
}

/// Tipo de orden en el libro de ofertas P2P (Fase 4 — WV-401).
enum P2POperationType {
  buy('BUY', 'Compra USDT', '🟢 Compra'),
  sell('SELL', 'Venta USDT', '🔵 Venta');

  const P2POperationType(this.code, this.label, this.badge);
  final String code;
  final String label;
  final String badge;

  static P2POperationType fromCode(String? code) {
    if (code == null) return P2POperationType.sell;
    final String clean = code.trim().toUpperCase();
    if (clean == 'BUY' || clean == 'COMPRA') return P2POperationType.buy;
    return P2POperationType.sell;
  }
}

/// Métodos de pago estándar soportados por el mercado P2P de Shest (Fase 4 — WV-401).
enum P2PPaymentMethod {
  bankWire('WIRE', 'Transferencia Bancaria / Wire'),
  instantShest('INSTANT_SHEST', 'Liquidación Inmediata Shest'),
  zelleAch('ZELLE_ACH', 'Zelle / ACH'),
  cryptoTrc20('CRYPTO_TRC20', 'TRC20 Directo');

  const P2PPaymentMethod(this.code, this.label);
  final String code;
  final String label;

  static const List<String> commonMethods = <String>[
    'Transferencia Bancaria / Wire',
    'Liquidación Inmediata Shest',
    'Zelle / ACH',
    'TRC20 Directo',
  ];
}

/// Operación P2P delegada a Shest API (Fases 18 y 4 — WV-401).
class P2POperation {
  const P2POperation({
    required this.id,
    required this.makerId,
    required this.makerName,
    required this.amountUsdt,
    required this.rateUsd,
    required this.paymentMethod,
    required this.status,
    this.type = P2POperationType.sell,
    double? minAmountUsdt,
    double? maxAmountUsdt,
    this.reputationScore = 99.2,
    this.completedTradesCount = 35,
    this.fiatCurrency = 'USD',
    this.takerId,
    this.takerName,
    this.createdAt,
    this.notes,
  }) : minAmountUsdt = minAmountUsdt ?? (amountUsdt > 50 ? 50.0 : 10.0),
       maxAmountUsdt = maxAmountUsdt ?? amountUsdt;

  final String id;
  final String makerId;
  final String makerName;
  final double amountUsdt;
  final double rateUsd;
  final String paymentMethod;
  final String status; // OPEN, IN_PROGRESS, COMPLETED, CANCELLED
  final P2POperationType type;
  final double minAmountUsdt;
  final double maxAmountUsdt;
  final double reputationScore;
  final int completedTradesCount;
  final String fiatCurrency;
  final String? takerId;
  final String? takerName;
  final DateTime? createdAt;
  final String? notes;

  double get totalFiat => amountUsdt * rateUsd;
  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  bool isMaker(String userId) => makerId == userId;

  P2POperation copyWith({
    String? id,
    String? makerId,
    String? makerName,
    double? amountUsdt,
    double? rateUsd,
    String? paymentMethod,
    String? status,
    P2POperationType? type,
    double? minAmountUsdt,
    double? maxAmountUsdt,
    double? reputationScore,
    int? completedTradesCount,
    String? fiatCurrency,
    String? takerId,
    String? takerName,
    DateTime? createdAt,
    String? notes,
  }) {
    return P2POperation(
      id: id ?? this.id,
      makerId: makerId ?? this.makerId,
      makerName: makerName ?? this.makerName,
      amountUsdt: amountUsdt ?? this.amountUsdt,
      rateUsd: rateUsd ?? this.rateUsd,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      type: type ?? this.type,
      minAmountUsdt: minAmountUsdt ?? this.minAmountUsdt,
      maxAmountUsdt: maxAmountUsdt ?? this.maxAmountUsdt,
      reputationScore: reputationScore ?? this.reputationScore,
      completedTradesCount: completedTradesCount ?? this.completedTradesCount,
      fiatCurrency: fiatCurrency ?? this.fiatCurrency,
      takerId: takerId ?? this.takerId,
      takerName: takerName ?? this.takerName,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}

/// Pago procesado por Shest API (Fase 26).
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.toUserName,
    required this.amountUsdt,
    required this.concept,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final String toUserName;
  final double amountUsdt;
  final String concept;
  final String status; // CONFIRMED, REJECTED
  final DateTime timestamp;
}

/// Mensaje de chat dentro de reunión o entre conexiones (Fase 14).
class WordverseChatMessage {
  const WordverseChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.channelId,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String channelId;
  final String text;
  final DateTime sentAt;
}

/// Excepción tipada para manejo de errores y trazabilidad de Shest API (Fase 1 y Fase 34).
class ShestApiException implements Exception {
  const ShestApiException({
    required this.code,
    required this.userMessage,
    this.statusCode,
    this.traceId,
  });

  final String code;
  final String userMessage;
  final int? statusCode;
  final String? traceId;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403 || code == 'UNAUTHORIZED';

  bool get isRetryable =>
      code == 'NETWORK_OFFLINE' ||
      statusCode == 408 ||
      statusCode == 429 ||
      (statusCode != null && statusCode! >= 500);

  @override
  String toString() {
    final String httpPart = statusCode != null ? ' HTTP $statusCode' : '';
    final String tracePart = traceId != null ? ' ($traceId)' : '';
    return '[$code$httpPart]$tracePart $userMessage';
  }
}
