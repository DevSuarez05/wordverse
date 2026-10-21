import 'package:flutter/material.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/models/shest_models.dart';

/// Panel de P2P, Wallet USDT TRC20 y Pagos validados por Shest API (Fases 18, 25, 26).
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
