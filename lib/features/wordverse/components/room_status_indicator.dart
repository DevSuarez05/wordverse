import 'package:flutter/material.dart';
import '../../../core/theme/wordverse_tokens.dart';

enum RoomAvailabilityStatus {
  disponible,
  enVivo,
  llena,
  privadaVip,
  mantenimiento,
}

/// Indicador visual del estado de una sala (disponible, llena, VIP, etc.)
class RoomStatusIndicator extends StatelessWidget {
  const RoomStatusIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  final RoomAvailabilityStatus status;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case RoomAvailabilityStatus.disponible:
        color = WordVerseTokens.verdeEsmeralda;
        label = 'Disponible';
        break;
      case RoomAvailabilityStatus.enVivo:
        color = WordVerseTokens.cianHolografico;
        label = 'En vivo';
        break;
      case RoomAvailabilityStatus.llena:
        color = WordVerseTokens.rojoAlerta;
        label = 'Llena';
        break;
      case RoomAvailabilityStatus.privadaVip:
        color = WordVerseTokens.oroPremium;
        label = 'Privada VIP';
        break;
      case RoomAvailabilityStatus.mantenimiento:
        color = WordVerseTokens.grisTecnologico;
        label = 'En mantenimiento';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.7),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          if (showLabel) ...<Widget>[
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
