enum RoomRole {
  owner('PROPIETARIO (HOST)'),
  moderator('MODERADOR'),
  member('MIEMBRO EJECUTIVO'),
  guest('INVITADO');

  const RoomRole(this.label);
  final String label;
}

/// Modelo de Dominio para Salas Privadas ("The Boardroom" / Private Suites).
class PrivateRoom {
  const PrivateRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    this.passcode,
    this.userRole = RoomRole.guest,
    this.participantCount = 0,
    this.maxCapacity = 12,
    this.isEncrypted = true,
    this.isClosed = false,
    this.meetingCode = 'WV-45821',
    this.validTokens = const <String>[],
    this.subRoomKey = 'Sala Privada',
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final String? passcode;
  final RoomRole userRole;
  final int participantCount;
  final int maxCapacity;
  final bool isEncrypted;
  final bool isClosed;
  final String meetingCode;
  final List<String> validTokens;
  final String subRoomKey;

  bool get isFull => participantCount >= maxCapacity;
  bool get isOwner => userRole == RoomRole.owner;
  bool get isModerator => userRole == RoomRole.moderator || isOwner;

  /// Permisos diferenciados por rol ejecutivo dentro de The Boardroom (Fase 2).
  bool get canControlHologram => isModerator && !isClosed;
  bool get canInviteParticipants => isModerator && !isClosed;
  bool get canCloseSuite => isOwner && !isClosed;
  bool get canVoteOrSignEscrow =>
      (userRole == RoomRole.owner ||
          userRole == RoomRole.moderator ||
          userRole == RoomRole.member) &&
      !isClosed;

  bool verifyAccess({String? enteredPasscode, String? enteredToken}) {
    if (isClosed || isFull) return false;
    if (userRole == RoomRole.owner || userRole == RoomRole.moderator) {
      return true;
    }
    if (passcode != null && passcode!.isNotEmpty) {
      if (enteredPasscode != null && enteredPasscode == passcode) {
        return true;
      }
    }
    if (enteredToken != null && validTokens.contains(enteredToken)) {
      return true;
    }
    return false;
  }

  PrivateRoom copyWith({
    RoomRole? userRole,
    int? participantCount,
    bool? isClosed,
    List<String>? validTokens,
  }) {
    return PrivateRoom(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      ownerName: ownerName,
      passcode: passcode,
      userRole: userRole ?? this.userRole,
      participantCount: participantCount ?? this.participantCount,
      maxCapacity: maxCapacity,
      isEncrypted: isEncrypted,
      isClosed: isClosed ?? this.isClosed,
      meetingCode: meetingCode,
      validTokens: validTokens ?? this.validTokens,
      subRoomKey: subRoomKey,
    );
  }

  static List<PrivateRoom> sampleSuites() {
    return const <PrivateRoom>[
      PrivateRoom(
        id: 'priv_boardroom_01',
        name: 'The Executive Boardroom VIP',
        description: 'Mesa de juntas central en cristal oscuro y oro cepillado. Proyección holográfica 3D, confidencialidad E2EE.',
        ownerId: 'usr_1',
        ownerName: 'Daniel (Tú)',
        passcode: 'NEXUS777',
        userRole: RoomRole.owner,
        participantCount: 3,
        maxCapacity: 10,
        isEncrypted: true,
        validTokens: <String>['INV-VIP-777', 'PREMION-DIRECTOR'],
        subRoomKey: 'Sala Privada',
      ),
      PrivateRoom(
        id: 'priv_investor_circle',
        name: 'Investor Syndicate Suite',
        description: 'Sala cerrada para revisión de métricas financieras, estructuración de rondas de inversión y NDAs.',
        ownerId: 'usr_3',
        ownerName: 'Carlos Mendoza',
        passcode: 'ALPHA2026',
        userRole: RoomRole.guest,
        participantCount: 5,
        maxCapacity: 8,
        isEncrypted: true,
        validTokens: <String>['SYNDICATE-TOKEN'],
        subRoomKey: 'Sala Privada',
      ),
    ];
  }
}
