# Hoja de ruta — Proyecto ENGIH 2018 (Consumo y Nutrición, WFP)

**Congelada el:** 2026-09-03
**Objetivo final:** artículo científico + dashboard de apoyo a decisiones, siguiendo el marco ampliado de Tang et al. (2021) sobre la base metodológica de Imhoff-Kunsch (2012).

Este documento fija el alcance acordado hasta ahora. Cualquier cambio de alcance debería reflejarse acá explícitamente antes de asumirse en el trabajo diario — si algo cambia, se edita esta hoja, no se improvisa por fuera de ella.

---

## Fase 0 — Cerrar la base de datos (prerrequisito, en curso)

**Primer corrido real de `01_import.R` (2026-09-05, Dr. Monzón):**
```
Sec 2   -- 47,837 filas | universal: 22,316 | específica: 16,866 | SIN FC: 8,655
Sec 3A  -- 342,046 filas | universal: 107,095 | específica: 0 | SIN FC: 234,951
```
Sec 2 pasó de ~0 filas resueltas por tabla específica a 16,866 en esta sesión. Las 5 filas `PROVISIONAL_baja_confianza` (ACEITE+Botella/Lata, CHOCOLATE+Paquete/Frasco, PANES+Funda) fueron validadas por criterio de mercado del Dr. Monzón — ver `data_raw_unidades.xlsx`, columna `nota`.

**Confirmado con el pipeline real corriendo (2026-09-05):**
```
Sec 2   -- 47,837 filas | universal: 22,316 | específica: 16,866 | SIN FC: 8,655
Sec 3A  -- 342,046 filas | universal: 107,095 | específica: 155,770 | SIN FC: 79,181
```
Sec 3A superó la proyección (155,770 vs. ~113,700 esperados) — probablemente por reutilización automática del FC vía el mecanismo `coalesce(presentación, base)` del script cuando algunos hogares sí reportaron presentación explícita para un alimento y otros no.

- [ ] **"Peso por unidad" (el hallazgo de la sesión anterior, ahora cuantificado en ambas secciones):** Sec 2 ~8,655 filas, Sec 3A ~79,181 filas. Top alimentos afectados en Sec 3A: Cebolla roja (12,855), Huevos de granja (11,224), Pan sobado (9,122), Cilantrico (9,063), Ají cubanela (8,704), Ajo (8,685), Plátano verde (7,662). Revisar primero `ENGIH_2018.pdf` (metodología oficial) por si ya define pesos estándar; si no, tablas de porciones FAO/INCAP.
- [x] **Resuelto:** `crosswalk_tablas_composicion.xlsx`, pestaña `Cuest. B Sec 3A`, columna `validado` — las 6 filas con número en vez de booleano ya se corrigieron a mano. De esas 6, dos (id 2936 "Impuesto a vivienda de lujos", id 2392 "Pulseras de metales preciosos") resultaron ser errores de captura reales del crudo ENGIH (1 hogar cada uno, no alimentos) — **eliminadas de la tabla el 2026-09-06**. Se revisaron otras 24 filas con palabras similares (alcohol, tabaco): son categorías legítimas de la sección, sin `ENHANCE_ID` a propósito por no aportar a la fortificación — no se tocan.
- [x] Sec 3A completo — resuelto 2026-09-05. Misma metodología que Sec 2, aplicada a 2,008 combinaciones reales (antes la tabla solo tenía 721, cubriendo el 36%). De 1,372 genuinamente alimento-específicas: 546 con FC asignado (97.9% de las observaciones pendientes), 68 combos (0.66%, incluye variantes menores de "Sopita Concentrada") quedan para revisión manual, 758 sin evidencia (1.5%, cola de muy baja frecuencia). La hoja `Cuest. B Sec 3A` de `data_raw_unidades_ACTUALIZADO.xlsx` fue reconstruida completa (2,008 filas, mismo formato que Sec 2: `id_variedad`, `descripcion`, `unidad_no_estandar`, `FC`, `frec_sec3` corregida, `validacion`, `nota`). Detalle: `data/eda/FC_propuesto_sec3a.csv`.
  - [ ] 68 combos en `REVISAR_MANUAL_alta_dispersion` (ver `data/eda/FC_propuesto_sec3a.csv`) — mayormente n pequeño (3-25 hogares) o rango amplio sin patrón claro de mercado, baja prioridad por impacto (762 observaciones de 342,046 filas totales).
  - [ ] Nota sobre "Sopita Concentrada": su FC principal (Cubito, 15,939 observaciones) ya quedó resuelto con buena confianza — el bloqueador pendiente sigue siendo la decisión de **tratamiento nutricional** en el crosswalk (diferente problema, sigue abierto).
  - [ ] El join de producción en `01_import.R` sigue siendo por `descripcion` (texto), no por `id_variedad` — se verificó que hoy no hay colisiones, pero sigue siendo fràgil a futuro (un cambio de tilde/mayúscula en cualquiera de los dos archivos rompe el match sin avisar). Considerar migrar el join a `id_variedad` cuando haya tiempo.


- [ ] Completar validación del crosswalk Sec 3A (144/772 hechas; quedan ~628)
- [ ] Resolver los ~68 `id_variedad` de Sec 3A ausentes del diccionario oficial (¿versión distinta, o residual real?)
- [ ] Decidir si cubrir los 16 códigos `VARIEDAD` de Sec 2 fuera del crosswalk de 30 (afecta 0.13% de filas — prioridad baja)
- [x] Completar factores FC "Alimento-específico" de **Sec 2** — resuelto 2026-09-05. De 196 combinaciones: 43 ya resueltas por unidad universal, 34 fuera del crosswalk de 30 alimentos (bajo impacto, ver abajo), 119 genuinamente alimento-específicas. De esas 119: 79 con FC asignado con evidencia del propio crudo (`contenido_empaque_presentacion`, mediana por combinación), cubriendo 95.9% de las observaciones; 40 sin evidencia suficiente (1% de las observaciones, baja prioridad). Metodología completa en `data/eda/FC_propuesto_sec2.csv`. Archivo actualizado: `data/raw/data_raw_unidades_ACTUALIZADO.xlsx` (reemplaza a `data_raw_unidades.xlsx` una vez validado).
  - [ ] Sec 3A (721 combinaciones) — pendiente, misma metodología: filtrar por unidad universal real (`FC` no nulo en `diccionario_conversion`, cuidado con códigos que aparecen en la tabla pero sin valor), calcular FC empírico vía `contenido_empaque_presentacion`, clasificar por dispersión.
  - [ ] 5 combinaciones marcadas `PROVISIONAL_baja_confianza` en Sec 2 (ACEITE+Botella, ACEITE+Lata, CHOCOLATE+Paquete, CHOCOLATE+Frasco, PANES+Funda) — decidir con conocimiento de mercado local si el patrón bimodal amerita desagregar en dos presentaciones distintas, o si se acepta la mediana tal cual.
  - [ ] 40 combinaciones `SIN_EVIDENCIA` en Sec 2 (1% de las observaciones pendientes, principalmente unidades de conteo: Unidad, Pieza, Cajita) — requieren peso de referencia externo. Baja prioridad, no bloquean el avance.
  - [ ] Confirmar tabla completa de códigos de unidad (fuente: `docs/Formulario ENGIH B. Gastos diarios del hogar.pdf`, sección "CÓDIGOS DE UNIDADES DE MEDIDA Y DE PRESENTACIÓN", 120 códigos en total, solo ~35 transcritos hasta ahora) — el código 113 en SALAMI no calza con la transcripción parcial actual, sin resolver
  - [ ] Hallazgo arquitectónico (bajo impacto, n=1 en cada caso): "Botellón" está en la tabla universal con FC fijo de 18,900g (densidad de agua), pero se aplica igual sin importar el alimento — revisar si debería tratarse como alimento-específico en vez de universal
- [ ] Corregir el bug de escala ×1000 en las 15 filas de FC específico ya rellenas en Sec 2 — **resuelto de facto**: esas 15 filas correspondían todas a unidades ya cubiertas por la tabla universal (nunca se usaban) y se limpiaron al regenerar el archivo.

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
- [ ] Consumo aparente por AME **y** AFE (mujeres 15-49, embarazadas/lactantes) — **requiere el módulo demográfico de ENGIH (aún sin descargar)**: trae composición del hogar (embarazadas, niños menores, etc.) y hay que conectarlo en `01_import.R` antes de poder calcular esto
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

*Próximo paso inmediato: "peso por unidad" (Sec 2 ~8,655 filas, Sec 3A ~79,181 filas) empezando por Cebolla roja, Huevos de granja, Pan sobado, Cilantrico, Ají cubanela, Ajo, Plátano verde. En paralelo, cuando haya tiempo: los 49 candidatos de Sec 2 y los 68+758 de Sec 3A marcados para revisión manual.*