import 'package:flutter/material.dart';

import '../../../core/api_client/shest_api_client.dart';
import '../../../core/models/shest_models.dart';

/// Vitrina Comercial 3D de **SHEST COFFEE** (100% Arabica • Tostado Premium • 12oz/340g)
/// + Pedidos con Wallet USDT TRC20 y Contratos Mayoristas con Escrow B2B.
/// Incluye también la pestaña del Glosario Oficial del Proyecto (`Conceptos.txt`).
class WordverseShestCafeSheet extends StatefulWidget {
  const WordverseShestCafeSheet({
    super.key,
    required this.apiClient,
    required this.currentUser,
    required this.onTransactionComplete,
  });

  final ShestApiClient apiClient;
  final ShestUser currentUser;
  final VoidCallback onTransactionComplete;

  static Future<void> show({
    required BuildContext context,
    required ShestApiClient apiClient,
    required ShestUser currentUser,
    required VoidCallback onTransactionComplete,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0B06),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext ctx) {
        return WordverseShestCafeSheet(
          apiClient: apiClient,
          currentUser: currentUser,
          onTransactionComplete: onTransactionComplete,
        );
      },
    );
  }

  @override
  State<WordverseShestCafeSheet> createState() =>
      _WordverseShestCafeSheetState();
}

class _WordverseShestCafeSheetState extends State<WordverseShestCafeSheet> {
  WalletInfo? _wallet;
  String? _feedbackMessage;
  bool _isProcessing = false;

  static const List<({String term, String desc})> _conceptos =
      <({String term, String desc})>[
        (term: 'Flutter', desc: 'Framework para crear la app multiplataforma'),
        (term: 'Dart', desc: 'Lenguaje de programación de Flutter'),
        (term: 'GLB', desc: 'Archivo/escena 3D binaria glTF 2.0 optimizada'),
        (term: 'Avatar', desc: 'Representación 3D del usuario en la sala'),
        (term: 'API', desc: 'Comunicación entre WordVerse y Shest Labs'),
        (term: 'Backend', desc: 'Parte del sistema que funciona detrás (Java/Supabase)'),
        (term: 'Frontend', desc: 'Lo que ve e interactúa el usuario en 3D'),
        (term: 'Mock', desc: 'Simulación temporal local sin bloqueos'),
        (term: 'MVP', desc: 'Primera versión funcional mínima'),
        (term: 'POC', desc: 'Prueba para validar viabilidad técnica'),
        (term: 'Realtime', desc: 'Actualización de datos en tiempo real'),
        (term: 'Multiplayer', desc: 'Varios usuarios conectados en la misma sala'),
        (term: 'Repository', desc: 'Capa que separa la app de los datos'),
        (term: 'Endpoint', desc: 'Punto específico de una API REST'),
        (term: 'WebSocket', desc: 'Comunicación persistente en tiempo real'),
        (term: 'UI / UX', desc: 'Interfaz visual y experiencia del usuario'),
        (term: 'SDK', desc: 'Herramientas para integrar una tecnología'),
      ];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final WalletInfo info = await widget.apiClient.wallet.getWalletInfo(
        widget.currentUser.id,
      );
      if (!mounted) return;
      setState(() => _wallet = info);
    } catch (_) {}
  }

  Future<void> _buyItemWithUsdt({
    required String title,
    required double amountUsdt,
  }) async {
    setState(() {
      _isProcessing = true;
      _feedbackMessage = null;
    });
    try {
      final PaymentRecord rec = await widget.apiClient.wallet.createPayment(
        fromUserId: widget.currentUser.id,
        toUserId: 'usr_3', // Carlos Mendoza - BlockBean Trade / Shest Coffee
        amountUsdt: amountUsdt,
        concept: 'Shest Coffee: $title',
      );
      await _loadWallet();
      widget.onTransactionComplete();
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _feedbackMessage =
            '✅ Pago confirmado (${rec.amountUsdt.toStringAsFixed(2)} USDT) • Pedido: $title';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _feedbackMessage = '⚠️ Error al procesar pago USDT: $e';
      });
    }
  }

  Future<void> _createCoffeeWholesaleEscrow() async {
    setState(() {
      _isProcessing = true;
      _feedbackMessage = null;
    });
    try {
      final EscrowOperation op = await widget.apiClient.escrow.createEscrow(
        creatorId: widget.currentUser.id,
        counterpartyId: 'usr_3',
        amount: 1850.0,
        description:
            'Lote Mayorista 100 Bolsas SHEST COFFEE 100% Arabica (12 oz / 340g)',
        conditions:
            'Liberación contra guía de despacho internacional y certificado de origen selecto.',
      );
      await _loadWallet();
      widget.onTransactionComplete();
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _feedbackMessage =
            '🛡️ Contrato Escrow #${op.id} creado por ${op.amount.toStringAsFixed(2)} USDT con BlockBean Trade (Estado: ${op.status.displayLabel}).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _feedbackMessage = '⚠️ Error al crear Escrow mayorista: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '☕ SHEST COFFEE • LOUNGE & COMERCIO B2B',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: gold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'Premium Coffee 100% Arabica • Tostado Premium • Origen Selecto (12 oz / 340g)',
                          style: TextStyle(fontSize: 11.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  if (_wallet != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E170A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gold),
                      ),
                      child: Text(
                        '💰 ${_wallet!.usdtBalance.toStringAsFixed(2)} USDT',
                        style: const TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const TabBar(
                indicatorColor: gold,
                labelColor: gold,
                unselectedLabelColor: Colors.white60,
                tabs: <Widget>[
                  Tab(text: '☕ Catálogo Shest Coffee (USDT / Escrow)'),
                  Tab(text: '📘 Glosario WordVerse (Conceptos)'),
                ],
              ),
              if (_feedbackMessage != null) ...<Widget>[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2B1B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: Text(
                    _feedbackMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _buildCatalogTab(gold),
                    _buildConceptsTab(gold),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogTab(Color gold) {
    return ListView(
      children: <Widget>[
        // Galería oficial de fotos de Shest Coffee
        SizedBox(
          height: 165,
          child: Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/shest_coffee_bags.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF1E170A),
                      alignment: Alignment.center,
                      child: const Text(
                        'SHEST COFFEE 12oz',
                        style: TextStyle(color: Colors.amberAccent),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/shest_coffee_mug.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFF1E170A),
                      alignment: Alignment.center,
                      child: const Text(
                        'SHEST MUG',
                        style: TextStyle(color: Colors.amberAccent),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildProductCard(
          gold: gold,
          title: '☕ Taza Ejecutiva SHEST COFFEE + Degustación en Sala',
          subtitle:
              'Invita un café 100% Arábica en la mesa de networking o adquiere la taza oficial con logo dorado.',
          priceText: '15.00 USDT',
          buttonLabel: 'Pagar 15 USDT',
          buttonKey: const Key('btn_buy_coffee_mug'),
          onPressed: _isProcessing
              ? null
              : () => _buyItemWithUsdt(
                  title: 'Taza Ejecutiva SHEST COFFEE + Degustación',
                  amountUsdt: 15.0,
                ),
        ),
        const SizedBox(height: 8),
        _buildProductCard(
          gold: gold,
          title: '🛍️ Bolsa SHEST COFFEE 100% Arabica (Net Wt. 12 oz / 340g)',
          subtitle:
              'Tostado Premium • Origen Selecto • Empaque negro & oro con sello cripto.',
          priceText: '28.00 USDT',
          buttonLabel: 'Comprar 28 USDT',
          buttonKey: const Key('btn_buy_coffee_bag'),
          onPressed: _isProcessing
              ? null
              : () => _buyItemWithUsdt(
                  title: 'Bolsa SHEST COFFEE 12 oz (340g)',
                  amountUsdt: 28.0,
                ),
        ),
        const SizedBox(height: 8),
        _buildProductCard(
          gold: gold,
          title: '🛡️ Lote Mayorista B2B (100 Bolsas x 340g) con Garantía Escrow',
          subtitle:
              'Operación comercial asegurada mediante Escrow Shest con Carlos Mendoza (BlockBean Trade).',
          priceText: '1,850.00 USDT (Escrow)',
          buttonLabel: 'Abrir Escrow Mayorista',
          buttonKey: const Key('btn_create_coffee_escrow'),
          onPressed: _isProcessing ? null : _createCoffeeWholesaleEscrow,
        ),
      ],
    );
  }

  Widget _buildProductCard({
    required Color gold,
    required String title,
    required String subtitle,
    required String priceText,
    required String buttonLabel,
    required Key buttonKey,
    required VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF19130A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 6),
                Text(
                  priceText,
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            key: buttonKey,
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: Colors.black,
            ),
            onPressed: onPressed,
            child: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConceptsTab(Color gold) {
    return ListView.builder(
      itemCount: _conceptos.length,
      itemBuilder: (BuildContext context, int index) {
        final ({String desc, String term}) item = _conceptos[index];
        return Card(
          color: const Color(0xFF18130B),
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: gold.withValues(alpha: 0.2),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: gold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item.term,
              style: TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              item.desc,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
