import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/events/wordverse_events.dart';
import '../../../core/models/shest_models.dart';
import 'meetings_qr_modals.dart';

/// Modales de Perfil 3D, Networking, Chat, P2P, Wallet, Pagos y Escrow (Fases 12-26, 29-30).
class EscrowAndProfileModals {
  /// Fase 12 y 17: Al tocar un avatar en la Sala 3D muestra su Tarjeta de Perfil 3D
  /// con los botones oficiales: CONEXIÓN, CHAT, REUNIÓN, P2P, ESCROW y Favorito ⭐.
  static Future<void> showAvatarProfileSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
    required ShestUser targetUser,
    required ValueChanged<ShestUser> onUserUpdated,
  }) async {
    apiClient.eventBus.emit(
      WordverseEventType.avatarSelected,
      'Perfil 3D abierto: ${targetUser.name} (${targetUser.company})',
      <String, Object?>{'targetUserId': targetUser.id},
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return _AvatarProfileCardSheet(
          apiClient: apiClient,
          currentUser: currentUser,
          initialTargetUser: targetUser,
          onUserUpdated: onUserUpdated,
        );
      },
    );
  }

  /// Fases 19-24: Abre el módulo central de ESCROW de WordVerse conectado a Shest API.
  static Future<void> showEscrowSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
    ShestUser? preselectedCounterparty,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return _EscrowCenterSheet(
          apiClient: apiClient,
          currentUser: currentUser,
          preselectedCounterparty: preselectedCounterparty,
        );
      },
    );
  }

  /// Fases 18, 25, 26: Abre el panel de P2P, Wallet USDT TRC20 y Pagos validados por Shest.
  static Future<void> showP2PAndWalletSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
  }) async {
    apiClient.eventBus.emit(
      WordverseEventType.p2pOpened,
      'Módulo P2P / Wallet USDT TRC20 consultado vía Shest API',
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return _P2PAndWalletSheet(
          apiClient: apiClient,
          currentUser: currentUser,
        );
      },
    );
  }

  /// Fases 13, 14, 29, 30: Abre el Hub de Networking, Búsqueda por Nombre/Empresa,
  /// Contactos Favoritos ⭐ y Chat de la sala.
  static Future<void> showNetworkingAndChatSheet({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
    required ValueChanged<ShestUser> onUserUpdated,
    String initialChannelId = 'global_room',
  }) async {
    apiClient.eventBus.emit(
      WordverseEventType.chatOpened,
      'Hub de Networking & Chat abierto ($initialChannelId)',
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return _NetworkingAndChatSheet(
          apiClient: apiClient,
          currentUser: currentUser,
          onUserUpdated: onUserUpdated,
          channelId: initialChannelId,
        );
      },
    );
  }
}

// =============================================================================
// 1. TARJETA DE PERFIL 3D (Fase 12 y 17)
// =============================================================================

class _AvatarProfileCardSheet extends StatefulWidget {
  const _AvatarProfileCardSheet({
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
  State<_AvatarProfileCardSheet> createState() =>
      _AvatarProfileCardSheetState();
}

class _AvatarProfileCardSheetState extends State<_AvatarProfileCardSheet> {
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
          // Botones oficiales de Fase 12: CONEXIÓN, CHAT, REUNIÓN, P2P, ESCROW
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

// =============================================================================
// 2. MÓDULO CENTRAL DE ESCROW + QR DE ESCROW (Fases 19-24)
// =============================================================================

class _EscrowCenterSheet extends StatefulWidget {
  const _EscrowCenterSheet({
    required this.apiClient,
    required this.currentUser,
    this.preselectedCounterparty,
  });

  final ShestApiClient apiClient;
  final ShestUser currentUser;
  final ShestUser? preselectedCounterparty;

  @override
  State<_EscrowCenterSheet> createState() => _EscrowCenterSheetState();
}

class _EscrowCenterSheetState extends State<_EscrowCenterSheet> {
  final TextEditingController _amountCtrl = TextEditingController(text: '1500');
  final TextEditingController _descCtrl = TextEditingController(
    text: 'Desarrollo y entrega de lote comercial B2B',
  );
  final TextEditingController _condCtrl = TextEditingController(
    text: 'Liberación tras validación de entregables por ambas partes en Shest',
  );

  List<ShestUser> _counterparties = <ShestUser>[];
  String _selectedCounterpartyId = 'usr_2';
  List<EscrowOperation> _escrows = <EscrowOperation>[];
  EscrowOperation? _qrEscrow;
  String? _bannerMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCounterparty != null &&
        widget.preselectedCounterparty!.id != widget.currentUser.id) {
      _selectedCounterpartyId = widget.preselectedCounterparty!.id;
    }
    _refreshData();
  }

  Future<void> _refreshData() async {
    try {
      final List<ShestUser> users = await widget.apiClient.auth.searchUsers();
      final List<EscrowOperation> escrows =
          await widget.apiClient.escrow.listEscrows(widget.currentUser.id);
      if (!mounted) return;
      setState(() {
        _counterparties = users
            .where((ShestUser u) => u.id != widget.currentUser.id)
            .toList();
        _escrows = escrows;
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _bannerMessage = e.userMessage;
      });
    }
  }

  Future<void> _createNewEscrow() async {
    final double amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    try {
      final EscrowOperation created =
          await widget.apiClient.escrow.createEscrow(
            creatorId: widget.currentUser.id,
            counterpartyId: _selectedCounterpartyId,
            amount: amount,
            currency: 'USDT',
            description: _descCtrl.text.trim(),
            conditions: _condCtrl.text.trim(),
          );
      await _refreshData();
      if (!mounted) return;
      setState(() {
        _isError = false;
        _qrEscrow = created;
        _bannerMessage =
            'ESCROW #${created.id} PENDIENTE creado mediante Shest API.';
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _bannerMessage = e.userMessage;
      });
    }
  }

  Future<void> _transitionEscrow(
    EscrowOperation escrow,
    EscrowStatus nextStatus,
  ) async {
    try {
      final EscrowOperation updated =
          await widget.apiClient.escrow.transitionEscrowState(
            escrowId: escrow.id,
            actorUserId: widget.currentUser.id,
            targetStatus: nextStatus,
          );
      await _refreshData();
      if (!mounted) return;
      setState(() {
        _isError = false;
        _bannerMessage =
            'ESCROW #${updated.id} actualizado a ${updated.status.apiValue} (${updated.status.displayLabel})';
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _bannerMessage = e.userMessage;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _condCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    '💰 ESCROW MEDIANTE SHEST API (Fases 19-24)',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD740),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            if (_bannerMessage != null)
              Container(
                key: const Key('escrow_status_banner'),
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_isError ? Colors.red : Colors.amber)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isError ? Colors.redAccent : Colors.amberAccent,
                  ),
                ),
                child: Text(
                  _bannerMessage!,
                  style: TextStyle(
                    color: _isError ? Colors.redAccent : Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),

            // Formulario Fase 20: Contraparte, Monto, Moneda, Descripción, Condiciones
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _counterparties.any(
                      (ShestUser u) => u.id == _selectedCounterpartyId,
                    )
                        ? _selectedCounterpartyId
                        : (_counterparties.isNotEmpty
                              ? _counterparties.first.id
                              : null),
                    dropdownColor: const Color(0xFF162238),
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                    decoration: const InputDecoration(
                      labelText: 'Contraparte en la Sala',
                      labelStyle: TextStyle(color: Colors.white70),
                      isDense: true,
                    ),
                    items: _counterparties
                        .map(
                          (ShestUser u) => DropdownMenuItem<String>(
                            value: u.id,
                            child: Text('${u.name} (${u.company})'),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) {
                      if (v != null) {
                        setState(() => _selectedCounterpartyId = v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    key: const Key('input_escrow_amount'),
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Monto (USDT TRC20)',
                      labelStyle: TextStyle(color: Colors.white70),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              decoration: const InputDecoration(
                labelText: 'Descripción de la operación',
                labelStyle: TextStyle(color: Colors.white70),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _condCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              decoration: const InputDecoration(
                labelText: 'Condiciones de liberación',
                labelStyle: TextStyle(color: Colors.white70),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('btn_submit_create_escrow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD740),
                  foregroundColor: Colors.black,
                ),
                onPressed: _createNewEscrow,
                icon: const Icon(Icons.lock_clock, size: 18),
                label: const Text(
                  'CREAR ESCROW EN SHEST API',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const Divider(color: Colors.white24, height: 22),

            // Listado de Escrows con formato oficial de Fase 21, 22 y 23
            for (final EscrowOperation e in _escrows)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF172542),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'ESCROW #${e.id} ${e.status.displayLabel}',
                          style: const TextStyle(
                            color: Color(0xFFFFD740),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.black54,
                          label: Text(
                            e.status.apiValue,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Monto: ${e.amount.toStringAsFixed(2)} ${e.currency}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      'Estado: ${e.status.displayLabel} (${e.status.apiValue})',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Participantes: ${e.creatorName} / ${e.counterpartyName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    // Botones de acción Fase 23 según la API de Shest
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        _stateBtn(e, EscrowStatus.funded, 'Fondear'),
                        _stateBtn(e, EscrowStatus.inProgress, 'Aceptar'),
                        _stateBtn(
                          e,
                          EscrowStatus.releaseRequested,
                          'Solicitar Liberación',
                        ),
                        _stateBtn(e, EscrowStatus.released, 'Liberar'),
                        _stateBtn(e, EscrowStatus.completed, 'Completar'),
                        _stateBtn(e, EscrowStatus.disputed, 'Disputa'),
                        _stateBtn(e, EscrowStatus.cancelled, 'Cancelar'),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _qrEscrow = e),
                          icon: const Icon(Icons.qr_code, size: 14),
                          label: const Text(
                            'QR Escrow (Fase 24)',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (_qrEscrow != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      QrImageView(data: _qrEscrow!.qrPayload, size: 115),
                      Text(
                        'QR ESCROW #${_qrEscrow!.id} • ${_qrEscrow!.amount.toStringAsFixed(0)} USDT',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stateBtn(
    EscrowOperation escrow,
    EscrowStatus status,
    String actionLabel,
  ) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        key: Key('escrow_${escrow.id}_to_${status.apiValue}'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: const Color(0xFF23396C),
          foregroundColor: Colors.white,
        ),
        onPressed: () => _transitionEscrow(escrow, status),
        child: Text(actionLabel, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}

// =============================================================================
// 3. P2P, WALLET & PAGOS SHEST (Fases 18, 25, 26)
// =============================================================================

class _P2PAndWalletSheet extends StatefulWidget {
  const _P2PAndWalletSheet({
    required this.apiClient,
    required this.currentUser,
  });

  final ShestApiClient apiClient;
  final ShestUser currentUser;

  @override
  State<_P2PAndWalletSheet> createState() => _P2PAndWalletSheetState();
}

class _P2PAndWalletSheetState extends State<_P2PAndWalletSheet> {
  final TextEditingController _payAmountCtrl =
      TextEditingController(text: '250');
  final TextEditingController _payConceptCtrl = TextEditingController(
    text: 'Anticipo consultoría Networking',
  );
  WalletInfo? _wallet;
  List<P2POperation> _p2pList = <P2POperation>[];
  String? _statusMsg;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final WalletInfo w =
          await widget.apiClient.wallet.getWalletInfo(widget.currentUser.id);
      final List<P2POperation> ops =
          await widget.apiClient.p2p.listOperations();
      if (!mounted) return;
      setState(() {
        _wallet = w;
        _p2pList = ops;
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _statusMsg = e.userMessage;
      });
    }
  }

  Future<void> _sendDirectPayment() async {
    final double amt = double.tryParse(_payAmountCtrl.text.trim()) ?? 0.0;
    try {
      final PaymentRecord rec = await widget.apiClient.wallet.createPayment(
        fromUserId: widget.currentUser.id,
        toUserId: 'usr_2',
        amountUsdt: amt,
        concept: _payConceptCtrl.text.trim(),
      );
      await _loadAll();
      if (!mounted) return;
      setState(() {
        _isError = false;
        _statusMsg =
            'Pago ${rec.id} procesado por Shest: ${rec.amountUsdt.toStringAsFixed(2)} USDT a ${rec.toUserName}.';
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _statusMsg = e.userMessage;
      });
    }
  }

  Future<void> _acceptP2P(String opId) async {
    try {
      await widget.apiClient.p2p.acceptOperation(
        operationId: opId,
        takerId: widget.currentUser.id,
      );
      await _loadAll();
      if (!mounted) return;
      setState(() {
        _isError = false;
        _statusMsg = 'Orden $opId ejecutada exitosamente en el módulo P2P de Shest.';
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _statusMsg = e.userMessage;
      });
    }
  }

  @override
  void dispose() {
    _payAmountCtrl.dispose();
    _payConceptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    'WALLET USDT TRC20, P2P & PAGOS (Fases 18, 25, 26)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            if (_statusMsg != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_isError ? Colors.red : Colors.green)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isError ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
                child: Text(
                  _statusMsg!,
                  style: TextStyle(
                    color: _isError ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_wallet != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF172542),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Balance en Shest Wallet: ${_wallet!.usdtBalance.toStringAsFixed(2)} USDT (TRC20)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Dirección TRC20: ${_wallet!.trc20Address}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Enviar Pago Mediante Payment API Shest (Fase 26):',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('input_payment_amount'),
                    controller: _payAmountCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Monto USDT',
                      labelStyle: TextStyle(color: Colors.white70),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _payConceptCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Concepto',
                      labelStyle: TextStyle(color: Colors.white70),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  key: const Key('btn_send_payment'),
                  onPressed: _sendDirectPayment,
                  child: const Text('Pagar'),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 22),
            const Text(
              'Mercado P2P Existente de Shest (Fase 18):',
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 6),
            for (final P2POperation op in _p2pList)
              Card(
                color: const Color(0xFF172542),
                child: ListTile(
                  dense: true,
                  title: Text(
                    '${op.id} • ${op.amountUsdt.toStringAsFixed(0)} USDT @ \$${op.rateUsd} USD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${op.makerName} • ${op.paymentMethod} • Estado: ${op.status}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  trailing: op.status == 'OPEN'
                      ? ElevatedButton(
                          key: Key('btn_accept_p2p_${op.id}'),
                          onPressed: () => _acceptP2P(op.id),
                          child: const Text('Tomar Orden'),
                        )
                      : const Text(
                          'COMPLETADA',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 4. NETWORKING, BÚSQUEDA, FAVORITOS & CHAT (Fases 13, 14, 29, 30)
// =============================================================================

class _NetworkingAndChatSheet extends StatefulWidget {
  const _NetworkingAndChatSheet({
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
  State<_NetworkingAndChatSheet> createState() =>
      _NetworkingAndChatSheetState();
}

class _NetworkingAndChatSheetState extends State<_NetworkingAndChatSheet> {
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
