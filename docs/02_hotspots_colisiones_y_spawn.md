# 02 — Hotspots, Colisiones y Spawn (Especificación Espacial 3D de WordVerse)

Documento técnico de referencia espacial para la escena [`assets/models/01_sala_principal.glb`](../assets/models/01_sala_principal.glb), sincronizado con [`RoomPhysicsController`](../lib/features/wordverse/movement/room_physics_controller.dart) y [`HotspotKind`](../lib/core/models/shest_models.dart).

---

## 1. Sistema de Coordenadas Normalizadas de la Sala 3D
- **Origen $(0.00, 0.00, 0.00)$:** Centro exacto de la Sala Principal (Mesa Octogonal de Negocios).
- **Eje $X \in [-0.82, +0.82]$:** Izquierda ($-$) a Derecha ($+$).
- **Eje $Y \in [0.00, +0.38]$:** Altura vertical sobre el nivel del piso ($0.00$).
- **Eje $Z \in [-0.82, +0.82]$:** Fondo Norte ($-$) hacia Frente Sur ($+$).

---

## 2. Punto Oficial de Spawn (Fase 2 y Fase 6)
Al autenticarse con la sesión de Shest Labs o al cambiar de sub-sala, el avatar local aparece en:
- **`spawnX`:** `0.00`
- **`spawnY`:** `0.00`
- **`spawnZ`:** `+0.42` (Frente a la mesa central de negocios, mirando hacia el centro de la sala).

---

## 3. Zonas de Colisión (Fase 2 y Fase 6)

| Obstáculo / Límite | Geometría de Colisión | Parámetros Exactos |
| :--- | :--- | :--- |
| **Muros Perimetrales (Norte, Sur, Este, Oeste)** | Caja AABB (`minBound` / `maxBound`) | $X \in [-0.82, +0.82]$, $Z \in [-0.82, +0.82]$ |
| **Mesa Central de Negocios y Reuniones** | Cilindro Central $(0.00, 0.00)$ | Radio `centerTableRadius = 0.19` |
| **4 Columnas Arquitectónicas** | Pilares en esquinas perimetrales | $(\pm 0.76, \pm 0.76)$, ancho $0.10$, altura $0.38$ |

---

## 4. Los 7 Hotspots Oficiales de la Sala (Fase 27)

Radio de activación automática por proximidad al caminar: **`hotspotTriggerRadius = 0.18`**.

| Código | Nombre del Hotspot | Coordenada $X$ | Coordenada $Z$ | Acción / Módulo Conectado |
| :--- | :--- | :---: | :---: | :--- |
| **`HOTSPOT 01`** | **Networking** | `-0.60` | `-0.45` | Abre Directorio de Usuarios, Búsqueda, Favoritos ⭐ y Chat (`NetworkingAndChatSheet`) |
| **`HOTSPOT 02`** | **Crear reunión** | `0.00` | `-0.65` | Abre formulario de Reuniones (`Networking`, `Negocios`, `P2P`, `Café`, `Privada`) y código `WV-45821` |
| **`HOTSPOT 03`** | **QR** | `+0.60` | `-0.45` | Abre Centro de Validación QR (`WV-45821`, `#45821`) y Tarjeta Digital con QR Personal |
| **`HOTSPOT 04`** | **P2P** | `-0.68` | `+0.20` | Abre Mercado P2P de Shest, Wallet USDT TRC20 y Pagos (`P2PAndWalletSheet`) |
| **`HOTSPOT 05`** | **ESCROW** | `+0.68` | `+0.20` | Abre Centro de Escrow (`ESCROW #45821 PENDIENTE`), estados y QR de Escrow (`EscrowCenterSheet`) |
| **`HOTSPOT 06`** | **Mi perfil** | `-0.45` | `+0.68` | Muestra Tarjeta Digital y QR Personal de Shest |
| **`HOTSPOT 07`** | **Salir** | `+0.45` | `+0.68` | Emite `USER_LEFT_ROOM` y regresa a la puerta de sesión de Shest Labs |
