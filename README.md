# ENGIH 2018 → Evidencia Nutricional para WFP

Pipeline reproducible para transformar la Encuesta Nacional de Gastos e Ingresos de los Hogares (ENGIH 2018, República Dominicana) en indicadores de consumo, ingesta aparente de micronutrientes y escenarios de fortificación.

📄 Contexto completo, marco metodológico, preguntas y justificación: [`VISION_Y_ARQUITECTURA_PROYECTO.md`](./VISION_Y_ARQUITECTURA_PROYECTO.md)

Este README es la puerta de entrada operativa. Si buscas *por qué* existe el proyecto, ve al documento de arquitectura. Si buscas *qué hacer hoy*, quédate aquí.

---

## Estado actual
*(Editar cada vez que algo cambie — es lo primero que se lee al volver al proyecto)*

- **Fase activa:** Fase 1. **`05_ingesta_micronutrientes.R` está completo (2026-09-10)** — joins, ingesta por hogar, cobertura y capa de escenarios de fortificación — pero **aún sin correr en R**: hay que ejecutarlo y contrastarlo contra los números esperados de la réplica Python (documentados al final del propio script). Auditoría externa completa del proyecto hecha el 2026-09-10: 11/13 cifras documentadas verificadas exactas; **2 bugs activos corregidos** (fan-out de 17,698 filas en Sec 3A por claves duplicadas; 3 filas de peso-por-unidad inertes en Sec 2); **1 decisión metodológica crítica pendiente** (línea base de fortificación: el crosswalk apunta arroz→enriquecido y harina/azúcar→sin fortificar, al revés del programa real RD 2018 — cambia la conclusión de folato de 23% a ~60% de aparente inadecuación). Ver [`INFORME_AUDITORIA_2026-09-10.md`](./INFORME_AUDITORIA_2026-09-10.md) y [`PLAN_EJECUCION.md`](./PLAN_EJECUCION.md).
- **Bloqueador principal:** ninguno técnico. Pendientes de decisión con Daniel/Carlos: línea base de fortificación (H3 de la auditoría) y aprobación final Sopita.
- **Última actualización:** 10-09-2026

---

## Qué hacer ahora

Ver **Oleada 1** de [`PLAN_EJECUCION.md`](./PLAN_EJECUCION.md): correr 01→05 en RStudio y contrastar con la réplica Python, decidir la línea base de fortificación, rellenar los 154 enhance_id confirmados (`data/eda/pendiente_llenar_enhance_id_confirmados.csv`). El detalle de Fase 0/1/2 sigue en [`HOJA_DE_RUTA_PROYECTO.md`](./HOJA_DE_RUTA_PROYECTO.md) — no duplicado acá.