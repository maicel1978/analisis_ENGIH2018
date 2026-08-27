# ENGIH 2018 → Evidencia Nutricional para WFP

Pipeline reproducible para transformar la Encuesta Nacional de Gastos e Ingresos de los
Hogares (ENGIH 2018, República Dominicana) en indicadores de consumo, ingesta aparente de
micronutrientes y escenarios de fortificación.

📄 *Por qué* existe: [`VISION_Y_ARQUITECTURA_PROYECTO.md`](./VISION_Y_ARQUITECTURA_PROYECTO.md)
· 🗺 *Cómo* se avanza (paso a paso, decisiones y KPI): [`PLAN_DE_TRABAJO.md`](./PLAN_DE_TRABAJO.md)

Este README es la puerta de entrada operativa: qué hacer hoy.

---

## Estado actual
*(editar cada vez que algo cambie — es lo primero que se lee al volver al proyecto)*

- **Fase activa:** Fase 2 — Crosswalk de la despensa (Sección 2) · *redirección del grupo de trabajo, 2026-08-27*
- **Estado 3A:** congelado en esqueleto operativo mínimo (pipeline completo, crosswalk 83.4% de registros; pendiente FC por alimento — PLAN Fase 4)
- **Bloqueadores principales:**
  1. Confirmar con MIMI/BCRD: PM de Sec 2 (=7 según formulario) y semántica de `cantidad` en filas con presentación (PLAN D1/D2)
  2. Cuestionario A (roster edad/sexo, quintiles, región) — fuera del repo; bloquea AFE y estratificación (PLAN D9)
- **KPI de capa MASTER (2026-08-27):** 818 llaves · 137 resueltas · 10 excluidas · 671 pendientes · TCA master: 78 alimentos
- **Última actualización:** 27-08-2026

## Qué hacer ahora

1. Llenar `data/raw/crosswalk_variedad_SEC2.xlsx` (46 filas; sugerencias INCAP ya curadas;
   hoja `FC_pendientes` = la mini-tabla de pesos de conversión de despensa).
   Regla de aceptación: `validado=TRUE` exige ID final no vacío o `no_alimento_excluir`.
2. Validar los ~20 pesos de referencia de `FC_pendientes` (BCRD/MIMI o tabla de porciones).
3. Correr en RStudio: `00_master.R` → revisar KPI en consola → `03_transform.R`.
   Sec 2 se habilita sola (KPI objetivo: ~99.9% de sus registros con composición).
4. Registrar el estado de cada racha aquí (estado actual) y commitear por fase.

## Estructura

```
scripts/
  00_master.R     → genera data/master/* (NO editar las salidas a mano)
  01_import.R     → data/raw/*.csv + data/clean/data_sec2.csv, data_sec3a.csv
  02_eda.R        → chequeos de calidad (data/eda/*)
  03_transform.R  → Q×FC×PC/PM → consumo diario por hogar (data/clean/consumo_*)
  04_equivalente_adulto.R   (espera Cuestionario A)
  05_ingesta_micronutrientes.R  (espera 03 + 04)
  06_report.qmd
data/
  raw/            → fuentes originales + crosswalks (se editan a mano)
  clean/          → datos de trabajo (salidas de 01 y 03)
  master/         → capas maestras (solo generadas por 00_master.R)
  eda/            → salidas de diagnóstico
docs/             → guía WFP, formulario ENGIH, Tang et al., notas
```

**Regla de llaves (crítico):** la llave canónica de alimento es `CAT:<id>` (catálogo,
Sec 3A y 11 códigos de Sec 2) o `SEC2:<id>` (código local del formulario de despensa).
Nunca unir 3A y Sec 2 por `id_variedad` plano: son espacios distintos (p.ej. `2` =
galletas dulces en Sec 2, pan sobado en 3A). Ver PLAN_DE_TRABAJO.md, descubrimiento 1.
