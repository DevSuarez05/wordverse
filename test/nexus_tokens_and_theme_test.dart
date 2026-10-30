import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordverse/core/theme/wordverse_theme.dart';
import 'package:wordverse/core/theme/wordverse_tokens.dart';

void main() {
  group('WordVerse Nexus Design Tokens — Master Prompt V2', () {
    test('Paleta oficial PREMION / NEXUS tiene los valores hexadecimales exactos', () {
      expect(WordVerseTokens.negroObsidiana, const Color(0xFF0A0A0C));
      expect(WordVerseTokens.negroProfundo, const Color(0xFF050505));
      expect(WordVerseTokens.negroElevado, const Color(0xFF16161E));
      expect(WordVerseTokens.oroPremium, const Color(0xFFD4AF37));
      expect(WordVerseTokens.oroLuminoso, const Color(0xFFFFD978));
      expect(WordVerseTokens.oroOscuro, const Color(0xFF8C6422));
      expect(WordVerseTokens.cianHolografico, const Color(0xFF00F0FF));
      expect(WordVerseTokens.purpuraNebulosa, const Color(0xFF7B2CBF));
      expect(WordVerseTokens.verdeEsmeralda, const Color(0xFF00FF87));
      expect(WordVerseTokens.blancoFrio, const Color(0xFFF5F7FA));
      expect(WordVerseTokens.grisTecnologico, const Color(0xFFA1A6B0));
      expect(WordVerseTokens.rojoAlerta, const Color(0xFFFF4D4F));
    });

    test('Tema ThemeData aplica fondos negros, primario oro y contraste cian', () {
      final ThemeData theme = WordVerseTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, WordVerseTokens.negroProfundo);
      expect(theme.colorScheme.primary, WordVerseTokens.oroPremium);
      expect(theme.colorScheme.secondary, WordVerseTokens.cianHolografico);
      expect(theme.colorScheme.surface, WordVerseTokens.negroObsidiana);
      expect(theme.cardTheme.color, WordVerseTokens.negroElevado);
    });
  });
}
