import 'package:flutter/material.dart';
import '../../../core/theme/wordverse_tokens.dart';
import 'wordverse_buttons.dart';

/// Vista de Carga Futurista con estética Nexus.
class WordVerseLoadingView extends StatelessWidget {
  const WordVerseLoadingView({
    super.key,
    this.message = 'Conectando con la matriz 3D...',
    this.subMessage = 'Cargando shaders, audio y geometría espacial',
  });

  final String message;
  final String subMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: WordVerseTokens.glowCian,
                  ),
                ),
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      WordVerseTokens.cianHolografico,
                    ),
                  ),
                ),
                const Icon(
                  Icons.vpn_key_outlined,
                  color: WordVerseTokens.oroPremium,
                  size: 26,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WordVerseTokens.blancoFrio,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WordVerseTokens.grisTecnologico,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de Acceso Denegado / Permisos insuficientes.
class WordVerseAccessDeniedView extends StatelessWidget {
  const WordVerseAccessDeniedView({
    super.key,
    required this.reason,
    required this.onBack,
    this.onRequestAccess,
  });

  final String reason;
  final VoidCallback onBack;
  final VoidCallback? onRequestAccess;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: WordVerseTokens.negroElevado,
          borderRadius: WordVerseTokens.borderRadiusLg,
          border: Border.all(color: WordVerseTokens.rojoAlerta.withValues(alpha: 0.5), width: 1.5),
          boxShadow: WordVerseTokens.sombraElevada,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WordVerseTokens.rojoAlerta.withValues(alpha: 0.12),
                border: Border.all(color: WordVerseTokens.rojoAlerta),
              ),
              child: const Icon(Icons.shield_outlined, color: WordVerseTokens.rojoAlerta, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'ACCESO RESTRINGIDO',
              style: TextStyle(
                color: WordVerseTokens.rojoAlerta,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WordVerseTokens.blancoFrio,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: WordVersePrimaryButton(
                    label: 'VOLVER AL HUB',
                    style: WordVerseButtonStyle.ghost,
                    onPressed: onBack,
                  ),
                ),
                if (onRequestAccess != null) ...<Widget>[
                  const SizedBox(width: 12),
                  Expanded(
                    child: WordVersePrimaryButton(
                      label: 'SOLICITAR INVITACIÓN',
                      style: WordVerseButtonStyle.gold,
                      onPressed: onRequestAccess,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
