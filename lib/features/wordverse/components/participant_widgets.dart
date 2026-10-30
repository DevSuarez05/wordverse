import 'package:flutter/material.dart';
import '../../../core/theme/wordverse_tokens.dart';

/// Avatar circular estilizado para participantes en WordVerse.
class ParticipantAvatar extends StatelessWidget {
  const ParticipantAvatar({
    super.key,
    required this.name,
    this.role,
    this.isOnline = true,
    this.avatarColor,
    this.radius = 18.0,
  });

  final String name;
  final String? role;
  final bool isOnline;
  final Color? avatarColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final String initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final Color baseColor = avatarColor ?? WordVerseTokens.oroPremium;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        CircleAvatar(
          radius: radius,
          backgroundColor: baseColor.withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: baseColor, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: baseColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.9,
              ),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: WordVerseTokens.verdeEsmeralda,
                shape: BoxShape.circle,
                border: Border.all(color: WordVerseTokens.negroProfundo, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
