import 'package:flutter/material.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/models/shest_models.dart';
import '../../../core/services/wordverse_translation_service.dart';
import 'escrow_p2p_modals.dart';

/// Hub de Networking, Búsqueda por Nombre/Empresa, Contactos Favoritos ⭐,
/// Chat en Tiempo Real y Traducción Asistida por IA (Fases 13, 14, 29, 30 y Fase 3 — WV-301.1).
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

  // Estado del motor de traducción IA (Fase 3 — WV-301.1)
  String _targetLanguage = 'es';
  bool _autoTranslate = true;
  final Map<String, TranslationResult> _translations =
      <String, TranslationResult>{};
  final Set<String> _pendingTranslations = <String>{};
  final Set<String> _collapsedTranslations = <String>{};

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

  void _triggerTranslationIfNeeded(WordverseChatMessage msg) {
    if (!_autoTranslate) return;
    final String key = '${msg.id}_$_targetLanguage';
    if (_translations.containsKey(key) || _pendingTranslations.contains(key)) {
      return;
    }

    _pendingTranslations.add(key);
    widget.apiClient.translationService
        .translate(text: msg.text, targetLanguage: _targetLanguage)
        .then((TranslationResult res) {
          if (!mounted) return;
          setState(() {
            _translations[key] = res;
            _pendingTranslations.remove(key);
          });
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() {
            _pendingTranslations.remove(key);
          });
        });
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

    // Disparar traducción reactiva de los mensajes visibles
    for (final WordverseChatMessage m in messages) {
      _triggerTranslationIfNeeded(m);
    }

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
                  key: const Key('btn_close_networking_sheet'),
                  tooltip: 'Cerrar',
                  onPressed: () {
                    if (Navigator.of(context, rootNavigator: true).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
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

            // Barra de controles de Chat e Idioma IA (Fase 3 — WV-301.1)
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Chat Multilingüe IA:',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        '🌐 IA:',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: const Key('dropdown_chat_language'),
                          value: _targetLanguage,
                          dropdownColor: const Color(0xFF0A1020),
                          isDense: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'es',
                              child: Text('🇪🇸 ES'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'en',
                              child: Text('🇺🇸 EN'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'pt',
                              child: Text('🇧🇷 PT'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'zh',
                              child: Text('🇨🇳 ZH'),
                            ),
                          ],
                          onChanged: (String? newLang) {
                            if (newLang != null && newLang != _targetLanguage) {
                              setState(() {
                                _targetLanguage = newLang;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        key: const Key('btn_toggle_auto_translate'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: _autoTranslate
                            ? 'Traducción IA Activa (clic para pausar)'
                            : 'Traducción IA Pausada (clic para activar)',
                        icon: Icon(
                          _autoTranslate
                              ? Icons.translate
                              : Icons.g_translate_outlined,
                          size: 17,
                          color: _autoTranslate
                              ? Colors.cyanAccent
                              : Colors.white38,
                        ),
                        onPressed: () {
                          setState(() {
                            _autoTranslate = !_autoTranslate;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Ventana de mensajes con soporte bilingüe dual (Original + IA)
            Container(
              height: 155,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1020),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1E293B),
                ),
              ),
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay mensajes en este canal. Sé el primero en escribir.',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    )
                  : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, int index) {
                        final WordverseChatMessage m = messages[index];
                        final String transKey = '${m.id}_$_targetLanguage';
                        final TranslationResult? trans = _translations[transKey];
                        final bool isPending =
                            _pendingTranslations.contains(transKey);
                        final bool isCollapsed =
                            _collapsedTranslations.contains(m.id);

                        final bool hasDifferentLanguage = trans != null &&
                            trans.sourceLanguage != _targetLanguage &&
                            trans.translatedText.trim() != m.text.trim();

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111A2E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Mensaje original
                              RichText(
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

                              // Renderizado de traducción bilingüe
                              if (_autoTranslate && isPending)
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: Row(
                                    children: <Widget>[
                                      SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.amberAccent,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Traduciendo mediante IA...',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              if (_autoTranslate &&
                                  hasDifferentLanguage &&
                                  !isCollapsed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F2338),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.cyan.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD4AF37)
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            'IA: ${trans.sourceLanguage.toUpperCase()} ➔ ${_targetLanguage.toUpperCase()}',
                                            style: const TextStyle(
                                              color: Color(0xFFD4AF37),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            trans.translatedText,
                                            key: Key(
                                              'translated_text_${m.id}',
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFFE2E8F0),
                                              fontSize: 11.5,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _collapsedTranslations.add(m.id);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.visibility_off,
                                            size: 13,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (_autoTranslate &&
                                  hasDifferentLanguage &&
                                  isCollapsed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _collapsedTranslations.remove(m.id);
                                      });
                                    },
                                    child: const Text(
                                      '👁️ Mostrar traducción IA',
                                      style: TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
