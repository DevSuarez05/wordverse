import 'package:flutter/material.dart';

import '../../../core/events/wordverse_events.dart';

/// Centro de Notificaciones y Monitor de Eventos Internos (Fases 31 y 32).
/// Muestra alertas de:
/// - Nueva conexión / Solicitud
/// - Invitación a reunión (`WV-45821`)
/// - Mensaje de chat
/// - Operaciones de Escrow (`#45821`), P2P y Pagos
class WordverseNotificationsSheet extends StatelessWidget {
  const WordverseNotificationsSheet({
    super.key,
    required this.eventBus,
    required this.onSimulateErrorTest,
  });

  final WordverseEventBus eventBus;
  final VoidCallback onSimulateErrorTest;

  static Future<void> show({
    required BuildContext context,
    required WordverseEventBus eventBus,
    required VoidCallback onSimulateErrorTest,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return WordverseNotificationsSheet(
          eventBus: eventBus,
          onSimulateErrorTest: onSimulateErrorTest,
        );
      },
    );
  }

  IconData _iconForEvent(WordverseEventType type) {
    switch (type) {
      case WordverseEventType.userJoinedRoom:
      case WordverseEventType.userLeftRoom:
      case WordverseEventType.avatarMoved:
      case WordverseEventType.avatarSelected:
        return Icons.person_pin_circle;
      case WordverseEventType.createMeeting:
      case WordverseEventType.joinMeeting:
      case WordverseEventType.qrScanned:
        return Icons.qr_code_2;
      case WordverseEventType.connectionRequest:
      case WordverseEventType.connectionAccepted:
        return Icons.handshake;
      case WordverseEventType.chatOpened:
        return Icons.chat_bubble_outline;
      case WordverseEventType.p2pOpened:
        return Icons.currency_exchange;
      case WordverseEventType.escrowCreated:
      case WordverseEventType.escrowUpdated:
      case WordverseEventType.escrowCompleted:
        return Icons.verified_user;
      case WordverseEventType.paymentRequest:
      case WordverseEventType.paymentCompleted:
        return Icons.account_balance_wallet;
    }
  }

  Color _colorForEvent(WordverseEventType type) {
    switch (type) {
      case WordverseEventType.escrowCreated:
      case WordverseEventType.escrowUpdated:
      case WordverseEventType.escrowCompleted:
        return const Color(0xFFFFD740);
      case WordverseEventType.paymentRequest:
      case WordverseEventType.paymentCompleted:
      case WordverseEventType.p2pOpened:
        return Colors.greenAccent;
      case WordverseEventType.connectionRequest:
      case WordverseEventType.connectionAccepted:
        return Colors.cyanAccent;
      case WordverseEventType.createMeeting:
      case WordverseEventType.joinMeeting:
      case WordverseEventType.qrScanned:
        return Colors.purpleAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<WordverseEvent> history = eventBus.history;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Expanded(
                  child: Text(
                    '🔔 NOTIFICACIONES SHEST & EVENTOS (Fases 31-34)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const Key('btn_simulate_offline_toggle'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSimulateErrorTest();
                  },
                  icon: const Icon(
                    Icons.wifi_off,
                    size: 15,
                    color: Colors.orangeAccent,
                  ),
                  label: const Text(
                    'Probar Caída Red (Fase 34)',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const Text(
              'Registro en tiempo real de los 16 tipos de eventos internos y alertas financieras de Shest:',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: history.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin notificaciones recientes.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (BuildContext context, int index) {
                        final WordverseEvent ev = history[index];
                        final Color color = _colorForEvent(ev.type);
                        final String timeStr =
                            '${ev.timestamp.hour.toString().padLeft(2, '0')}:'
                            '${ev.timestamp.minute.toString().padLeft(2, '0')}:'
                            '${ev.timestamp.second.toString().padLeft(2, '0')}';

                        return Card(
                          color: const Color(0xFF16223A),
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              _iconForEvent(ev.type),
                              color: color,
                              size: 20,
                            ),
                            title: Text(
                              ev.summary,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${ev.type.code} • $timeStr',
                              style: TextStyle(
                                color: color.withValues(alpha: 0.85),
                                fontSize: 10.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
