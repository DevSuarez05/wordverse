import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/models/shest_models.dart';

/// Módulo Central de ESCROW + QR de Escrow (Fases 19-24).
/// Consume exclusivamente `ShestApiClient.escrow` para crear operaciones
/// (`ESCROW #45821 PENDIENTE`) y transicionar sus 8 estados oficiales.
class EscrowCenterSheet extends StatefulWidget {
  const EscrowCenterSheet({
    super.key,
    required this.apiClient,
    required this.currentUser,
    this.preselectedCounterparty,
  });

  final ShestApiClient apiClient;
  final ShestUser currentUser;
  final ShestUser? preselectedCounterparty;

  @override
  State<EscrowCenterSheet> createState() => _EscrowCenterSheetState();
}

class _EscrowCenterSheetState extends State<EscrowCenterSheet> {
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
            for (final EscrowOperation e in _escrows)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF172542),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amberAccent.withValues(alpha: 0.6),
                  ),
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
