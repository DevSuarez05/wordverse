import 'package:flutter/material.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/models/shest_models.dart';
import 'escrow_p2p_modals.dart';

/// Hub de Networking, Búsqueda por Nombre/Empresa, Contactos Favoritos ⭐ y Chat (Fases 13, 14, 29, 30).
class NetworkingAndChatSheet extends StatefulWidget {
  const NetworkingAndChatSheet({
    super.key,
    required this.apiClient,
    required this.currentUser,
    required this.onUserUpdated,
    required this.channelId,
  });

  final ShestApiClient apiClient;
  final ShestUser currentUser;
  final ValueChanged<ShestUser> onUserUpdated;
  final String channelId;

  @override
  State<NetworkingAndChatSheet> createState() => _NetworkingAndChatSheetState();
}

class _NetworkingAndChatSheetState extends State<NetworkingAndChatSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _chatCtrl = TextEditingController();
  List<ShestUser> _results = <ShestUser>[];
  bool _onlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    final List<ShestUser> users = await widget.apiClient.auth.searchUsers(
      query: _searchCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _results = _onlyFavorites
          ? users.where((ShestUser u) => u.isFavorite).toList()
          : users;
    });
  }

  Future<void> _sendChat() async {
    final String txt = _chatCtrl.text.trim();
    if (txt.isEmpty) return;
    await widget.apiClient.sendChatMessage(
      senderId: widget.currentUser.id,
      senderName: widget.currentUser.name,
      channelId: widget.channelId,
      text: txt,
    );
    _chatCtrl.clear();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<WordverseChatMessage> messages =
        widget.apiClient.getChatMessages(widget.channelId);

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'DIRECTORIO NETWORKING, FAVORITOS ⭐ & CHAT',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('input_search_users'),
                    controller: _searchCtrl,
                    onChanged: (_) => _runSearch(),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                      hintText: 'Buscar por nombre o empresa (Fase 29)...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('⭐ Favoritos'),
                  selected: _onlyFavorites,
                  onSelected: (bool v) {
                    setState(() => _onlyFavorites = v);
                    _runSearch();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final ShestUser u in _results)
              Card(
                color: const Color(0xFF172542),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: Color(u.avatarHexColor),
                    child: Text(
                      u.avatarInitials,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    '${u.isFavorite ? "⭐ " : ""}${u.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${u.company} • ${u.status.emoji} ${u.status.label}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      EscrowAndProfileModals.showAvatarProfileSheet(
                        context: context,
                        apiClient: widget.apiClient,
                        currentUser: widget.currentUser,
                        targetUser: u,
                        onUserUpdated: widget.onUserUpdated,
                      );
                    },
                    child: const Text('Abrir Perfil'),
                  ),
                ),
              ),
            const Divider(color: Colors.white24, height: 20),
            const Text(
              'Chat de Sala / Reunión en Tiempo Real (Fase 14):',
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 115,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1020),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final WordverseChatMessage m = messages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: RichText(
                      text: TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: '${m.senderName}: ',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          TextSpan(
                            text: m.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('input_chat_message'),
                    controller: _chatCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje para la sala...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  key: const Key('btn_send_chat'),
                  onPressed: _sendChat,
                  icon: const Icon(Icons.send, size: 15),
                  label: const Text('Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
