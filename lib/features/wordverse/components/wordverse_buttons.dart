import 'package:flutter/material.dart';
import '../../../core/theme/wordverse_tokens.dart';

enum WordVerseButtonStyle { gold, cyan, purple, ghost }

/// Botón principal premium con estilo visual WordVerse Nexus.
class WordVersePrimaryButton extends StatelessWidget {
  const WordVersePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = WordVerseButtonStyle.gold,
    this.isLoading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WordVerseButtonStyle style;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    Color bgGradientStart;
    Color bgGradientEnd;
    Color textColor;
    List<BoxShadow> glow;

    switch (style) {
      case WordVerseButtonStyle.gold:
        bgGradientStart = WordVerseTokens.oroLuminoso;
        bgGradientEnd = WordVerseTokens.oroOscuro;
        textColor = WordVerseTokens.negroProfundo;
        glow = WordVerseTokens.glowOro;
        break;
      case WordVerseButtonStyle.cyan:
        bgGradientStart = WordVerseTokens.cianHolografico;
        bgGradientEnd = const Color(0xFF0077B6);
        textColor = WordVerseTokens.negroProfundo;
        glow = WordVerseTokens.glowCian;
        break;
      case WordVerseButtonStyle.purple:
        bgGradientStart = const Color(0xFF9D4EDD);
        bgGradientEnd = WordVerseTokens.purpuraNebulosa;
        textColor = WordVerseTokens.blancoFrio;
        glow = WordVerseTokens.glowPurpura;
        break;
      case WordVerseButtonStyle.ghost:
        bgGradientStart = const Color(0x33FFFFFF);
        bgGradientEnd = const Color(0x11FFFFFF);
        textColor = WordVerseTokens.blancoFrio;
        glow = const <BoxShadow>[];
        break;
    }

    final Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading) ...<Widget>[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...<Widget>[
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            fontSize: 13,
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: WordVerseTokens.borderRadiusSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[bgGradientStart, bgGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: WordVerseTokens.borderRadiusSm,
            boxShadow: onPressed != null ? glow : null,
            border: Border.all(
              color: style == WordVerseButtonStyle.ghost
                  ? WordVerseTokens.grisTecnologico.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
