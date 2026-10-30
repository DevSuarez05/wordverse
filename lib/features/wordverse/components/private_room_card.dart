import 'package:flutter/material.dart';
import '../../../core/theme/wordverse_tokens.dart';
import '../models/private_room.dart';
import 'wordverse_buttons.dart';

/// Tarjeta exclusiva para mostrar suites privadas en WordVerse Private Suites.
class PrivateRoomCard extends StatelessWidget {
  const PrivateRoomCard({
    super.key,
    required this.room,
    required this.onAccess,
    this.isLoading = false,
  });

  final PrivateRoom room;
  final VoidCallback onAccess;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isHost = room.isOwner;

    return Container(
      decoration: BoxDecoration(
        color: WordVerseTokens.negroElevado,
        borderRadius: WordVerseTokens.borderRadiusMd,
        border: Border.all(
          color: WordVerseTokens.oroPremium.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x44D4AF37),
            blurRadius: 10,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header: Tag VIP y Candado
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: WordVerseTokens.gradienteOro,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isHost ? 'ANFITRIÓN (TÚ)' : 'SUITE PRIVADA VIP',
                  style: const TextStyle(
                    color: WordVerseTokens.negroProfundo,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                room.isEncrypted ? Icons.lock_outline : Icons.lock_open,
                size: 16,
                color: WordVerseTokens.oroLuminoso,
              ),
              const SizedBox(width: 4),
              const Text(
                'E2EE ENCRYPTED',
                style: TextStyle(
                  color: WordVerseTokens.oroLuminoso,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Título de la Suite
          Text(
            room.name,
            style: const TextStyle(
              color: WordVerseTokens.blancoFrio,
              fontSize: 16,
              fontWeight: FontWeight.w800,
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
          const SizedBox(height: 12),
          const Divider(color: Color(0x22FFFFFF)),
          const SizedBox(height: 6),

          // Footer: Propietario, Capacidad y Botón
          Row(
            children: <Widget>[
              const Icon(Icons.stars, size: 16, color: WordVerseTokens.oroPremium),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  room.ownerName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WordVerseTokens.oroLuminoso,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.people_alt_outlined, size: 15, color: WordVerseTokens.grisTecnologico),
                    const SizedBox(width: 4),
                    Text(
                      '${room.participantCount}/${room.maxCapacity}',
                      style: const TextStyle(
                        color: WordVerseTokens.blancoFrio,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              WordVersePrimaryButton(
                label: isHost ? 'INGRESAR' : 'DESBLOQUEAR',
                icon: isHost ? Icons.meeting_room : Icons.vpn_key,
                style: WordVerseButtonStyle.gold,
                isLoading: isLoading,
                onPressed: onAccess,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
