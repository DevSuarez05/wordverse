import 'package:flutter/material.dart';
import '../../../core/api_client/shest_api_client.dart';
import '../../../core/theme/wordverse_tokens.dart';
import '../components/public_room_card.dart';
import '../components/wordverse_buttons.dart';
import '../models/public_room.dart';

/// Pantalla y Módulo WordVerse Public Hub (Salas Públicas).
class PublicHubScreen extends StatefulWidget {
  const PublicHubScreen({
    super.key,
    required this.apiClient,
    required this.onEnterRoom,
    required this.onBackToLobby,
  });

  final ShestApiClient apiClient;
  final ValueChanged<PublicRoom> onEnterRoom;
  final VoidCallback onBackToLobby;

  @override
  State<PublicHubScreen> createState() => _PublicHubScreenState();
}

class _PublicHubScreenState extends State<PublicHubScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Todas';
  late List<PublicRoom> _rooms;
  String? _loadingRoomId;

  static const List<String> _categories = <String>[
    'Todas',
    'Networking',
    'P2P',
    'Negocios',
    'Tech',
    'Shest Café',
  ];

  @override
  void initState() {
    super.initState();
    _rooms = List<PublicRoom>.of(widget.apiClient.publicRooms);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PublicRoom> get _filteredRooms {
    return _rooms.where((PublicRoom r) {
      final bool matchesCategory =
          _selectedCategory == 'Todas' || r.category == _selectedCategory;
      final String query = _searchCtrl.text.trim().toLowerCase();
      final bool matchesSearch = query.isEmpty ||
          r.name.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query) ||
          r.tags.any((String t) => t.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _handleEnterRoom(PublicRoom room) async {
    if (!room.canEnter) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            room.isFull
                ? 'La sala "${room.name}" ha alcanzado su capacidad máxima (${room.maxCapacity}).'
                : 'La sala está temporalmente en mantenimiento.',
          ),
          backgroundColor: WordVerseTokens.rojoAlerta,
        ),
      );
      return;
    }

    setState(() => _loadingRoomId = room.id);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loadingRoomId = null);

    widget.onEnterRoom(room);
  }

  void _showCreateRoomDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    String category = 'Networking';
    int capacity = 30;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setDlgState) {
            return AlertDialog(
              title: Row(
                children: const <Widget>[
                  Icon(Icons.add_business, color: WordVerseTokens.cianHolografico),
                  SizedBox(width: 8),
                  Text('CREAR SALA PÚBLICA'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Sala',
                        hintText: 'Ej. Crypto Traders Lounge',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Propósito',
                        hintText: 'Temas a tratar o dinámica del espacio',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      dropdownColor: WordVerseTokens.negroElevado,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: _categories
                          .where((String c) => c != 'Todas')
                          .map(
                            (String c) =>
                                DropdownMenuItem<String>(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (String? val) {
                        if (val != null) setDlgState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        const Text(
                          'Capacidad máxima: ',
                          style: TextStyle(color: WordVerseTokens.grisTecnologico),
                        ),
                        Text(
                          '$capacity personas',
                          style: const TextStyle(
                            color: WordVerseTokens.cianHolografico,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: capacity.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 9,
                      activeColor: WordVerseTokens.cianHolografico,
                      onChanged: (double v) =>
                          setDlgState(() => capacity = v.round()),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
                ),
                WordVersePrimaryButton(
                  label: 'PUBLICAR SALA',
                  style: WordVerseButtonStyle.cyan,
                  onPressed: () async {
                    final String name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                    final NavigatorState navigator = Navigator.of(ctx);
                    final PublicRoom newRoom =
                        await widget.apiClient.createPublicRoom(
                          creatorId: 'usr_1',
                          creatorName: 'Daniel (Tú)',
                          name: name,
                          description: descCtrl.text.trim(),
                          category: category,
                          maxCapacity: capacity,
                        );
                    if (!mounted) return;
                    setState(() {
                      _rooms = List<PublicRoom>.of(widget.apiClient.publicRooms);
                    });
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Sala "${newRoom.name}" creada con éxito.'),
                        backgroundColor: WordVerseTokens.verdeEsmeralda,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<PublicRoom> visibleRooms = _filteredRooms;

    return Scaffold(
      backgroundColor: WordVerseTokens.negroProfundo,
      appBar: AppBar(
        backgroundColor: WordVerseTokens.negroObsidiana,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: widget.onBackToLobby,
          tooltip: 'Volver al Lobby Central',
        ),
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.public, color: WordVerseTokens.cianHolografico, size: 20),
              SizedBox(width: 8),
              Text(
                'WORDVERSE PUBLIC HUB',
                style: TextStyle(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WordVersePrimaryButton(
              label: 'CREAR SALA',
              icon: Icons.add,
              style: WordVerseButtonStyle.cyan,
              onPressed: _showCreateRoomDialog,
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Barra de Búsqueda y Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: WordVerseTokens.negroObsidiana,
              border: Border(
                bottom: BorderSide(color: Color(0x2200F0FF), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Input Búsqueda
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: WordVerseTokens.cianHolografico,
                    ),
                    hintText: 'Buscar salas públicas por nombre, tema o etiqueta...',
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Filtro por categorías
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((String cat) {
                      final bool isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (bool sel) {
                            if (sel) setState(() => _selectedCategory = cat);
                          },
                          selectedColor: WordVerseTokens.cianHolografico,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? WordVerseTokens.negroProfundo
                                : WordVerseTokens.blancoFrio,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: WordVerseTokens.negroElevado,
                          side: BorderSide(
                            color: isSelected
                                ? WordVerseTokens.cianHolografico
                                : const Color(0x33FFFFFF),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Catálogo de Salas
          Expanded(
            child: visibleRooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: WordVerseTokens.grisTecnologico,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No se encontraron salas públicas con ese criterio.',
                          style: TextStyle(color: WordVerseTokens.grisTecnologico),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: visibleRooms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (BuildContext context, int index) {
                      final PublicRoom r = visibleRooms[index];
                      return PublicRoomCard(
                        room: r,
                        isLoading: _loadingRoomId == r.id,
                        onEnter: () => _handleEnterRoom(r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
