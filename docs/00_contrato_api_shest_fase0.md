# 00 — Contrato de API e Integración con Shest Labs (Fase 0 y Fase 1)

**Destinatario:** Equipo de Backend Java (Spring Boot) — Shest Labs  
**Módulo Cliente:** WordVerse 3D (Flutter) — [`ShestApiClient`](../lib/core/api_client/shest_api_client.dart)  
**URL Base Productiva Esperada:** `https://api.shestlabs.com/v1`

---

## 1. Regla Arquitectónica Fundamental
WordVerse **NO** almacena ni decide lógica financiera (fondos, validación de pagos, custodia de USDT TRC20, liberación de Escrows ni ejecución de órdenes P2P). Todas las operaciones son solicitadas mediante HTTP REST con cabecera `Authorization: Bearer <SHEST_JWT_TOKEN>` hacia el backend en Java Spring Boot de Shest Labs.

---

## 2. Checklist de Endpoints Requeridos (Fase 0)

### 2.1 Autenticación y Usuarios (`ShestAuthService`)

| Operación | Método y Ruta | Request JSON | Response JSON Esperado |
| :--- | :--- | :--- | :--- |
| **Obtener perfil de sesión actual** | `GET /users/me?userId={id}` | — | `{"id":"usr_1","nombre":"Daniel","empresa":"Shest Partner","cargo":"Director","descripcion":"...","avatar":"DN","avatar_color":4278248959,"estado":"AVAILABLE","es_favorito":false,"conectado":true}` |
| **Refrescar Token JWT** | `POST /auth/refresh` | `{"refreshToken":"..."}` | `{"accessToken":"...","refreshToken":"...","expiresAt":"2026-10-21T12:00:00Z"}` |
| **Buscar usuarios (Nombre / Empresa)** | `GET /users/search?q={texto}` | — | `[ { ...objeto usuario... } ]` |
| **Cambiar estado de presencia** | `PATCH /users/{id}/status` | `{"status":"AVAILABLE \| BUSY \| UNAVAILABLE"}` | `{ ...objeto usuario actualizado... }` |
| **Marcar / Desmarcar Favorito ⭐** | `POST /users/{targetId}/favorite` | `{"targetUserId":"usr_2"}` | `{ ...objeto usuario actualizado... }` |
| **Enviar / Aceptar Conexión Networking** | `POST /networking/connect` | `{"targetUserId":"usr_2"}` | `{ ...objeto usuario con "conectado": true... }` |

---

### 2.2 Wallet USDT TRC20 y Pagos (`ShestWalletService`)

| Operación | Método y Ruta | Request JSON | Response JSON Esperado |
| :--- | :--- | :--- | :--- |
| **Consultar Balance y Dirección TRC20** | `GET /wallet/{userId}/balance` | — | `{"user_id":"usr_1","balance_usdt":12500.00,"trc20_address":"TShest...TRC20","recentTransactions":["..."]}` |
| **Ejecutar Pago Directo** | `POST /payments/create` | `{"fromUserId":"usr_1","toUserId":"usr_2","amountUsdt":250.00,"concept":"Consultoría"}` | `{"id":"PAY-1001","status":"CONFIRMED","timestamp":"..."}` (o `HTTP 400 INSUFFICIENT_FUNDS`) |
| **Historial de Pagos** | `GET /payments/{userId}/history` | — | `[ { ...registro de pago... } ]` |

---

### 2.3 Mercado P2P (`ShestP2PService`)

| Operación | Método y Ruta | Request JSON | Response JSON Esperado |
| :--- | :--- | :--- | :--- |
| **Listar Órdenes P2P Activas** | `GET /p2p/orders` | — | `[{"id":"P2P-901","makerId":"usr_2","makerName":"Valeria","amountUsdt":2500.0,"rateUsd":1.001,"paymentMethod":"Wire","status":"OPEN"}]` |
| **Crear Orden P2P** | `POST /p2p/orders` | `{"makerId":"usr_1","amountUsdt":1000.0,"rateUsd":1.00,"paymentMethod":"Transferencia"}` | `{ ...orden creada... }` |
| **Aceptar / Tomar Orden P2P** | `POST /p2p/orders/{id}/accept` | `{"takerId":"usr_1"}` | `{ ...orden con "status":"COMPLETED"... }` |
| **Cancelar Orden P2P** | `POST /p2p/orders/{id}/cancel` | `{}` | `{ ...orden con "status":"CANCELLED"... }` |

---

### 2.4 Escrow de Negocios (`ShestEscrowService` — Fases 19 a 24)

**Estados Oficiales Soportados (Fase 22):**
`PENDING`, `FUNDED`, `IN_PROGRESS`, `RELEASE_REQUESTED`, `RELEASED`, `DISPUTED`, `CANCELLED`, `COMPLETED`.

| Operación | Método y Ruta | Request JSON | Response JSON Esperado |
| :--- | :--- | :--- | :--- |
| **Listar Escrows del Usuario** | `GET /escrows?userId={id}` | — | `[ { ...objeto escrow... } ]` |
| **Crear Operación Escrow** | `POST /escrows` | `{"creatorId":"usr_1","counterpartyId":"usr_2","amount":1500.0,"currency":"USDT","description":"...","conditions":"..."}` | `{"id":"45821","creador_id":"usr_1","contraparte_id":"usr_2","monto":1500.0,"moneda":"USDT","estado":"PENDING","created_at":"..."}` |
| **Transicionar Estado de Escrow** | `PATCH /escrows/{id}/state` | `{"actorUserId":"usr_1","targetStatus":"FUNDED \| IN_PROGRESS \| RELEASE_REQUESTED \| RELEASED \| DISPUTED \| CANCELLED \| COMPLETED"}` | `{ ...escrow actualizado tras validar permisos y fondos en Java... }` |

---

### 2.5 Reuniones (`WV-45821`) y Sistema QR (`ShestQrService` — Fases 9 a 11, 24, 28)

| Operación | Método y Ruta | Request JSON | Response JSON Esperado |
| :--- | :--- | :--- | :--- |
| **Crear Reunión** | `POST /meetings` | `{"creatorId":"usr_1","name":"Mesa OTC","type":"Negocios","description":"...","isPrivate":false,"durationMinutes":45}` | `{"id":"mtg_1","codigo":"WV-45821","nombre":"Mesa OTC","tipo":"Negocios","es_privada":false,"creador":"usr_1"}` |
| **Listar Reuniones Activas** | `GET /meetings` | — | `[ { ...objeto reunión... } ]` |
| **Validar Código QR / Invitación** | `POST /qr/validate` | `{"qrOrCode":"WV-45821 \| SHEST-ESCROW:45821 \| SHEST-USER:usr_2","scannerUserId":"usr_1"}` | `{"kind":"MEETING \| ESCROW \| USER","message":"Acceso autorizado..."}` |

---

### 2.6 Eventos Realtime / WebSocket (`WordverseMultiplayerService` — Fases 7 y 32)

Canal WebSocket para sincronizar posición y presencia en la Sala 3D:
- **`USER_JOINED_ROOM`:** `{"event":"USER_JOINED_ROOM","userId":"usr_1","room":"Sala Principal","x":0.0,"z":0.42}`
- **`AVATAR_MOVED`:** `{"event":"AVATAR_MOVED","userId":"usr_1","x":0.15,"z":-0.10,"rot":1.57}`
- **`USER_LEFT_ROOM`:** `{"event":"USER_LEFT_ROOM","userId":"usr_1","room":"Sala Principal"}`
