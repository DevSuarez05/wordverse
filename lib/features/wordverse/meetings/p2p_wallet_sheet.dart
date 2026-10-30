import 'package:flutter/material.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/models/shest_models.dart';

/// Panel de P2P Avanzado, Wallet USDT TRC20, Publicación y Pagos validados por Shest API
/// (Fases 18, 25, 26 y Fase 4 — WV-401..WV-403).
class P2PAndWalletSheet extends StatefulWidget {
  const P2PAndWalletSheet({
    super.key,
    required this.apiClient,
    required this.currentUser,
  });

  final ShestApiClient apiClient;
  final ShestUser currentUser;

  @override
  State<P2PAndWalletSheet> createState() => _P2PAndWalletSheetState();
}

class _P2PAndWalletSheetState extends State<P2PAndWalletSheet> {
  final TextEditingController _payAmountCtrl =
      TextEditingController(text: '250');
  final TextEditingController _payConceptCtrl = TextEditingController(
    text: 'Anticipo consultoría Networking',
  );

  final TextEditingController _searchCtrl = TextEditingController();

  WalletInfo? _wallet;
  List<P2POperation> _p2pList = <P2POperation>[];
  String? _statusMsg;
  bool _isError = false;

  // Filtros avanzados P2P (WV-402)
  P2POperationType? _selectedTypeFilter;
  final String _selectedPaymentMethod = 'ALL';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final WalletInfo w =
          await widget.apiClient.wallet.getWalletInfo(widget.currentUser.id);
      final List<P2POperation> ops = await widget.apiClient.p2p.listOperations(
        typeFilter: _selectedTypeFilter,
        paymentMethodFilter: _selectedPaymentMethod,
        query: _searchCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _wallet = w;
        _p2pList = List<P2POperation>.from(ops);
        _applySorting();
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _statusMsg = e.userMessage;
      });
    }
  }

  void _applySorting() {
    _p2pList.sort((P2POperation a, P2POperation b) {
      final int comp = a.rateUsd.compareTo(b.rateUsd);
      return _sortAscending ? comp : -comp;
    });
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
        _statusMsg =
            'Orden $opId ejecutada exitosamente en el módulo P2P de Shest.';
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _statusMsg = e.userMessage;
      });
    }
  }

  Future<void> _cancelP2P(String opId) async {
    try {
      await widget.apiClient.p2p.cancelOperation(opId);
      await _loadAll();
      if (!mounted) return;
      setState(() {
        _isError = false;
        _statusMsg =
            'Orden $opId cancelada exitosamente y balance restituido.';
      });
    } on ShestApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _statusMsg = e.userMessage;
      });
    }
  }

  void _showCreateOrderModal() {
    final TextEditingController amountCtrl =
        TextEditingController(text: '500');
    final TextEditingController rateCtrl =
        TextEditingController(text: '1.000');
    final TextEditingController minCtrl =
        TextEditingController(text: '50');
    final TextEditingController maxCtrl =
        TextEditingController(text: '500');
    final TextEditingController notesCtrl =
        TextEditingController(text: 'Pago rápido verificado');

    P2POperationType selectedType = P2POperationType.sell;
    String selectedMethod = P2PPaymentMethod.commonMethods.first;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext modalCtx, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'PUBLICAR OFERTA P2P — WORDVERSE',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(modalCtx).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Selector de Tipo: Compra / Venta
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('🟢 COMPRAR USDT')),
                            selected: selectedType == P2POperationType.buy,
                            onSelected: (bool sel) {
                              if (sel) {
                                setModalState(() => selectedType = P2POperationType.buy);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('🔵 VENDER USDT')),
                            selected: selectedType == P2POperationType.sell,
                            onSelected: (bool sel) {
                              if (sel) {
                                setModalState(() => selectedType = P2POperationType.sell);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('input_create_p2p_amount'),
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Monto Total USDT',
                        labelStyle: TextStyle(color: Colors.white70),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('input_create_p2p_rate'),
                      controller: rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tasa USD por USDT',
                        labelStyle: TextStyle(color: Colors.white70),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      key: const Key('dropdown_create_p2p_method'),
                      initialValue: selectedMethod,
                      dropdownColor: const Color(0xFF172542),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago',
                        labelStyle: TextStyle(color: Colors.white70),
                        isDense: true,
                      ),
                      items: P2PPaymentMethod.commonMethods.map((String m) {
                        return DropdownMenuItem<String>(
                          value: m,
                          child: Text(m, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setModalState(() => selectedMethod = val);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Mínimo USDT',
                              labelStyle: TextStyle(color: Colors.white70),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Máximo USDT',
                              labelStyle: TextStyle(color: Colors.white70),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('btn_submit_create_p2p'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          final double amt =
                              double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          final double rate =
                              double.tryParse(rateCtrl.text.trim()) ?? 1.0;
                          final double minL =
                              double.tryParse(minCtrl.text.trim()) ?? 10.0;
                          final double maxL =
                              double.tryParse(maxCtrl.text.trim()) ?? amt;

                          Navigator.of(modalCtx).pop();

                          try {
                            final P2POperation created =
                                await widget.apiClient.p2p.createOperation(
                              makerId: widget.currentUser.id,
                              amountUsdt: amt,
                              rateUsd: rate,
                              paymentMethod: selectedMethod,
                              type: selectedType,
                              minAmountUsdt: minL,
                              maxAmountUsdt: maxL,
                              notes: notesCtrl.text.trim(),
                            );
                            await _loadAll();
                            if (!mounted) return;
                            setState(() {
                              _isError = false;
                              _statusMsg =
                                  'Oferta P2P ${created.id} creada exitosamente (${created.type.label} ${created.amountUsdt} USDT).';
                            });
                          } on ShestApiException catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _isError = true;
                              _statusMsg = e.userMessage;
                            });
                          }
                        },
                        child: const Text(
                          'Publicar Oferta en Mercado P2P',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _payAmountCtrl.dispose();
    _payConceptCtrl.dispose();
    _searchCtrl.dispose();
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
                    'WALLET USDT TRC20, MERCADO P2P & PAGOS',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('btn_close_p2p_sheet'),
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
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  ),
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

            // Encabezado P2P con botón de Crear Oferta (WV-403)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Mercado P2P Institucional (Fase 4):',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                ElevatedButton.icon(
                  key: const Key('btn_open_create_p2p'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  onPressed: _showCreateOrderModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Publicar Oferta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Buscador de Liquidez y Filtros (WV-402)
            TextField(
              key: const Key('input_search_p2p'),
              controller: _searchCtrl,
              onChanged: (_) => _loadAll(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.white54, size: 18),
                hintText: 'Buscar por comerciante, ID o método de pago...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),

            // Filtros de Tipo y Ordenamiento (WV-402)
            Row(
              children: <Widget>[
                ChoiceChip(
                  key: const Key('chip_filter_all'),
                  label: const Text('Todas', style: TextStyle(fontSize: 11)),
                  selected: _selectedTypeFilter == null,
                  onSelected: (bool sel) {
                    if (sel) {
                      setState(() => _selectedTypeFilter = null);
                      _loadAll();
                    }
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  key: const Key('chip_filter_buy'),
                  label: const Text('🟢 Compras', style: TextStyle(fontSize: 11)),
                  selected: _selectedTypeFilter == P2POperationType.buy,
                  onSelected: (bool sel) {
                    setState(() {
                      _selectedTypeFilter = sel ? P2POperationType.buy : null;
                    });
                    _loadAll();
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  key: const Key('chip_filter_sell'),
                  label: const Text('🔵 Ventas', style: TextStyle(fontSize: 11)),
                  selected: _selectedTypeFilter == P2POperationType.sell,
                  onSelected: (bool sel) {
                    setState(() {
                      _selectedTypeFilter = sel ? P2POperationType.sell : null;
                    });
                    _loadAll();
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: _sortAscending
                      ? 'Orden: Menor Tasa Primero'
                      : 'Orden: Mayor Tasa Primero',
                  icon: Icon(
                    _sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _applySorting();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Lista de Tarjetas P2P Enriquecidas
            if (_p2pList.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No se encontraron órdenes P2P con los filtros seleccionados.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              )
            else
              for (final P2POperation op in _p2pList)
                Card(
                  color: const Color(0xFF131D33),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: op.type == P2POperationType.buy
                          ? const Color(0xFF00FF87).withValues(alpha: 0.3)
                          : const Color(0xFF00F0FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: op.type == P2POperationType.buy
                                        ? const Color(0xFF00FF87).withValues(alpha: 0.2)
                                        : const Color(0xFF00F0FF).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    op.type.badge,
                                    style: TextStyle(
                                      color: op.type == P2POperationType.buy
                                          ? const Color(0xFF00FF87)
                                          : const Color(0xFF00F0FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  op.id,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '⭐ ${op.reputationScore.toStringAsFixed(1)}% (${op.completedTradesCount} trades)',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${op.amountUsdt.toStringAsFixed(0)} USDT @ \$${op.rateUsd} USD',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Total: \$${op.totalFiat.toStringAsFixed(2)} ${op.fiatCurrency} • Límites: \$${op.minAmountUsdt.toStringAsFixed(0)} - \$${op.maxAmountUsdt.toStringAsFixed(0)} USDT',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                            // Botones de Acción Contextuales (WV-403)
                            if (op.isOpen) ...<Widget>[
                              if (op.isMaker(widget.currentUser.id))
                                ElevatedButton(
                                  key: Key('btn_cancel_p2p_${op.id}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade900,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                  ),
                                  onPressed: () => _cancelP2P(op.id),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  key: Key('btn_accept_p2p_${op.id}'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: op.type == P2POperationType.buy
                                        ? const Color(0xFF00FF87)
                                        : const Color(0xFF00F0FF),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: () => _acceptP2P(op.id),
                                  child: Text(
                                    op.type == P2POperationType.buy
                                        ? 'Vender a Maker'
                                        : 'Comprar USDT',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ] else if (op.isCompleted)
                              const Text(
                                '✓ COMPLETADA',
                                style: TextStyle(
                                  color: Color(0xFF00FF87),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              )
                            else if (op.isCancelled)
                              const Text(
                                '✕ CANCELADA',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${op.makerName} • ${op.paymentMethod}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
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
}
