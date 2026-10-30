import 'package:flutter/material.dart';
import 'wordverse_tokens.dart';

/// Configuración de Tema ThemeData para WordVerse Nexus.
class WordVerseTheme {
  WordVerseTheme._();

  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.dark(
      primary: WordVerseTokens.oroPremium,
      onPrimary: WordVerseTokens.negroProfundo,
      secondary: WordVerseTokens.cianHolografico,
      onSecondary: WordVerseTokens.negroProfundo,
      tertiary: WordVerseTokens.purpuraNebulosa,
      onTertiary: WordVerseTokens.blancoFrio,
      surface: WordVerseTokens.negroObsidiana,
      onSurface: WordVerseTokens.blancoFrio,
      error: WordVerseTokens.rojoAlerta,
      onError: WordVerseTokens.blancoFrio,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: WordVerseTokens.negroProfundo,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color: WordVerseTokens.negroElevado,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: WordVerseTokens.borderRadiusMd,
          side: const BorderSide(color: Color(0x33D4AF37), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: WordVerseTokens.negroElevado,
        shape: RoundedRectangleBorder(
          borderRadius: WordVerseTokens.borderRadiusLg,
          side: const BorderSide(color: WordVerseTokens.oroPremium, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: WordVerseTokens.negroElevado,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: WordVerseTokens.negroObsidiana,
        foregroundColor: WordVerseTokens.oroLuminoso,
        elevation: 0,
        centerTitle: true,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x22FFFFFF),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
        border: OutlineInputBorder(
          borderRadius: WordVerseTokens.borderRadiusSm,
          borderSide: const BorderSide(color: WordVerseTokens.grisTecnologico),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: WordVerseTokens.borderRadiusSm,
          borderSide: const BorderSide(color: Color(0x44A1A6B0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: WordVerseTokens.borderRadiusSm,
          borderSide: const BorderSide(color: WordVerseTokens.oroLuminoso, width: 2),
        ),
        labelStyle: const TextStyle(color: WordVerseTokens.grisTecnologico),
        hintStyle: const TextStyle(color: Color(0x88A1A6B0)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: WordVerseTokens.blancoFrio,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          color: WordVerseTokens.oroLuminoso,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        titleLarge: TextStyle(
          color: WordVerseTokens.blancoFrio,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: WordVerseTokens.oroPremium,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: WordVerseTokens.blancoFrio,
        ),
        bodyMedium: TextStyle(
          color: WordVerseTokens.grisTecnologico,
        ),
        labelLarge: TextStyle(
          color: WordVerseTokens.blancoFrio,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
