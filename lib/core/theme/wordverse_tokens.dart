import 'package:flutter/material.dart';

/// Tokens oficiales de diseño para WordVerse Nexus / PREMION.
/// Centraliza la paleta aprobada, elevaciones, bordes y tipografía.
abstract final class WordVerseTokens {
  // --- PALETA OFICIAL PREMION / NEXUS ---
  /// Fondo principal y paneles primarios (#0A0A0C)
  static const Color negroObsidiana = Color(0xFF0A0A0C);

  /// Fondo profundo de la escena y viewport (#050505)
  static const Color negroProfundo = Color(0xFF050505);

  /// Superficie elevada para tarjetas y modales (#16161E)
  static const Color negroElevado = Color(0xFF16161E);

  /// Acento de lujo, identidad corporativa y elementos VIP (#D4AF37)
  static const Color oroPremium = Color(0xFFD4AF37);

  /// Destellos, bordes activos y estados hover/foco (#FFD978)
  static const Color oroLuminoso = Color(0xFFFFD978);

  /// Sombras doradas, bordes sutiles y contraste (#8C6422)
  static const Color oroOscuro = Color(0xFF8C6422);

  /// Navegación pública, teleports, hologramas y tecnología (#00F0FF)
  static const Color cianHolografico = Color(0xFF00F0FF);

  /// Acentos secundarios, suites ejecutivas y misterio (#7B2CBF)
  static const Color purpuraNebulosa = Color(0xFF7B2CBF);

  /// Estados activos, transacciones P2P exitosas y presencia (#00FF87)
  static const Color verdeEsmeralda = Color(0xFF00FF87);

  /// Textos primarios y títulos (#F5F7FA)
  static const Color blancoFrio = Color(0xFFF5F7FA);

  /// Textos secundarios, metadatos y bordes inactivos (#A1A6B0)
  static const Color grisTecnologico = Color(0xFFA1A6B0);

  /// Advertencias, salas llenas o errores (#FF4D4F)
  static const Color rojoAlerta = Color(0xFFFF4D4F);

  // --- GRADIENTES ---
  static const LinearGradient gradienteOro = LinearGradient(
    colors: <Color>[oroLuminoso, oroPremium, oroOscuro],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradienteCian = LinearGradient(
    colors: <Color>[cianHolografico, Color(0xFF0077B6), purpuraNebulosa],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientePurpura = LinearGradient(
    colors: <Color>[Color(0xFF9D4EDD), purpuraNebulosa, Color(0xFF3C096C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradienteObsidiana = LinearGradient(
    colors: <Color>[Color(0xFF181822), negroObsidiana, negroProfundo],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- BORDES Y RADIOS ---
  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);

  // --- SOMBRAS Y RESPLANDOR (GLOW) ---
  static const List<BoxShadow> glowOro = <BoxShadow>[
    BoxShadow(
      color: Color(0x66D4AF37),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> glowCian = <BoxShadow>[
    BoxShadow(
      color: Color(0x6600F0FF),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> glowPurpura = <BoxShadow>[
    BoxShadow(
      color: Color(0x667B2CBF),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> sombraElevada = <BoxShadow>[
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
