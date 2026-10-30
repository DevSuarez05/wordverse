# 🌐 WordVerse — Cliente 3D Inmersivo para Shest Labs

Para la documentación completa de arquitectura, instalación, variables de entorno, APIs, IA, P2P, restricciones regulatorias de Escrow y plan de despliegue, consulta el archivo principal en la raíz:
👉 [**README.md del Proyecto**](../../README.md)

---

## Estructura Rápida de Directorios (`/lib`)

```text
lib/
 ├── main.dart
 ├── core/
 │    ├── api_client/                     # Capa de integración hexagonal (ShestApiClient)
 │    │    ├── shest_api_client.dart      # Interface única de servicios
 │    │    ├── http_shest_api.dart        # Implementación REST Spring Boot & PostgREST con JWT 401 refresh
 │    │    └── mock_shest_api.dart        # Sandbox local determinista en memoria
 │    ├── config/
 │    │    └── wordverse_env_config.dart  # Variables de entorno y enmascaramiento de secretos
 │    ├── events/
 │    │    └── wordverse_events.dart      # Event bus reactivo tipado (16 eventos)
 │    ├── models/
 │    │    └── shest_models.dart          # DTOs y entidades de dominio (User, Wallet, Escrow, P2P)
 │    ├── services/
 │    │    └── wordverse_translation_service.dart # Servicio IA multilingüe con rate limit y sanitización PII
 │    └── theme/
 │         ├── wordverse_tokens.dart      # Paleta oficial (Obsidiana, Oro, Cian, Púrpura, Verde)
 │         └── wordverse_theme.dart       # ThemeData corporativo para Flutter
 └── features/
      └── wordverse/
           ├── 3d_room/
           │    ├── hub3d/                # Puente bidireccional Flutter <-> Three.js (postMessage)
           │    ├── room_3d_viewport.dart # Visor 3D y fallback 2.5D
           │    └── wordverse_module_screen.dart # Pantalla principal con HUD dorado
           ├── meetings/
           │    ├── escrow_sheet.dart     # Centro de arbitraje Escrow B2B
           │    ├── networking_chat_sheet.dart # Chat bilingüe con traducción IA
           │    ├── p2p_wallet_sheet.dart # Billetera USDT y mercado P2P
           │    └── private_suites_screen.dart # Catálogo de salas privadas VIP
           ├── public_hub/
           │    └── public_hub_screen.dart # Catálogo de salas públicas
           └── multiplayer/
                └── multiplayer_service.dart # Sincronización de presencia multiusuario
```

## Verificación de Compilaciones y Pruebas
```bash
# Pruebas automatizadas (53/53 passed)
flutter test

# Análisis estático (0 issues)
flutter analyze

# Compilación Web para producción
flutter build web --no-pub
```
