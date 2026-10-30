# 📋 WORDVERSE — BACKLOG Y MATRIZ DE TAREAS (`TASKS.md`)

**Estados permitidos:** `BACKLOG` | `READY` | `IN_PROGRESS` | `BLOCKED` | `IN_REVIEW` | `DONE`  
**Regla de Auditoría:** Ninguna tarea se marca como `DONE` sin evidencia verificable en el repositorio (archivos implementados + pruebas ejecutadas).

---

## Fase 0: Auditoría

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia Verificada |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-001`** | E0.1 | Auditar arquitectura real Frontend (Flutter + Three.js `hub3d`), Backend (`ShestApiClient`) y SQL (`supabase_schema.sql`) | `P0` | 1.5h | — | `DONE` | Inspección completa de `lib/`, `web/hub3d/` y `supabase_schema.sql` |
| **`WV-001.1`** | E0.1 | Confirmar tecnologías y versiones (`Flutter 3.47.5`, `Dart 3.13.4`, `Three.js r160`, paquetes `pubspec.yaml`) | `P0` | 0.5h | `WV-001` | `DONE` | `src/wordverse/pubspec.yaml`, `web/hub3d/index.html` |
| **`WV-001.2`** | E0.1 | Analizar requerimientos del cliente y verificar existencia de archivos de audio en el repositorio | `P0` | 0.5h | `WV-001` | `DONE` | Verificado: 0 archivos de audio en repo; requerimientos tomados de contratos e imágenes oficiales sin inventar requisitos |
| **`WV-002`** | E0.1 | Auditar estado actual de Wallet, P2P, Escrow, QR, Networking, Salas Públicas/Privadas y dependencias con Shest | `P0` | 1.0h | `WV-001` | `DONE` | Revisión de `lib/core/api_client/*`, `lib/features/wordverse/meetings/*`, `screens/*` y `20/20` tests en `flutter test` |
| **`WV-003`** | E0.1 | Generar documentación oficial de gestión (`ROADMAP.md`, `TASKS.md`, `STATUS.md`, `DECISIONS.md`, `RISKS.md`) | `P0` | 0.5h | `WV-002` | `DONE` | Creados en `src/wordverse/docs/implementation/` y `docs/implementation/` |

---

## Fase 1: Preparación Técnica

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-101`** | E1.1 | Consolidar tokens de diseño `WordVerseTokens` y `WordVerseTheme` (Paleta Obsidiana `#0A0A0C` + Oro `#D4AF37` + Cian `#00F0FF`) | `P0` | 2.0h | `WV-003` | `DONE` | `lib/core/theme/wordverse_tokens.dart`, `wordverse_theme.dart` + `test/nexus_tokens_and_theme_test.dart` (Pass) |
| **`WV-102`** | E1.1 | Sincronizar protocolo bidireccional `Hub3DProtocol` (`init`, `moved`, `interact`, `avatarTapped`, `subRoomChanged`) | `P0` | 2.0h | `WV-003` | `DONE` | `lib/features/wordverse/3d_room/hub3d/hub3d_protocol.dart` + `test/hub3d_protocol_test.dart` (Pass) |
| **`WV-103`** | E1.1 | Endurecer configuración de variables de entorno (`WordverseEnvConfig`), enmascaramiento de secretos, trazabilidad (`traceId`) y diagnóstico `verifyRemoteConnection()` | `P0` | 2.0h | `WV-102` | `DONE` | `lib/core/config/wordverse_env_config.dart`, `http_shest_api.dart`, `wordverse_events.dart` + `test/phase1_technical_foundations_test.dart` (Pass) |

---

## Fase 2: Experiencia Visual y Salas

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-201`** | E2.1 | Eliminar pórtico `pubPortalGroup` innecesario que sobresalía en el piso del Mezzanine y ajustar altura de `privPortalGroup` (`y <= 3.84m`) | `P0` | 1.5h | `WV-101` | `DONE` | `web/hub3d/src/world.js` (L1151-L1192) + captura `screenshot_mezzanine_sin_letrero_saliente.png` |
| **`WV-202`** | E2.1 | Integrar Monumento Central y 4 Tótems Corporativos Oficiales (`AURUM HEX`, `SHEST COFFEE`, `CYBER WOLF`, `WORDVERSE VR`) en Sala Privada VIP | `P0` | 2.5h | `WV-101` | `DONE` | `web/hub3d/src/world.js` (L1296-L1492) + captura `screenshot_boardroom_logos_empresas.png` |
| **`WV-203`** | E2.1 | Corregir coordenadas y anatomía de asientos en Boardroom (`3.05m`) y retorno exacto al punto de entrada al salir de Sala Privada VIP | `P0` | 3.0h | `WV-102` | `DONE` | `web/hub3d/src/physics.js`, `avatars.js`, `main.js` + `physics.test.mjs` (OK) |
| **`WV-204`** | E2.1 | Conectar creación, permisos RBAC (`Owner`/`Moderator`/`Member`/`Guest`), invitaciones y filtrado de salas en `PublicHubScreen` y `PrivateSuitesScreen` con persistencia en `ShestApiClient` | `P1` | 3.0h | `WV-103` | `DONE` | `shest_api_client.dart`, `public_room.dart`, `private_room.dart`, `public_hub_screen.dart`, `private_suites_screen.dart` + `test/public_and_private_rooms_test.dart` (Pass) |

---

## Fase 3: Traducción mediante IA

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-301`** | E3.1 | Crear `WordverseTranslationService` con soporte multilingüe (`ES`, `EN`, `PT`, `ZH`) para mensajes de chat y reuniones | `P1` | 4.0h | `WV-204` | `DONE` | `wordverse_translation_service.dart` + 6 tests unitarios en `translation_service_test.dart` (Pass) |
| **`WV-301.1`** | E3.1 | Añadir selector de idioma destino y toggle de traducción automática en `NetworkingAndChatSheet` | `P1` | 3.0h | `WV-301` | `DONE` | `networking_chat_sheet.dart` + test widget reactivo bilingüe (Pass) |
| **`WV-302`** | E3.1 | Añadir generación de Minuta Ejecutiva Bilingüe y subtítulos traducidos en el panel de **Nexus AI** (`hub3d`) | `P1` | 3.0h | `WV-301` | `DONE` | `web/hub3d/src/main.js` y selector `ES/EN/Dual` + captura `screenshot_nexus_ai_minuta_bilingue.png` |
| **`WV-303`** | E3.1 | Integrar endpoint opcional `POST /ai/translate` en `ShestBackendAdapter` con fallback local determinista | `P2` | 2.0h | `WV-301` | `DONE` | `shest_backend_adapter.dart`, `http_shest_api.dart`, `mock_shest_api.dart`, `shest_api_client.dart` |

---

## Fase 4: P2P Avanzado

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-401`** | E4.1 | Extender `P2POperation` con tipo (`BUY`/`SELL`), método de pago tipado, límites min/max y reputación verificada | `P1` | 4.0h | `WV-103` | `DONE` | `shest_models.dart`, `P2POperationType`, `P2PPaymentMethod` + 7 tests en `p2p_advanced_test.dart` (Pass) |
| **`WV-402`** | E4.1 | Agregar filtros por método de pago, tipo de operación y buscador de liquidez en `P2PAndWalletSheet` | `P1` | 5.0h | `WV-401` | `DONE` | `p2p_wallet_sheet.dart` con filtros `BUY`/`SELL`, buscador reactivo y ordenamiento por tasa |
| **`WV-403`** | E4.1 | Conectar creación (`createOperation`) y cancelación (`cancelOperation`) de órdenes P2P en `P2PAndWalletSheet` | `P1` | 5.0h | `WV-402` | `DONE` | Modal de publicación, validación de balance, cancelación con reembolso atómico y anti-autonegociación |

---

## Fase 5: Escrow

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-500`** | E5.0 | Análisis del modelo, documento para revisión jurídica, evaluación técnica de custodia y diseño de estados/transiciones | `P0` | 6.0h | `WV-403` | `DONE` | `docs/escrow/01..03` + sonda de auditoría (defectos ESC-D1..D6 documentados) |
| **`WV-500.1`** | E5.0 | Prototipo aislado sin fondos reales: máquina de estados, libro de auditoría encadenado, idempotencia, custodio simulado y corrección de ESC-D1/D2/D3 | `P0` | 8.0h | `WV-500`, `AP-1` | `DONE` | `test/escrow_advanced_test.dart` (ESC-D1, ESC-D2, ESC-D3 corregidos y testeados con 100% éxito) |
| **`WV-501`** | E5.1 | Implementar matriz de acciones contextuales por estado y rol (`creator` vs `counterparty`) en `EscrowCenterSheet` | `P0` | 5.0h | `WV-500.1` | `DONE` | `escrow_sheet.dart` con matriz de roles y estados, probado en `escrow_advanced_test.dart` |
| **`WV-502`** | E5.1 | Añadir línea de tiempo de auditoría (`historyLog`) e inspección de condiciones en cada contrato Escrow (`#45821`) | `P0` | 4.0h | `WV-501` | `DONE` | Timeline cronológico enriquecido con marcas `[HH:MM:SS]`, probado en UI |
| **`WV-503`** | E5.1 | Integrar flujo de disputa (`DISPUTED`) con motivo obligatorio y sincronización con compras del Kiosco 3D (`hub3d`) | `P1` | 5.0h | `WV-502` | `DONE` | Modal de disputa con validación + `Hub3DKioskEscrowPurchase` sincronizado Flutter <-> Three.js |

---

## Fase 6: Integración Full Stack

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-601`** | E6.1 | Sincronizar catálogo de salas y presencia multiusuario (`room_presence`) entre `HttpShestApi`, `WordverseMultiplayerService` y `hub3d` | `P0` | 4.0h | `WV-204`, `WV-503` | `DONE` | `updateRoomPresence` y `getRoomPresence` en `HttpShestApi` + catálogo persistente, probado en `fullstack_integration_test.dart` |
| **`WV-602`** | E6.1 | Conectar compras con Escrow del Kiosco 3D (`buyKioskProductEscrow`) con `ShestEscrowService.createEscrow` vía `bridge.js` | `P0` | 4.0h | `WV-503` | `DONE` | `Hub3DKioskEscrowPurchase` sincronizado y verificado con creación de contrato en Bóveda Escrow |
| **`WV-603`** | E6.1 | Validar ciclo completo de token JWT (`Authorization: Bearer`) y renovación automática (`refreshSession`) en `HttpShestApi` | `P0` | 4.0h | `WV-601` | `DONE` | Manejo transparente de `401 Unauthorized` con reintento automático y conmutación Spring Boot / Supabase / Mock |

---

## Fase 7: Calidad y Seguridad

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-701`** | E7.1 | Documentar y separar políticas RLS de desarrollo (`anon`) vs producción (`authenticated` / `auth.uid()`) en `supabase_schema.sql` | `P0` | 3.0h | `WV-601` | `DONE` | Políticas RLS de producción documentadas y separadas en `supabase_schema.sql` |
| **`WV-702`** | E7.1 | Endurecer control de acceso RBAC (`OWNER`, `MODERATOR`, `MEMBER`, `GUEST`) en salas privadas y validación de tokens de invitación | `P0` | 3.5h | `WV-603` | `DONE` | Verificación de RBAC y tokens en `public_and_private_rooms_test.dart` y `fullstack_integration_test.dart` |
| **`WV-703`** | E7.1 | Ampliar suite de pruebas (`flutter test` + `physics.test.mjs`) y certificar `0` errores en `flutter analyze` | `P0` | 3.5h | `WV-702` | `DONE` | `53/53 tests passed` en Flutter, `physics.test.mjs OK` en Three.js, `0 issues` en `flutter analyze` |

---

## Fase 8: Entrega

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-801`** | E8.1 | Compilar build Web optimizado (`flutter build web --no-pub`) y sincronizar paquete `build/web/hub3d` | `P1` | 2.0h | `WV-703` | `DONE` | `√ Built build\web` en 48.3s y `build/web/hub3d` sincronizado con Three.js a 60 FPS |
| **`WV-802`** | E8.1 | Emitir acta de cierre en `STATUS.md` y guía de despliegue para el equipo Java de Shest Labs | `P1` | 2.0h | `WV-801` | `DONE` | Documentos oficiales `README.md`, `08_ENTREGA_Y_DESPLIEGUE.md`, `STATUS.md` actualizados |

---

## Fase 9: Audio Espacial y Conectividad Avanzada

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-901`** | E9.1 | Implementar `SpatialAudioService` con cálculo de atenuación 3D, balance estéreo, control de mute y eventos en `Hub3DProtocol` | `P1` | 3.5h | `WV-102`, `WV-601` | `DONE` | `spatial_audio_service.dart`, `hub3d_protocol.dart` + 7 tests aprobados en `spatial_audio_test.dart` |
| **`WV-902`** | E9.1 | Integrar contratos inteligentes de Escrow con fondos reales en Mainnet | `P0` | 10.0h | `WV-500.1` | `BLOCKED` | **Bloqueada:** Sujeto a obtención de licencia VASP y auditoría externa (ADR-009) |
| **`WV-903`** | E9.1 | Desplegar clúster productivo de Spring Boot en la infraestructura cloud de Shest Labs | `P1` | 4.0h | `WV-603` | `BLOCKED` | **Bloqueada:** Dependencia externa del equipo de infraestructura de Shest Labs |

---

## Fase A: Corrección Visual, Limpieza de UI & Ergonomía de Cámara

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-A01`** | EA.1 | Eliminar haz de luz vertical amarillo por floración de neón y orientar sofás Mezzanine hacia el atrio abierto | `P0` | 1.5h | `WV-801` | `DONE` | `physics.js` (`mezz_couch_1` `rot: Math.PI`), `world.js` (neón de pilares atenuado a `glow(0.95)`, `couchGroup` local), `main.js` (`cam.yaw = seat.rot`) |
| **`WV-A02`** | EA.1 | Silenciar ticker debug `[AVATAR_MOVED]` en barra superior y evitar colisión con botones HUD 3D de Nexus AI y Kiosco | `P1` | 1.0h | `WV-A01` | `DONE` | `wordverse_module_screen.dart` (`_showDebugTicker` condicional por `onLongPress`, filtrado de coordenadas) |
| **`WV-A03`** | EA.1 | Ocultar selector Three.js `#room-switch-bar` cuando se renderiza dentro del frame Flutter | `P1` | 0.5h | `WV-A01` | `DONE` | `index.html` (`body.in-flutter-frame #room-switch-bar { display: none !important; }`), barra única limpia |
| **`WV-A04`** | EA.1 | Suavizar anillos concéntricos del techo a iluminación indirecta ambiental | `P2` | 0.5h | `WV-A01` | `DONE` | `world.js` (`glowCol` atenuado de 2.8 a 1.25), ambiente de lujo equilibrado sin distracción |

---

## Fase B: Suite de Identidad Corporativa y Presencia Holográfica

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-B01`** | EB.1 | Proyectar rótulos y monumentos holográficos reactivos en la Red Global WordVerse (Plaza Central) y The Boardroom | `P1` | 1.5h | `WV-A01` | `DONE` | `world.js` (`holoNetSign` rotatorio en `globeGroup`, `brHoloStatusSign` quórum VIP activo en `brTableGroup`) |
| **`WV-B02`** | EB.1 | Diseñar e implementar Credencial Holográfica Ejecutiva 3D (`Holo-Card`) con acciones directas de Networking | `P0` | 2.0h | `WV-A02` | `DONE` | `index.html` (`#holo-card-panel` glassmorphism Obsidian & Gold), `main.js` (`openHoloCard`, chat, saludo gestual `wave`, escrow directo) |
| **`WV-B03`** | EB.1 | Implementar Halo de Ondas Acústicas de Audio Espacial (`Speaking Waves`) y conmutador de micrófono en tiempo real | `P0` | 2.0h | `WV-901`, `WV-B02` | `DONE` | `avatars.js` (`speakingGroup` con 3 ondas expansivas + micro sprite + visor glow verde), `wordverse_module_screen.dart` (`btn_microphone_toggle`), `hub3d_protocol_test.dart` (61/61 tests en verde) |

---

## Fase C: Conectividad y Economía Digital Integrada

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-C01`** | EC.1 | Implementar pastilla de balance USDT TRC20 en vivo en HUD 3D (`#hud-wallet-pill`) y sincronización atómica con Flutter | `P0` | 2.0h | `WV-B01` | `DONE` | `index.html` (`#hud-wallet-pill`), `main.js` (`walletUpdated`), `wordverse_module_screen.dart` (`_refreshWalletBalance`, `_onHub3DKioskEscrowPurchase`), `shest_models.dart` (`WalletInfo.copyWith`) |
| **`WV-C02`** | EC.1 | Desarrollar pasarela de pago QR rápida para productos del Kiosco Comercial 3D con URI Tron TRC20 | `P0` | 2.0h | `WV-C01` | `DONE` | `index.html` (`#kiosk-qr-box`, `#kiosk-qr-canvas`), `main.js` (`renderKioskQr`, copia de URI `tron:TK7g...`, confirmación instantánea) |
| **`WV-C03`** | EC.1 | Integrar sistema de notificaciones holográficas ejecutivas no invasivas (`Holo-Toasts E2EE`) | `P1` | 1.5h | `WV-C01` | `DONE` | `index.html` (`#holo-toast-container`), `main.js` (`showHoloToast`, toasts dinámicos de escrow, QR y wallet), 61/61 pruebas aprobadas |

---

## Fase D: Gamificación Ejecutiva, Logros On-Chain y Teletransportación Rápida

| ID | Épica | Tarea / Subtarea | Prioridad | Estimación | Dependencias | Estado | Evidencia / Criterio de Aceptación |
| :--- | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **`WV-D01`** | ED.1 | Portal de Teletransportación Inmediata con Mini-Selector Holográfico y transición cuántica | `P0` | 2.0h | `WV-C01` | `DONE` | `index.html` (`#btn-fast-travel`, `#teleport-overlay`, `#teleport-panel`), `main.js` (`teleportTo`, 5 zonas libres de colisión), `hub3d_protocol.dart` (`Hub3DProtocol.teleport`), `hub3d_view.dart` (`Hub3DController.teleport`), 62/62 pruebas aprobadas |
| **`WV-D02`** | ED.1 | Sistema de Insignias Ejecutivas y Logros On-Chain visualizables en Holo-Card | `P1` | 2.5h | `WV-D01` | `READY` | Insignias en perfil (`Pionero Web3`, `Trader VIP`, `Embajador Shest`), estadísticas de reputación e interacción en `openHoloCard` |
| **`WV-D03`** | ED.1 | Modo Presentación y Pantalla Compartida Holográfica en The Boardroom | `P1` | 3.0h | `WV-D01` | `BACKLOG` | Proyección interactiva de diapositivas en la pantalla monumental de The Boardroom con control para moderadores |

