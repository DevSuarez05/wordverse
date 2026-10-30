# 🏛️ WORDVERSE — REGISTRO DE DECISIONES ARQUITECTÓNICAS (`DECISIONS.md`)

Este documento registra las decisiones técnicas clave (ADRs) adoptadas tras la auditoría del repositorio de WordVerse.

---

## ADR-001: Delegación Financiera Total al Backend de Shest Labs
- **Estado:** Aceptada y Vigente
- **Contexto:** WordVerse incluye módulos de Wallet USDT TRC20, Pagos, Mercado P2P, Shest Coffee y Contratos de Escrow (`#45821`).
- **Decisión:** WordVerse **nunca** custodia llaves privadas, ni calcula saldos definitivos, ni libera fondos por cuenta propia en el cliente. Toda operación financiera viaja a través de [`ShestApiClient`](../../lib/core/api_client/shest_api_client.dart) hacia el backend autoritativo de Shest Labs (`https://api.shestlabs.com/v1` en Java Spring Boot, o Supabase/Mock en entornos de desarrollo).
- **Consecuencias:** Cero duplicación de reglas contables de Shest y cumplimiento estricto de seguridad transaccional.

---

## ADR-002: Arquitectura Híbrida 3D (Three.js WebGL + Respaldo 2.5D en Flutter)
- **Estado:** Aceptada y Vigente
- **Contexto:** El cliente requiere una experiencia 3D fotorrealista estilo ejecutivo (Obsidiana y Oro WordVerse) en navegador Web, manteniendo compatibilidad con pruebas unitarias/widgets en la VM de Dart y dispositivos sin WebGL.
- **Decisión:**
  1. En Web, [`Hub3DView`](../../lib/features/wordverse/3d_room/hub3d/hub3d_view.dart) monta el motor Three.js (`web/hub3d/index.html`) comunicado por mensajes JSON tipados (`Hub3DProtocol`).
  2. Cuando corre en entorno de tests (`flutter test`) o sin soporte WebGL, `Hub3DView` conmuta automáticamente al visor 2.5D (`Room3DViewport` + `HubArchitecturePainter`).
- **Consecuencias:** Permite renderizado 3D a 60 FPS con Bloom, reflejos PBR y Smart LOD en navegador, sin perder determinismo en las 20 pruebas automatizadas de Flutter.

---

## ADR-003: Adaptador Tri-Entorno (`Mock` / `Supabase Staging` / `Production Java API`)
- **Estado:** Aceptada y Vigente
- **Contexto:** El equipo de desarrollo necesita iterar y probar flujos multiusuario y de negocio antes y durante el despliegue del backend Java de Shest Labs.
- **Decisión:** Implementar la interfaz única [`ShestBackendAdapter`](../../lib/core/api_client/shest_backend_adapter.dart) con tres modos seleccionables en caliente desde la UI o por `--dart-define`:
  - `ShestBackendEnvironment.mock` (`MockShestApi`)
  - `ShestBackendEnvironment.supabaseStaging` (`HttpShestApi` contra PostgREST/Realtime)
  - `ShestBackendEnvironment.production` (`HttpShestApi` contra Spring Boot REST API)

---

## ADR-004: Separación Espacial y Cota de Altura bajo el Mezzanine (`y < 3.99m`)
- **Estado:** Aceptada e Implementada (`WV-201`)
- **Contexto:** La losa del Mezzanine se ubica en `y = 4.02m .. 4.20m`. Cualquier cartel o pórtico en planta baja cerca del perímetro norte (`z < -4.2m`) cuya altura supere `3.99m` atraviesa visualmente el suelo del segundo piso.
- **Decisión:**
  1. Eliminar el pórtico redundante `SALA PÚBLICA` en planta baja izquierda (`x = -6.2m`).
  2. Limitar la altura máxima del pórtico `SALA PRIVADA VIP` en planta baja derecha (`x = 6.2m`) a `y <= 3.84m` para que quede íntegramente debajo de la losa del Mezzanine.
  3. Guardar la coordenada exacta de ingreso (`lastLobbyEntryPose`) con `portalCooldown = 2.4s` para que al salir de la Sala Privada VIP el jugador regrese exactamente al punto de entrada sin rebotes.

---

## ADR-005: No Invención de Requisitos de Audio
- **Estado:** Aceptada y Vigente (`WV-001.2`)
- **Contexto:** El prompt de auditoría solicita analizar los audios del cliente sin inventar requisitos.
- **Decisión:** Tras auditar el árbol completo del repositorio y el directorio de archivos subidos por el usuario, se constató que no existen archivos de audio adjuntos (`.mp3`, `.wav`, `.ogg`, `.m4a`). Por tanto, **no se inventa ningún requisito proveniente de audios**; toda la planificación se basa estrictamente en el código existente, los contratos de `docs/`, las imágenes oficiales cargadas y las instrucciones explícitas del usuario.

---

## ADR-006: Configuración Centralizada, Enmascaramiento de Secretos y Trazabilidad HTTP (`WV-103`)
- **Estado:** Aceptada e Implementada (Fase 1)
- **Contexto:** Se requería centralizar las variables `--dart-define`, evitar que tokens JWT o `SUPABASE_ANON_KEY` se filtraran en texto plano en logs/eventos y mitigar el riesgo `RSK-03` (fallos HTTP remotos silenciados).
- **Decisión:**
  1. Crear [`WordverseEnvConfig`](../../lib/core/config/wordverse_env_config.dart) para centralizar URLs por defecto, lectura de variables de entorno, validación de endpoints remotos (`isConfiguredRemoteUrl`), normalización PostgREST (`normalizeRestUrl`) y enmascaramiento de credenciales (`maskSecret`).
  2. Enriquecer [`WordverseEventBus`](../../lib/core/events/wordverse_events.dart) con `WordverseEventSeverity` (`INFO`, `WARN`, `ERROR`), generación automática de `traceId` (`WV-TRC-...`) y filtros por severidad/tipo.
  3. Enriquecer [`HttpShestApi`](../../lib/core/api_client/http_shest_api.dart) con cabeceras de trazabilidad (`X-WordVerse-Client-Version`, `X-WordVerse-Environment`, `X-WordVerse-Trace-Id`), medición de latencia en `verifyRemoteConnection()` y bandera `strictRemoteErrors` que emite `WordverseEventType.apiError` y lanza [`ShestApiException`](../../lib/core/models/shest_models.dart) tipada con `statusCode` y `traceId`.

---

## ADR-007: Motor Híbrido de Traducción IA con Fallback Determinista y Renderizado Bilingüe Dual (Fase 3 — WV-301..WV-303)
- **Estado:** Aceptada e Implementada (Fase 3)
- **Contexto:** Se requiere soporte multilingüe en tiempo real (`ES`, `EN`, `PT`, `ZH`) para el chat de salas y las reuniones ejecutivas, sin exponer API keys de terceros en el cliente web ni bloquear la interfaz de usuario en caso de latencia de red.
- **Decisión:**
  1. Crear [`WordverseTranslationService`](../../lib/core/services/wordverse_translation_service.dart) con detección automática de idioma (Unicode Han para Chino, patrones léxicos para Portugués, Inglés y Español), control de tasa (máx 60 req/min) y caché LRU en memoria.
  2. Implementar fallback determinista con amplio corpus B2B, Escrow y términos financieros que opera tanto offline como cuando el endpoint remoto (`POST /ai/translate`) no está disponible.
  3. En [`NetworkingAndChatSheet`](../../lib/features/wordverse/meetings/networking_chat_sheet.dart), el mensaje original **nunca se sobrescribe**; se muestra de forma dual con indicador holográfico (`[IA: EN ➔ ES]`) y botón para colapsar/desplegar la traducción sin demoras.
  4. En Three.js 3D (`web/hub3d/src/main.js`), el conserje holográfico **Nexus AI** permite conmutar la generación de la minuta ejecutiva entre Español (`ES`), Inglés (`EN`) o formato Dual (`Dual ES+EN`), con locución por voz neural en el idioma elegido y descarga en Markdown.

---

## ADR-008: Arquitectura P2P Avanzada con Controles de Integridad Financiera y Anti-Autonegociación (Fase 4 — WV-401..WV-403)
- **Estado:** Aceptada e Implementada (Fase 4)
- **Contexto:** Se requiere evolucionar el mercado P2P para permitir publicación de ofertas de compra y venta (`BUY`/`SELL`), límites mínimos/máximos, reputación de comerciantes, filtros dinámicos y cancelación de órdenes, preservando la integridad contable y la estricta delegación a Shest API.
- **Decisión:**
  1. Extender [`P2POperation`](../../lib/core/models/shest_models.dart) manteniendo total compatibilidad hacia atrás mediante valores por defecto seguros (`P2POperationType.sell`, límites basados en el volumen de la orden, reputación y total fiat calculado).
  2. Implementar regla anti-autonegociación en el backend/adaptador: un usuario no puede aceptar su propia orden (`takerId == makerId`), arrojando excepción de integridad financiera `CANNOT_ACCEPT_OWN_ORDER`.
  3. En ofertas de venta (`SELL`), el balance del maker se reserva atómicamente al momento de la publicación y se restituye de forma íntegra e instantánea si la orden es cancelada antes de ser tomada.
  4. Enriquecer [`P2PAndWalletSheet`](../../lib/features/wordverse/meetings/p2p_wallet_sheet.dart) con filtrado reactivo por tipo (`Todas`, `🟢 Compras`, `🔵 Ventas`), buscador en tiempo real, ordenamiento por tasa USD/USDT, modal de creación de oferta P2P y acciones contextuales por rol (cancelar si es del usuario actual, comerciar si es de terceros).




---

## ADR-009: Escrow condicionado a revisi�n jur�dica, custodia por tercero y m�quina de estados autoritativa en backend (Fase 5 � WV-500)
- **Estado:** Propuesta � pendiente de aprobaci�n (AP-1..AP-8).
- **Contexto:** La sonda de auditor�a confirm� que la simulaci�n actual permite liberar sin fondeo, cancelar sin reembolso y liberar dos veces con actores no autorizados; el adaptador HTTP escribe el estado desde el cliente.
- **Decisi�n propuesta:** (1) WordVerse no custodia fondos; preferencia t�cnica por proveedor de custodia especializado o agente de escrow licenciado, sujeta a dictamen jur�dico. (2) Estados `CREATED..COMPLETED` con matriz de transiciones y actores (`docs/escrow/01` �3). (3) El cliente env�a acciones, nunca estados; `FUNDS_CONFIRMED`/`RELEASED`/`REFUNDED` solo por webhook verificado del custodio. (4) Idempotencia, bloqueo optimista, `payout_id` �nico y libro de auditor�a con hash encadenado. (5) Ning�n uso con fondos reales sin aprobaci�n jur�dica y t�cnica documentada.

