import '../components/room_status_indicator.dart';

/// Modelo de Dominio para Salas Públicas en WordVerse Public Hub.
class PublicRoom {
  const PublicRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.previewImage,
    this.status = RoomAvailabilityStatus.disponible,
    this.participantCount = 0,
    this.maxCapacity = 50,
    required this.host,
    this.language = 'ES / EN',
    this.tags = const <String>[],
    this.subRoomKey = 'Sala Principal',
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String? previewImage;
  final RoomAvailabilityStatus status;
  final int participantCount;
  final int maxCapacity;
  final String host;
  final String language;
  final List<String> tags;
  final String subRoomKey;

  bool get isFull => participantCount >= maxCapacity || status == RoomAvailabilityStatus.llena;
  bool get canEnter => status != RoomAvailabilityStatus.mantenimiento && !isFull;

  /// Funcionalidades colaborativas activas según la categoría de la sala pública.
  List<String> get collaborativeTools {
    switch (category) {
      case 'P2P':
        return const <String>['Libro de Órdenes P2P', 'Cotizador USDT', 'Chat Verificado'];
      case 'Negocios':
        return const <String>['Proyector Pitch', 'Networking B2B', 'Creación Escrow'];
      case 'Shest Café':
        return const <String>['Catálogo Café USDT', 'Chat Social', 'Tarjetas QR'];
      default:
        return const <String>['Directorio en Vivo', 'Chat Abierto', 'Intercambio QR'];
    }
  }

  PublicRoom copyWith({
    RoomAvailabilityStatus? status,
    int? participantCount,
    int? maxCapacity,
  }) {
    return PublicRoom(
      id: id,
      name: name,
      description: description,
      category: category,
      previewImage: previewImage,
      status: status ?? this.status,
      participantCount: participantCount ?? this.participantCount,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      host: host,
      language: language,
      tags: tags,
      subRoomKey: subRoomKey,
    );
  }

  static List<PublicRoom> sampleCatalog() {
    return const <PublicRoom>[
      PublicRoom(
        id: 'pub_nexus_plaza',
        name: 'The Grand Nexus Plaza',
        description: 'Plaza central y atrio de WordVerse. Networking libre, hologramas corporativos y stands de innovación.',
        category: 'Networking',
        status: RoomAvailabilityStatus.enVivo,
        participantCount: 38,
        maxCapacity: 100,
        host: 'WordVerse Official',
        tags: <String>['Networking', 'Hologramas', 'Plaza', 'Oficial'],
        subRoomKey: 'Sala Principal',
      ),
      PublicRoom(
        id: 'pub_p2p_trading',
        name: 'Terminal P2P & Escrow Hub',
        description: 'Mesa de operaciones peer-to-peer y validación de contratos inteligentes con garantía Shest Labs.',
        category: 'P2P',
        status: RoomAvailabilityStatus.disponible,
        participantCount: 14,
        maxCapacity: 30,
        host: 'Shest P2P Desk',
        tags: <String>['P2P', 'Escrow', 'USDT', 'Arbitraje'],
        subRoomKey: 'P2P',
      ),
      PublicRoom(
        id: 'pub_business_expo',
        name: 'Expo de Startups & Negocios Web3',
        description: 'Exhibición de rondas semilla, conferencias empresariales y demostraciones de tecnología descentralizada.',
        category: 'Negocios',
        status: RoomAvailabilityStatus.disponible,
        participantCount: 22,
        maxCapacity: 50,
        host: 'Carlos Mendoza',
        tags: <String>['Inversión', 'Startups', 'Web3', 'Pitch'],
        subRoomKey: 'Negocios',
      ),
      PublicRoom(
        id: 'pub_tech_builders',
        name: 'Dev Lab & Arquitectura Espacial',
        description: 'Mesa redonda para desarrolladores Flutter, shaders WebGL y sistemas distribuidos de alta concurrencia.',
        category: 'Tech',
        status: RoomAvailabilityStatus.disponible,
        participantCount: 19,
        maxCapacity: 40,
        host: 'Daniel Dev',
        tags: <String>['Flutter', 'WebGL', 'Three.js', 'Arquitectura'],
        subRoomKey: 'Networking',
      ),
      PublicRoom(
        id: 'pub_shest_cafe',
        name: 'Shest Café & Lounge Social',
        description: 'Espacio relajado para charlar con colegas, tomar un café virtual e intercambiar códigos de contacto.',
        category: 'Shest Café',
        status: RoomAvailabilityStatus.disponible,
        participantCount: 8,
        maxCapacity: 25,
        host: 'Valeria Méndez',
        tags: <String>['Café', 'Casual', 'Social', 'Música'],
        subRoomKey: 'Shest Café',
      ),
    ];
  }
}
