# ENGIH 2018 → Evidencia Nutricional para WFP

Pipeline reproducible para transformar la Encuesta Nacional de Gastos e Ingresos de los Hogares (ENGIH 2018, República Dominicana) en indicadores de consumo, ingesta aparente de micronutrientes y escenarios de fortificación.

📄 Contexto completo, marco metodológico, preguntas y justificación: [`VISION_Y_ARQUITECTURA_PROYECTO.md`](./VISION_Y_ARQUITECTURA_PROYECTO.md)

Este README es la puerta de entrada operativa. Si buscas *por qué* existe el proyecto, ve al documento de arquitectura. Si buscas *qué hacer hoy*, quédate aquí.

---

## Estado actual
*(Editar cada vez que algo cambie — es lo primero que se lee al volver al proyecto)*

- **Fase activa:** Fase 0 — Auditoría de factores de conversión (FC), `data_raw_unidades.xlsx`, hoja `Cuest. B Sec 2`. Sub-tarea dentro del cuello de botella de FC "alimento-específico" (181/196 filas pendientes en Sec 2).
- **Bloqueador principal:** ninguno nuevo bloqueando — hay trabajo concreto listo para empezar, ver abajo. (El bloqueador de *Sopita Concentrada* del crosswalk sigue abierto, es independiente de esto.)
- **`frecuencia_datos` de `data_raw_unidades.xlsx` (Sec 2) está desalineada** respecto al crudo — reemplazo en `data/eda/combinaciones_reales_sec2.csv`. Detalle en `HOJA_DE_RUTA_PROYECTO.md`, Fase 0.
- **Última actualización:** 05-09-2026

---

## Qué hacer ahora

Ver **Fase 0** de [`HOJA_DE_RUTA_PROYECTO.md`](./HOJA_DE_RUTA_PROYECTO.md) — checklist y protocolo de validación de FC ya está ahí, junto con el resto del alcance pendiente. No duplicar ese detalle acá.