# WordVerse — Escrow: Documento de Preguntas para Revisión Jurídica y Regulatoria

> [!WARNING]
> **Este documento NO es una opinión legal** ni concluye que el servicio sea legalmente viable. Es un inventario técnico de temas y preguntas que deben ser evaluados por abogados y asesores regulatorios habilitados en cada jurisdicción relevante. Ninguna funcionalidad de Escrow con fondos reales debe habilitarse sin un dictamen escrito de dichos profesionales.

**Preparado por:** Equipo técnico WordVerse (Fase 5)
**Fecha:** 2026-10-29
**Destinatarios:** Asesoría jurídica de Shest Labs / WordVerse, asesor regulatorio externo, oficial de cumplimiento.

---

## 1. Descripción del servicio propuesto (para contexto del revisor)

WordVerse es una plataforma de reuniones y networking empresarial en 3D. Se propone que dos usuarios (normalmente empresas) acuerden una operación comercial y que el pago, en **USDT sobre la red TRON (TRC20)**, quede retenido hasta que se cumplan las condiciones pactadas, momento en el cual se libera al vendedor; o se reembolse al comprador si la operación no se concreta; con un mecanismo de disputas resuelto por un árbitro.

Características relevantes:
- Activo: stablecoin USDT (TRC20). Posible extensión a fiat **no confirmada**.
- La plataforma también ofrece un mercado P2P de compra/venta de USDT y pagos directos entre usuarios (Fase 4).
- WordVerse se presenta como interfaz; el backend financiero es de Shest Labs (Java Spring Boot).
- El custodio de los fondos **no está definido** (opciones: proveedor de custodia especializado, agente de escrow licenciado, contrato inteligente, custodia propia — ver documento 01 §2).
- Usuarios potencialmente en múltiples países (la interfaz soporta ES, EN, PT, ZH).

---

## 2. Jurisdicciones

**Información que falta y debe aportar el negocio:**
1. País de constitución de la entidad que opera WordVerse y de Shest Labs.
2. Países donde se ofrecerá el servicio y donde residirán los usuarios.
3. Ubicación de la infraestructura y de los datos.
4. Jurisdicción del custodio candidato.

**Preguntas al revisor:**
- ¿Qué leyes aplican al operador, a los usuarios y al custodio? ¿Se requiere bloqueo geográfico de algunas jurisdicciones?
- ¿La oferta a usuarios de un país desde otro país activa requisitos locales de registro o licencia?

---

## 3. Naturaleza jurídica del servicio

- ¿Retener USDT por cuenta de terceros y liberarlo según condiciones constituye custodia de activos virtuales, servicio de pago, transmisión de dinero, servicio fiduciario/escrow regulado u otra figura?
- ¿Cambia la calificación según quién custodie (plataforma vs. tercero licenciado vs. contrato inteligente con árbitro)?
- ¿El mercado P2P de USDT, combinado con el Escrow, convierte al operador en proveedor de servicios de activos virtuales (VASP o figura equivalente)?
- ¿La resolución de disputas por parte de la plataforma constituye una actividad regulada (arbitraje, mediación) o requiere cláusulas específicas?
- ¿Existen restricciones locales para el uso de stablecoins en pagos comerciales?

---

## 4. Obligaciones contractuales

Documentos que se prevé necesitar (a redactar por asesoría jurídica):
- Términos y Condiciones de Escrow (partes, condiciones de liberación, plazos de inspección, cancelación, reembolsos, comisiones).
- Reglamento de disputas (plazos, evidencias admitidas, árbitro, apelación, efecto vinculante).
- Contrato con el custodio / agente de escrow (responsabilidades, segregación de fondos, seguros, SLA, insolvencia).
- Limitación de responsabilidad frente a: congelamiento de USDT por el emisor, fallos de la red TRON, errores de dirección, fluctuaciones de comisión de red.

**Preguntas al revisor:**
- ¿Quién responde frente al usuario en caso de pérdida de fondos por fallo del custodio?
- ¿Qué ocurre con los fondos en caso de insolvencia del operador o del custodio?
- ¿Son exigibles las resoluciones de disputa de la plataforma? ¿Cómo interactúan con tribunales o arbitraje externo?

---

## 5. Requisitos regulatorios (temas a evaluar)

- Licencias o registros necesarios para el operador y/o el custodio.
- Requisitos de capital, seguros o garantías.
- Segregación de fondos de clientes.
- Reporte regulatorio periódico.
- Requisitos de auditoría externa.
- Requisitos sobre publicidad y comunicación del servicio (p.ej., no presentar USDT como "dinero asegurado").

---

## 6. Protección de usuarios

- Información precontractual obligatoria (riesgos de stablecoins, comisiones, plazos).
- Derechos de desistimiento o cancelación aplicables a usuarios empresariales vs. consumidores.
- Canales de reclamo y plazos de respuesta.
- Accesibilidad y comprensión del flujo (incluida la traducción automática por IA: ¿es suficiente para documentos contractuales o se requiere traducción certificada? — la Fase 3 conserva siempre el texto original).

---

## 7. Protección de datos

Datos que el flujo trataría: identidad y documentos KYC, direcciones de billetera, historial de operaciones, mensajes de chat y minutas de reunión usados como evidencia, archivos de evidencia.

**Preguntas al revisor:**
- Base legal para cada tratamiento y para el uso de mensajes/minutas como evidencia.
- Transferencias internacionales de datos (infraestructura, custodio, proveedor KYC, proveedor de traducción IA si se usa uno externo).
- Plazos de conservación versus derecho de supresión, considerando obligaciones AML.
- La naturaleza pública de la blockchain: ¿vincular una dirección TRC20 con una identidad genera obligaciones adicionales?

---

## 8. Prevención de lavado de activos y financiamiento del terrorismo (cuando corresponda)

- ¿Se requiere KYC/KYB de ambas partes antes de crear o fondear un escrow? ¿Con qué nivel de diligencia según monto?
- Monitoreo de transacciones y análisis de direcciones blockchain (screening de direcciones sancionadas o de alto riesgo).
- Listas de sanciones aplicables.
- Reportes de operaciones sospechosas: ¿quién es el sujeto obligado (plataforma, custodio, ambos)?
- "Travel rule" o equivalente para transferencias de activos virtuales.
- Política de reembolso solo al origen de los fondos (propuesta técnica, documento 01 §1.5) — ¿es suficiente o requiere controles adicionales?
- Riesgo específico del mercado P2P (posible uso para conversión fiat↔cripto por terceros).

---

## 9. Obligaciones de proveedores de custodia y pagos

- ¿Qué licencias debe tener el custodio en cada jurisdicción?
- ¿Qué debidas diligencias debe realizar el operador sobre el custodio (due diligence, auditorías SOC 2/ISO 27001, seguros, prueba de reservas)?
- ¿Qué responsabilidades se transfieren contractualmente y cuáles permanecen en el operador?
- ¿El emisor de USDT puede congelar fondos en custodia? ¿Cómo se informa al usuario?

---

## 10. Riesgos legales identificados desde la perspectiva técnica

| ID | Riesgo | Por qué importa |
| :--- | :--- | :--- |
| LEG-01 | Operar como custodio sin licencia | Si WordVerse/Shest retiene fondos directamente (modelo D). |
| LEG-02 | Combinación P2P + Escrow + pagos | Puede ampliar el perímetro regulado del operador. |
| LEG-03 | Resoluciones de disputa no exigibles | El usuario podría impugnar la decisión del árbitro. |
| LEG-04 | Datos de chat y reuniones como evidencia | Requiere base legal y consentimiento informado. |
| LEG-05 | Traducción IA en contextos contractuales | Riesgo de malentendidos; el original debe prevalecer. |
| LEG-06 | Congelamiento de USDT por el emisor | Fondos bloqueados fuera del control de la plataforma. |
| LEG-07 | Usuarios en jurisdicciones restringidas | Necesidad de geobloqueo y verificación de residencia. |

---

## 11. Decisiones que el negocio debe tomar antes de la revisión

- [ ] Jurisdicción del operador y mercados objetivo.
- [ ] ¿Solo B2B o también consumidores?
- [ ] ¿Solo USDT o también fiat?
- [ ] Montos mínimos y máximos por escrow.
- [ ] Modelo de custodia preferido (A o B del documento 01).
- [ ] Quién actuará como árbitro.
- [ ] Modelo de comisiones.

---

## 12. Conclusión

No es posible, desde el análisis técnico, determinar si el servicio es legalmente viable. Se requiere un dictamen escrito de asesoría jurídica y regulatoria. Hasta entonces, el módulo Escrow permanece en estado **diseño / simulación sin fondos reales**.

| Aprobación | Responsable | Estado |
| :--- | :--- | :---: |
| Dictamen jurídico y regulatorio | Asesoría legal | **PENDIENTE** |
| Aprobación de cumplimiento (KYC/AML) | Oficial de cumplimiento | **PENDIENTE** |
