# ⚠️ WORDVERSE — MATRIZ DE RIESGOS Y DEUDA TÉCNICA (`RISKS.md`)

Registro de riesgos técnicos y de negocio identificados durante la **Fase 0: Auditoría**, junto con su severidad y plan de mitigación.

---

## 1. Riesgos Técnicos Identificados

| ID | Riesgo / Deuda Técnica | Severidad | Probabilidad | Impacto | Mitigación Asignada en el Plan |
| :--- | :--- | :---: | :---: | :--- | :--- |
| **`RSK-01`** | **Políticas RLS permisivas en `supabase_schema.sql` (`using (true)` para `anon`)** | Alta | Media | En un entorno productivo público, cualquier cliente con el `ANON_KEY` podría modificar filas de `wallets`, `escrows` o `users`. | **`WV-701` (Fase 7):** Separar el script SQL en políticas de desarrollo (`staging`) y políticas estrictas de producción basadas en `auth.uid()` y rol de servicio del backend Java de Shest. |
| **`RSK-02`** | **Desincronización entre `web/hub3d/` (fuente) y `build/web/hub3d/` (compilado)** | Media | Alta | Si se edita `src/wordverse/web/hub3d/` sin copiar a `build/web/hub3d/` o sin cache-busting (`?v=...`), el navegador sirve módulos JS antiguos en caché. | **`WV-801` (Fase 8):** Mantener query strings de versión en los imports ES6 (`?v=20261029_v7`) y sincronizar automáticamente ambos directorios en el script de build/servidor. |
| **`RSK-03`** | **Fallback silencioso en `HttpShestApi` cuando falla una petición remota** | Media | Media | En `HttpShestApi`, varios bloques `try/catch` caen silenciosamente en `fallbackMock` ante un error HTTP, lo que puede ocultar errores `401`/`500` reales en producción. | **`WV-103` (Fase 1) y `WV-603` (Fase 6):** Diferenciar entre ausencia de credenciales (usar `fallbackMock`) y error explícito de API en modo `production` (propagar `ShestApiException` controlada a la UI). |
| **`RSK-04`** | **Catálogos de Salas Públicas y Privadas inicializados en memoria (`sampleCatalog` / `sampleSuites`)** | Media | Media | Las salas creadas desde `PublicHubScreen` durante una sesión no se persisten aún en Supabase ni se comparten con otros clientes conectados. | **`WV-204` (Fase 2) y `WV-601` (Fase 6):** Conectar la creación y listado de salas con `ShestApiClient` (`meetings` / `rooms`). |
| **`RSK-05`** | **Compras de Escrow en Kiosco 3D (`hub3d`) no sincronizadas con `EscrowCenterSheet` de Flutter** | Media | Media | El Kiosco Comercial 3D muestra confirmación visual de Escrow al comprar un producto, pero no emite aún el evento al `ShestEscrowService` de Flutter para agregarlo a la lista de contratos. | **`WV-602` (Fase 6):** Emitir mensaje `kioskEscrowCreated` por `bridge.js` y registrar la operación mediante `ShestEscrowService.createEscrow`. |
| **`RSK-06`** | **Ausencia de capa de Traducción Multilingüe IA en el Chat de Salas** | Media | Baja | Usuarios internacionales en salas de Networking y P2P aún no cuentan con traducción automática en tiempo real dentro de `NetworkingAndChatSheet`. | **`WV-301`..`WV-303` (Fase 3):** Implementar `WordverseTranslationService` con soporte multilingüe (`ES`/`EN`/`PT`/`ZH`) e integración con Nexus AI. |
| **`RSK-07`** | **Rendimiento WebGL en equipos con GPU integrada** | Baja | Media | El post-procesado `UnrealBloomPass` y múltiples `PointLight` pueden reducir los FPS en portátiles sin GPU dedicada. | **Ya mitigado y monitoreado (`main.js` L1406-L1422):** El motor cuenta con calidad adaptativa automática (desactiva Bloom y ajusta `pixelRatio` a `1` si los FPS bajan de 40 durante 3 segundos) y culling de zona (`boardroomRoot.visible`). |

| **`RSK-08`** | **Simulaci�n Escrow con defectos financieros cr�ticos (ESC-D1..D4)** | Cr�tica | Confirmada | Liberaci�n sin fondos, cancelaci�n sin reembolso, doble liberaci�n y escritura de estado desde el cliente. | `WV-500.1` (bloqueado por AP-1). Detalle en `docs/escrow/03_ESCROW_RIESGOS_PRUEBAS_APROBACIONES.md`. |

