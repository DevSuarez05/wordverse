# WordVerse — Escrow: Matriz de Riesgos, Resultados de Pruebas y Aprobaciones Pendientes

**Fecha:** 2026-10-29 · **Estado del módulo:** Diseño / simulación. **No apto para producción.**

---

## 1. Matriz de riesgos

Escala: Probabilidad (P) e Impacto (I) de 1 a 5. Nivel = P × I.

| ID | Riesgo | Tipo | P | I | Nivel | Mitigación propuesta | Estado |
| :--- | :--- | :--- | :-: | :-: | :-: | :--- | :--- |
| ESC-R01 | Liberación sin fondos confirmados (ESC-D1) | Técnico/Financiero | 5 | 5 | **25** | Máquina de estados estricta; `FUNDS_CONFIRMED` solo por webhook del custodio | Confirmado en simulación; corrección en prototipo |
| ESC-R02 | Cancelación sin reembolso (ESC-D2) | Técnico/Financiero | 5 | 5 | **25** | `CANCELLED` solo sin fondos; con fondos → `REFUNDED` vía custodio | Confirmado en simulación |
| ESC-R03 | Doble liberación (ESC-D3) | Técnico/Financiero | 4 | 5 | **20** | Terminales sin salida, bloqueo optimista, idempotencia, `payout_id` único, conciliación | Confirmado en simulación |
| ESC-R04 | Actor no autorizado cambia estado (ESC-D3) | Seguridad | 4 | 5 | **20** | Autorización por rol en backend; el cliente envía acciones, no estados | Confirmado en simulación |
| ESC-R05 | Cliente escribe `estado` vía PostgREST con RLS permisiva (ESC-D4, RSK-01) | Seguridad | 3 | 5 | **15** | Retirar `PATCH` directo; RLS solo lectura para usuarios; escritura solo rol de servicio | Abierto |
| ESC-R06 | Reintentos repiten efectos (ESC-D6) | Técnico | 4 | 4 | **16** | `Idempotency-Key` obligatoria | Abierto |
| ESC-R07 | Auditoría manipulable/incompleta (ESC-D5) | Cumplimiento | 4 | 4 | **16** | Libro append-only con hash encadenado, actor y hora | Abierto |
| ESC-R08 | Operar como custodio sin licencia | Legal | 3 | 5 | **15** | No custodia propia; tercero licenciado | Pendiente revisión jurídica |
| ESC-R09 | Fallo o insolvencia del custodio | Contraparte | 2 | 5 | 10 | Due diligence, segregación, seguros, conciliación diaria | Pendiente selección |
| ESC-R10 | Congelamiento de USDT por el emisor | Contraparte | 2 | 4 | 8 | Screening de direcciones; cláusula contractual | Pendiente jurídico |
| ESC-R11 | Webhook falsificado marca fondos confirmados | Seguridad | 2 | 5 | 10 | Firma HMAC, lista de IPs, verificación en cadena antes de confirmar | Diseño |
| ESC-R12 | Disputa abierta mientras el custodio ya ejecutó el pago | Técnico | 2 | 4 | 8 | `DISPUTED` desde `RELEASE_PENDING` solo si la orden no fue enviada; estado de orden del custodio | Diseño |
| ESC-R13 | Evidencias alteradas | Integridad | 2 | 4 | 8 | Hash SHA-256 al recibir; almacenamiento inmutable | Diseño |
| ESC-R14 | Uso para lavado de activos (con P2P) | Legal/AML | 3 | 5 | **15** | KYC/KYB, screening, límites, reembolso solo al origen | Pendiente cumplimiento |
| ESC-R15 | Kiosco 3D muestra "Escrow" sin registro real (RSK-05) | Producto | 4 | 3 | 12 | Rotular como demostración hasta WV-503/WV-602 | Abierto |

---

## 2. Resultados de pruebas

### 2.1 Sonda de auditoría sobre la simulación actual

Archivo: `scratch/escrow_audit_probe_test.dart` (ejecutado 2026-10-29; retirado de la suite para no dejar pruebas que documentan defectos como si fueran comportamiento esperado).

| Prueba | Salida | Interpretación |
| :--- | :--- | :--- |
| P1 Liberar desde `PENDING` | `creator 12500.0 -> 12500.0 | counterparty 48000.0 -> 49000.0` | Se acreditan 1.000 que nunca fueron debitados → **defecto** |
| P2 Cancelar tras fondear | `creator 12500.0 -> 12000.0` | 500 retenidos se pierden → **defecto** |
| P3 Actor ajeno + doble liberación | `counterparty 48000.0 -> 48200.0 (esperado +100)` | Sin autorización y liberación duplicada → **defecto** |

### 2.2 Suite existente

`flutter test --no-pub`: **38/38** pasan. Ninguna de ellas valida reglas de transición de Escrow (la prueba de negocio existente solo crea el Escrow #45821 en `PENDING`).

### 2.3 Prototipo aislado

**No ejecutado** — requiere aprobación (§3).

---

## 3. Aprobaciones pendientes

| # | Aprobación | Responsable | Desbloquea | Estado |
| :-: | :--- | :--- | :--- | :---: |
| AP-1 | Autorizar construcción del **prototipo aislado sin fondos reales** (doc. 01 §4) y corrección de ESC-D1/D2/D3 en la simulación | Product owner / cliente | Fase E | **PENDIENTE** |
| AP-2 | Validar los estados y la matriz de transiciones (doc. 01 §3) | Negocio + backend Shest | Implementación en backend | **PENDIENTE** |
| AP-3 | Respuestas del negocio (doc. 02 §11) | Negocio | Revisión jurídica | **PENDIENTE** |
| AP-4 | Dictamen jurídico y regulatorio | Asesoría legal | Cualquier uso con fondos reales | **PENDIENTE** |
| AP-5 | Aprobación de cumplimiento KYC/AML | Cumplimiento | Onboarding de usuarios reales | **PENDIENTE** |
| AP-6 | Selección y due diligence del custodio | Negocio + seguridad + legal | Integración con custodio | **PENDIENTE** |
| AP-7 | Revisión de seguridad del backend Escrow (y auditoría externa si se usa contrato inteligente) | Seguridad | Staging con fondos de prueba en testnet | **PENDIENTE** |
| AP-8 | Aprobación de paso a producción | Legal + técnico (documentado) | Producción | **BLOQUEADO** por AP-1..AP-7 |

> [!IMPORTANT]
> Restricciones vigentes: no se despliegan contratos productivos, no se custodian fondos reales, no se ejecutan transferencias reales, no se solicitan claves privadas y no se habilitan liberaciones financieras reales.
