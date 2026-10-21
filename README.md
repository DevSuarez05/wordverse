# WordVerse — Módulo 3D para Shest Labs (Nivel 1+)

Espacio virtual 3D de reuniones, networking y negocios integrado directamente dentro del ecosistema **Shest Labs**.

## Regla de Oro (NO Duplicar Shest)
WordVerse **NO** posee wallet propia, motor P2P propio ni sistema de pagos independiente. Todo lo financiero (`Auth`, `Wallet USDT TRC20`, `P2P`, `Escrow`, `Pagos`, `QR`) se consume a través de [`ShestApiClient`](lib/core/api_client/shest_api_client.dart).

## Estructura del Proyecto (`/lib`)

```text
lib/
 ├── main.dart
 ├── core/
 │    ├── models/
 │    │    └── shest_models.dart          # Entidades compartidas (User, Wallet, Escrow, Meeting, P2P)
 │    ├── events/
 │    │    └── wordverse_events.dart      # Bus reactivo con los 16 eventos internos (Fase 32)
 │    ├── api_client/                     # Capa de integración con Shest Labs (Fase 1)
 │    │    ├── shest_api_client.dart      # Punto único de cambio (Mock -> Supabase -> api.shestlabs.com)
 │    │    ├── auth_service.dart          # Sesión, perfil, búsqueda, favoritos y conexiones
 │    │    ├── wallet_service.dart        # Balance USDT TRC20 y pagos validados por Shest
 │    │    ├── p2p_service.dart           # Órdenes P2P de Shest
 │    │    ├── escrow_service.dart        # Creación y estados reales de Escrow (#45821)
 │    │    └── qr_service.dart            # Reuniones (WV-45821) y validación de QR
 │    └── mocks/
 │         └── mock_shest_api.dart        # Simulador completo del backend Java Spring Boot de Shest
 └── features/
      └── wordverse/
           ├── 3d_room/
           │    ├── glb_inspector.dart            # Auditoría e inspección binaria del .GLB (Fase 3)
           │    ├── room_3d_viewport.dart         # Escena 3D interactiva, 7 Hotspots y Avatares
           │    └── wordverse_module_screen.dart  # HUD principal, cámara, emotes y reconexión
           ├── avatar/
           │    └── avatar_node.dart              # Nodo espacial, estado de presencia y emote activo
           ├── movement/
           │    └── room_physics_controller.dart  # Spawn, colisiones y proximidad a Hotspots (Fase 6)
           ├── multiplayer/
           │    └── multiplayer_service.dart      # Sincronización USER_JOINED_ROOM / AVATAR_MOVED (Fase 7)
           └── meetings/
                ├── meetings_qr_modals.dart       # Crear reunión (WV-45821) y Centro QR (Fases 9-11)
                └── escrow_p2p_modals.dart        # Perfil 3D, Networking, Chat, P2P y Escrow #45821
```

## Checklist de Endpoints Requeridos de Shest Backend (Java Spring Boot)
1. **Auth & Usuarios**: `GET /v1/users/me`, `GET /v1/users/search`, `POST /v1/networking/connect`, `PATCH /v1/users/status`
2. **Wallet & Pagos**: `GET /v1/wallet/balance`, `POST /v1/payments/create`
3. **P2P**: `GET /v1/p2p/orders`, `POST /v1/p2p/orders`, `POST /v1/p2p/orders/{id}/accept`
4. **Escrow**: `GET /v1/escrows`, `POST /v1/escrows`, `PATCH /v1/escrows/{id}/state`
5. **Reuniones & QR**: `POST /v1/meetings`, `POST /v1/qr/validate`
