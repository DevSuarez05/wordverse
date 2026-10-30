import 'package:flutter/material.dart';
import '../../../core/theme/wordverse_tokens.dart';
import '../models/public_room.dart';
import 'room_status_indicator.dart';
import 'wordverse_buttons.dart';

/// Tarjeta moderna para mostrar salas públicas en el catálogo WordVerse Public Hub.
class PublicRoomCard extends StatelessWidget {
  const PublicRoomCard({
    super.key,
    required this.room,
    required this.onEnter,
    this.isLoading = false,
  });

  final PublicRoom room;
  final VoidCallback onEnter;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: WordVerseTokens.negroElevado,
        borderRadius: WordVerseTokens.borderRadiusMd,
        border: Border.all(
          color: WordVerseTokens.cianHolografico.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Fila superior: Categoría, Estado y Ocupación
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WordVerseTokens.cianHolografico.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: WordVerseTokens.cianHolografico.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  room.category.toUpperCase(),
                  style: const TextStyle(
                    color: WordVerseTokens.cianHolografico,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              RoomStatusIndicator(status: room.status),
            ],
          ),
          const SizedBox(height: 12),

          // Título de la Sala
          Text(
            room.name,
            style: const TextStyle(
              color: WordVerseTokens.blancoFrio,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),

          // Descripción
          Text(
            room.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WordVerseTokens.grisTecnologico,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Tags
          if (room.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: room.tags.map((String tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: WordVerseTokens.grisTecnologico,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x1AFFFFFF)),
          const SizedBox(height: 6),

          // Footer: Host, Ocupación y Botón Entrar
          Row(
            children: <Widget>[
              Icon(Icons.person_pin_outlined, size: 16, color: WordVerseTokens.oroPremium),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  room.host,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WordVerseTokens.blancoFrio,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.groups_outlined, size: 16, color: WordVerseTokens.cianHolografico),
                    const SizedBox(width: 4),
                    Text(
                      '${room.participantCount}/${room.maxCapacity}',
                      style: const TextStyle(
                        color: WordVerseTokens.cianHolografico,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              WordVersePrimaryButton(
                label: 'ENTRAR',
                icon: Icons.login,
                style: WordVerseButtonStyle.cyan,
                isLoading: isLoading,
                onPressed: room.canEnter ? onEnter : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
