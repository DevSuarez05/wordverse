import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/models/shest_models.dart';

/// Módulo Central de ESCROW + QR de Escrow (Fases 19-24 y Fase 5 — WV-500.1..WV-503).
/// Consume exclusivamente `ShestApiClient.escrow` para crear operaciones
/// (`ESCROW #45821 PENDIENTE`) y transicionar estados mediante matriz de permisos RBAC.
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

  final Set<String> _expandedAuditLogs = <String>{};

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

  void _showDisputeDialog(EscrowOperation escrow) {
    final TextEditingController reasonCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.redAccent),
          ),
          title: Row(
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                'Abrir Disputa: Escrow #${escrow.id}',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Al abrir una disputa, la custodia de fondos quedará congelada inmediatamente hasta que el equipo de arbitraje de Shest emita una resolución formal.',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('input_dispute_reason'),
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo obligatorio de la disputa',
                  labelStyle: TextStyle(color: Colors.redAccent),
                  hintText: 'Ej. Incumplimiento de especificaciones acordadas...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              key: const Key('btn_confirm_dispute'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final String reason = reasonCtrl.text.trim();
                if (reason.isEmpty) return;
                Navigator.of(ctx).pop();
                _transitionEscrow(escrow, EscrowStatus.disputed);
              },
              child: const Text('Congelar y Abrir Disputa'),
            ),
          ],
        );
      },
    );
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
            // Banner de Aislamiento Sandbox (WV-500.1 / Prompt 5)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6)),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.shield_outlined, color: Color(0xFFD4AF37), size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'SANDBOX — CUSTODIA SIMULADA SIN FONDOS REALES',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Expanded(
                  child: Text(
                    '💰 ESCROW INSTITUCIONAL SHEST B2B',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD740),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('btn_close_escrow_sheet'),
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

            // Lista de Contratos Escrow con Matriz Contextual de Acciones (WV-501)
            for (final EscrowOperation e in _escrows)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D33),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: e.isDisputed
                        ? Colors.redAccent.withValues(alpha: 0.8)
                        : (e.isCompleted
                            ? Colors.greenAccent.withValues(alpha: 0.6)
                            : const Color(0xFFD4AF37).withValues(alpha: 0.6)),
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
                          style: TextStyle(
                            color: e.isDisputed
                                ? Colors.redAccent
                                : const Color(0xFFFFD740),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.black54,
                          label: Text(
                            e.status.apiValue,
                            style: TextStyle(
                              color: e.isDisputed
                                  ? Colors.redAccent
                                  : (e.isCompleted
                                      ? Colors.greenAccent
                                      : Colors.cyanAccent),
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
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Comprador: ${e.creatorName} • Vendedor: ${e.counterpartyName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                    const SizedBox(height: 6),

                    // Matriz Contextual de Acciones por Rol y Estado (WV-501)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        // PENDING: Fondeo por creador o cancelación
                        if (e.isPending) ...<Widget>[
                          _stateBtn(e, EscrowStatus.funded, '💰 Fondear Depósito', isPrimary: true),
                          _stateBtn(e, EscrowStatus.cancelled, '✕ Cancelar'),
                        ],

                        // FUNDED: Contraparte inicia entrega; Creador puede cancelar con reembolso
                        if (e.isFunded) ...<Widget>[
                          _stateBtn(e, EscrowStatus.inProgress, '🚀 Iniciar Entrega', isPrimary: true),
                          _stateBtn(e, EscrowStatus.cancelled, '↩️ Cancelar y Reembolsar'),
                          _disputeBtn(e),
                        ],

                        // IN_PROGRESS: Contraparte solicita liberación; Creador libera
                        if (e.isInProgress) ...<Widget>[
                          _stateBtn(
                            e,
                            EscrowStatus.releaseRequested,
                            '📤 Solicitar Liberación',
                            isPrimary: true,
                          ),
                          _stateBtn(
                            e,
                            EscrowStatus.released,
                            '✅ Liberar Fondos',
                            isPrimary: true,
                          ),
                          _disputeBtn(e),
                        ],

                        // RELEASE_REQUESTED: Creador aprueba liberación
                        if (e.isReleaseRequested) ...<Widget>[
                          _stateBtn(
                            e,
                            EscrowStatus.released,
                            '✅ Aprobar y Liberar',
                            isPrimary: true,
                          ),
                          _disputeBtn(e),
                        ],

                        // RELEASED: Finalización formal
                        if (e.isReleased) ...<Widget>[
                          _stateBtn(e, EscrowStatus.completed, '✓ Completar Contrato', isPrimary: true),
                        ],

                        // DISPUTED: Arbitraje activo
                        if (e.isDisputed) ...<Widget>[
                          _stateBtn(e, EscrowStatus.released, '⚖️ Arbitraje: Liberar a Vendedor'),
                          _stateBtn(e, EscrowStatus.cancelled, '⚖️ Arbitraje: Reembolsar a Comprador'),
                        ],

                        // TERMINAL
                        if (e.isTerminal)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: e.isCompleted
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              e.isCompleted ? '✓ CONTRATO LIQUIDADO' : '✕ CONTRATO CANCELADO',
                              style: TextStyle(
                                color: e.isCompleted ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        OutlinedButton.icon(
                          onPressed: () => setState(() => _qrEscrow = e),
                          icon: const Icon(Icons.qr_code, size: 14),
                          label: const Text(
                            'QR Escrow',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Línea de Tiempo de Auditoría y Condiciones (WV-502)
                    InkWell(
                      key: Key('btn_toggle_audit_${e.id}'),
                      onTap: () {
                        setState(() {
                          if (_expandedAuditLogs.contains(e.id)) {
                            _expandedAuditLogs.remove(e.id);
                          } else {
                            _expandedAuditLogs.add(e.id);
                          }
                        });
                      },
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _expandedAuditLogs.contains(e.id)
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.cyanAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _expandedAuditLogs.contains(e.id)
                                ? 'Ocultar Auditoría y Condiciones'
                                : 'Ver Condiciones & Línea de Tiempo (${e.historyLog.length})',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_expandedAuditLogs.contains(e.id)) ...<Widget>[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF090E17),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              '📜 CONDICIONES PACTADAS:',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              e.conditions,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const Divider(color: Colors.white12, height: 14),
                            const Text(
                              '⏱️ LÍNEA DE TIEMPO DE AUDITORÍA EN TIEMPO REAL:',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            for (final String log in e.historyLog)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text('• ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                    Expanded(
                                      child: Text(
                                        log,
                                        style: const TextStyle(
                                          color: Color(0xFFE2E8F0),
                                          fontSize: 10.5,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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
    String actionLabel, {
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        key: Key('escrow_${escrow.id}_to_${status.apiValue}'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: isPrimary
              ? (status == EscrowStatus.released || status == EscrowStatus.completed
                  ? const Color(0xFF00FF87)
                  : const Color(0xFFD4AF37))
              : const Color(0xFF23396C),
          foregroundColor: isPrimary ? Colors.black : Colors.white,
        ),
        onPressed: () => _transitionEscrow(escrow, status),
        child: Text(
          actionLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _disputeBtn(EscrowOperation escrow) {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        key: Key('escrow_${escrow.id}_to_DISPUTED'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: const BorderSide(color: Colors.redAccent),
          foregroundColor: Colors.redAccent,
        ),
        onPressed: () => _showDisputeDialog(escrow),
        child: const Text('⚠️ Disputa', style: TextStyle(fontSize: 11)),
      ),
    );
  }
}
