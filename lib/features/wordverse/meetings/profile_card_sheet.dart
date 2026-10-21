import 'package:flutter/material.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/models/shest_models.dart';
import 'escrow_p2p_modals.dart';
import 'meetings_qr_modals.dart';

/// Tarjeta de Perfil 3D y Tarjeta Digital (Fases 12 y 17).
/// Muestra Avatar, Nombre, Empresa, Cargo, Descripción, Estado, Favorito ⭐
/// y los 5 botones oficiales: CONEXIÓN, CHAT, REUNIÓN, P2P, ESCROW.
class AvatarProfileCardSheet extends StatefulWidget {
  const AvatarProfileCardSheet({
    super.key,
    required this.apiClient,
    required this.currentUser,
    required this.initialTargetUser,
    required this.onUserUpdated,
  });

  final ShestApiClient apiClient;
  final ShestUser currentUser;
  final ShestUser initialTargetUser;
  final ValueChanged<ShestUser> onUserUpdated;

  @override
  State<AvatarProfileCardSheet> createState() => _AvatarProfileCardSheetState();
}

class _AvatarProfileCardSheetState extends State<AvatarProfileCardSheet> {
  late ShestUser _target;
  String? _statusBanner;

  @override
  void initState() {
    super.initState();
    _target = widget.initialTargetUser;
  }

  Future<void> _handleConnect() async {
    try {
      final ShestUser updated = await widget.apiClient.auth.connectWithUser(
        targetUserId: _target.id,
      );
      widget.onUserUpdated(updated);
      if (!mounted) return;
      setState(() {
        _target = updated;
        _statusBanner =
            'Conexión establecida con ${updated.name} en Shest Networking.';
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() => _statusBanner = e.userMessage);
    }
  }

  Future<void> _handleToggleFavorite() async {
    try {
      final ShestUser updated = await widget.apiClient.auth.toggleFavorite(
        targetUserId: _target.id,
      );
      widget.onUserUpdated(updated);
      if (!mounted) return;
      setState(() {
        _target = updated;
        _statusBanner = updated.isFavorite
            ? '⭐ ${updated.name} agregado a tus favoritos.'
            : '${updated.name} removido de favoritos.';
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() => _statusBanner = e.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Color(_target.avatarHexColor);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 26,
                backgroundColor: color,
                child: Text(
                  _target.avatarInitials,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _target.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_target.role} • ${_target.company}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    Text(
                      '${_target.status.emoji} ${_target.status.label}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('btn_toggle_favorite'),
                tooltip: 'Favorito (Fase 30)',
                onPressed: _handleToggleFavorite,
                icon: Icon(
                  _target.isFavorite ? Icons.star : Icons.star_border,
                  color: Colors.amberAccent,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _target.description,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          if (_statusBanner != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent),
              ),
              child: Text(
                _statusBanner!,
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ElevatedButton.icon(
                key: const Key('profile_btn_conexion'),
                onPressed: _handleConnect,
                icon: Icon(
                  _target.isConnected ? Icons.check_circle : Icons.person_add,
                  size: 16,
                ),
                label: Text(_target.isConnected ? 'CONECTADO' : 'CONEXIÓN'),
              ),
              ElevatedButton.icon(
                key: const Key('profile_btn_chat'),
                onPressed: () {
                  Navigator.of(context).pop();
                  EscrowAndProfileModals.showNetworkingAndChatSheet(
                    context: context,
                    apiClient: widget.apiClient,
                    currentUser: widget.currentUser,
                    onUserUpdated: widget.onUserUpdated,
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('CHAT'),
              ),
              ElevatedButton.icon(
                key: const Key('profile_btn_reunion'),
                onPressed: () {
                  Navigator.of(context).pop();
                  MeetingsAndQrModals.showMeetingsSheet(
                    context: context,
                    apiClient: widget.apiClient,
                    currentUser: widget.currentUser,
                  );
                },
                icon: const Icon(Icons.groups, size: 16),
                label: const Text('REUNIÓN'),
              ),
              ElevatedButton.icon(
                key: const Key('profile_btn_p2p'),
                onPressed: () {
                  Navigator.of(context).pop();
                  EscrowAndProfileModals.showP2PAndWalletSheet(
                    context: context,
                    apiClient: widget.apiClient,
                    currentUser: widget.currentUser,
                  );
                },
                icon: const Icon(Icons.currency_exchange, size: 16),
                label: const Text('P2P'),
              ),
              ElevatedButton.icon(
                key: const Key('profile_btn_escrow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD740),
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  EscrowAndProfileModals.showEscrowSheet(
                    context: context,
                    apiClient: widget.apiClient,
                    currentUser: widget.currentUser,
                    preselectedCounterparty: _target,
                  );
                },
                icon: const Icon(Icons.verified_user, size: 16),
                label: const Text(
                  'ESCROW',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
