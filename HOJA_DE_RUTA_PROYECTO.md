# Hoja de ruta — Proyecto ENGIH 2018 (Consumo y Nutrición, WFP)

**Congelada el:** 2026-09-03
**Objetivo final:** artículo científico + dashboard de apoyo a decisiones, siguiendo el marco ampliado de Tang et al. (2021) sobre la base metodológica de Imhoff-Kunsch (2012).

Este documento fija el alcance acordado hasta ahora. Cualquier cambio de alcance debería reflejarse acá explícitamente antes de asumirse en el trabajo diario — si algo cambia, se edita esta hoja, no se improvisa por fuera de ella.

---

## Fase 0 — Cerrar la base de datos (prerrequisito, en curso)

- [ ] Completar validación del crosswalk Sec 3A (144/772 hechas; quedan ~628)
- [ ] Resolver los ~68 `id_variedad` de Sec 3A ausentes del diccionario oficial (¿versión distinta, o residual real?)
- [ ] Decidir si cubrir los 16 códigos `VARIEDAD` de Sec 2 fuera del crosswalk de 30 (afecta 0.13% de filas — prioridad baja)
- [ ] Completar factores FC "Alimento-específico" — 181/196 filas pendientes en Sec 2, 718/721 en Sec 3A. **Este es el cuello de botella más grande del proyecto hoy.**
  - [ ] `frecuencia_datos` de `data_raw_unidades.xlsx` (Sec 2) está desalineada respecto al crudo — usar `data/eda/combinaciones_reales_sec2.csv` (recalculada, frecuencia real por combinación) en su lugar
  - [ ] Revisar las 49 combinaciones atípicas de `data/eda/candidatos_inconsistencia_FC_sec2.csv` contra el crudo antes de asignar FC (protocolo abajo); llenar `estado_revision`/`decision`/`justificacion` en el mismo archivo
  - [ ] Repetir recálculo de frecuencia real + detección de atípicos para Sec 3A (721 filas, sin auditar)
  - [ ] Evaluar `cantidad_unidades_presentacion`/`contenido_empaque_presentacion` del crudo (no usadas en `01_import.R`) como fuente empírica de FC cuando la base sea masa/volumen, antes de buscar factores externos
  - [ ] Confirmar tabla completa de códigos de unidad (fuente: `docs/Formulario ENGIH B. Gastos diarios del hogar.pdf`, sección "CÓDIGOS DE UNIDADES DE MEDIDA Y DE PRESENTACIÓN") — códigos 111/113 en SALAMI no calzan con la transcripción parcial actual
- [ ] Corregir el bug de escala ×1000 en las 15 filas de FC específico ya rellenas en Sec 2

**Protocolo de validación de FC** (cualquier combinación sospechosa, Sec 2 o Sec 3A): (1) extraer la fila cruda completa (vivienda/hogar); (2) revisar si la unidad base y cantidad_inicial/final ya tienen sentido físico por sí solas; (3) revisar si la misma vivienda repite otras respuestas atípicas; (4) documentar la decisión (validado / corregido, dejando el valor original / sin evidencia) — nunca sobrescribir sin dejar rastro.
- [ ] Corregir la codificación de texto rota en 168 filas de la hoja FC de Sec 3A
- [ ] Resolver la colisión de `ENHANCE_ID` 70211110 (sal de mesa / elote enlatado) en `food_composition_INCAP.xlsx`
- [ ] Decidir tratamiento de "Guandules verdes desgranados" (EDIBLE mal heredado de la versión en vaina)
- [ ] Decidir arquitectura para los ítems de fuente FNDDS en el join final (su ID no es nativo de INCAP)

## Fase 1 — Pipeline de scripts (01 → 06)

- [x] `01_import.R` — Q, FC (3 niveles), `enhance_id`, PC ensamblados. Recién corregido; pendiente correr contra datos reales — **estamos acá**.
- [ ] `02_eda.R` — overlap de hogares, estandarización de unidades, missingness, duplicados, cobertura del diario. Ya existe; revisar tras el fix de 01.
- [ ] `03_transform.R` — aplicar `Q × FC × PC / PM` con PM real (`dias_observados_hogar`, no la constante 1 en Sec 3A); disponibilidad neta Sec 2 + Sec 3A para alimentos almacenables (arroz, aceite, azúcar, harina, habichuelas, leche); control de calidad de outliers (Paso 7 de la guía MIMI/WFP).
- [ ] `04_equivalente_adulto.R` — AME (FAO) y AFE (Tang) por hogar.
- [ ] `05_ingesta_micronutrientes.R` — join con INCAP/FNDDS completos (~65 nutrientes); consumo aparente de energía, macro y micronutrientes por AME y AFE.
- [ ] `06_report.qmd` — reporte reproducible base.

## Fase 2 — Marco analítico ampliado (Tang et al. 2021)

- [ ] Cobertura de vehículos de fortificación (arroz, aceite, harina, azúcar, sal) — % de hogares consumidores, por quintil de gasto, región, urbano/rural
- [ ] Consumo aparente por AME **y** AFE (mujeres 15-49, embarazadas/lactantes)
- [ ] Densidad de nutrientes (por 1000 kcal) — separar calidad de dieta de cantidad de dieta
- [ ] Equidad — comparaciones por quintil, urbano/rural, región
- [ ] Escenarios de fortificación (sin fortificar / norma actual / cumplimiento perfecto / optimizada) para arroz, aceite, harina
- [ ] Aporte de alimentos consumidos fuera del hogar, si ENGIH lo captura con suficiente detalle (requiere factores de receta — evaluar viabilidad antes de comprometerse)

## Fase 3 — Dashboard

- [ ] Definir audiencia y decisiones que debe soportar (¿uso interno WFP? ¿Ministerio de Salud/SESPAS?)
- [ ] Seleccionar indicadores clave (cobertura, prevalencia de inadecuación, densidad, equidad)
- [ ] Prototipo (herramienta a decidir: Shiny, Quarto dashboard, u otra)
- [ ] Iterar con retroalimentación de Carlos Rodas y Daniel Hernández

## Fase 4 — Artículo

- [ ] Definir estructura (Tang et al. 2021 como modelo de referencia)
- [ ] Métodos: crosswalk, FC, PC, AME/AFE, escenarios de fortificación
- [ ] Resultados: cobertura, consumo aparente, densidad, equidad, escenarios
- [ ] Discusión y limitaciones (HCES vs. consumo individual; ver caveats metodológicos ya identificados en las notas del proyecto)

---

*Próximo paso inmediato: revisar los 49 candidatos de `data/eda/candidatos_inconsistencia_FC_sec2.csv` contra el crudo, y repetir la auditoría de frecuencia real para Sec 3A.*