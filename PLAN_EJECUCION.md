# Plan de ejecución — ENGIH 2018 → Evidencia Nutricional (WFP)

**Creado:** 2026-09-10, tras la auditoría externa (`INFORME_AUDITORIA_2026-09-10.md`).
**Para qué existe:** convertir la estrategia acordada el 2026-09-09 ("avanzar por fases con los datos como están, no perfeccionar datos antes de avanzar") en un plan operativo con oleadas, reglas de decisión y criterios de terminado. Este documento **no reemplaza** a `HOJA_DE_RUTA_PROYECTO.md` (que sigue siendo el log): define el *cómo y cuándo*.

---

## 1. Veredicto de factibilidad

**VIABLE, y más cerca de lo que la propia documentación cree.** La evidencia:

1. **El núcleo metodológico ya está demostrado.** La réplica independiente (Python) del pipeline completo 01→05 corrió de punta a punta sobre los datos reales y reprodujo *exactamente* las cifras documentadas (11/13, incluidos desgloses por nivel de FC y el IC de cobertura). La fórmula MIMI (Q×FC×PC/PM) está correctamente implementada; el EMA está verificado hasta la fuente primaria FAO/WHO/UNU 2004.
2. **No hay bloqueadores de datos duros.** Lo que la documentación consideraba faltante, en gran parte ya está en el repo (variables de diseño muestral ESTRATO/UPM, región/urbano-rural, módulo demográfico — ver H5 de la auditoría). El crosswalk al 55% y el PC al 19% (144/770) limitan la cobertura, no la viabilidad.
3. **El resultado central ya existe en versión preliminar:** ingesta aparente de energía, hierro, folato y vitamina A por EMA, con escenarios de fortificación (§4 de la auditoría). La mediana de energía (2,102 kcal/EMA) pasa el sanity check contra hojas de balance — el pipeline entero produce números plausibles.
4. **El riesgo dominante no es técnico:** es de ejecución (proyecto de una persona, sesiones asistidas por IA con riesgo de perder la estrategia, historial git de 1 commit, decisiones metodológicas sin registrar). Por eso este plan pone tanto peso en protocolo y trazabilidad como en análisis.

**Estimación honesta a entregables:** con ~2 semanas de trabajo enfocado (ver oleadas), hay versión defendible de 05+06 (resultados 4 nutrientes con escenarios y diseño muestral completo). El artículo y el dashboard son función de iteración con Carlos/Daniel/Santiago, no de pipeline.

---

## 2. La estrategia "avanzar y volver" — formalizada

El principio: **nada se perfecciona antes de avanzar, pero nada se avanza sin medir lo que se deja atrás.**

**Reglas de decisión:**

1. **Regla de avance:** un dato faltante nunca bloquea el pipeline. Entra al backlog con su **impacto medido** (filas y, cuando se pueda, gramos implicados), no como item genérico de lista.
2. **Regla de retorno (backfill priorizado):** se rellena en orden de impacto medido, no de orden alfabético ni de comodidad. La auditoría ya genera la lista: `data/audit/prioridad_relleno_excluidos.csv` (excluidos del cálculo por filas) + `data/eda/pendiente_llenar_enhance_id_confirmados.csv` (154 mapeos listos para copiar).
3. **Regla de honestidad:** todo resultado se publica con su % de cobertura de filas (Sec2 90.7% / Sec3A 71.9% al 10-09) y la lista de top exclusiones. La cobertura sube con cada oleada de backfill; el resultado se recalcula y ambas cifras se mueven juntas.
4. **Regla de congelamiento:** cada oleada termina con commit(s) atómicos + entrada fechada en HOJA_DE_RUTA + tag de datos si cambió un Excel. Sin esto no se abre la siguiente oleada.
5. **La señal de alarma acordada (2026-09-09) se mantiene:** si una sesión nueva propone "sigamos afinando datos" en vez de avanzar, es la señal de que se perdió la estrategia — corregir hacia el entregable más cercano.

**Cadencia sugerida:** oleadas de ~3-5 días de trabajo, cada una termina con algo demostrable (número, gráfico, reporte renderizado). El backfill vive dentro de cada oleada como ítem acotado (30-90 min), no como fase separada infinita.

---

## 3. Oleadas

### Oleada 1 — Cerrar 05 y validar (objetivo: resultado central en R, verificado) — ~2-3 días
1. **Correr `01_import.R` → `05` completo en RStudio** (por primera vez con el 05 completo). Contrasta contra los números esperados documentados al final del script (producidos por la réplica Python). Diferencias <1-2% = redondeo; mayores = investigar (principio 5).
2. **Decisión H3 (la más importante del proyecto):** línea base de fortificación. Aprobar (b) "norma RD 2018" como baseline; decidir pan/pastas/galletas (fortificación voluntaria en RD — FFI); verificar si "Arroz selecto" estaba realmente enriquecido en 2018. Con Daniel/Carlos: 1 reunión, propuesta por escrito de antemano.
3. **Rellenar los 154 enhance_id** (`data/eda/pendiente_llenar_enhence_id_confirmados.csv`... nombre exacto: `pendiente_llenar_enhance_id_confirmados.csv`): revisar la lista (ojo a las 2-3 marcadas), copiar a `enhance_id` con `fuente` correcto. Impacto: +9,172 registros con nutrientes. 30-45 min + regenerar.
4. **Quick wins de cobertura de alto impacto:** PC=1.0 + entrada FNDDS para **Sopita Concentrada** (18,087 filas, ya hay trabajo de campo propio); peso-por-unidad para **Plátano verde, Guineo verde, Cilantro** (ya medidos en campo según hoja de ruta — solo cargarlos con la misma mecánica de unidad=1, y **verificar primero que no exista fila previa con la misma clave** — fue el bug H1).
5. `renv::init()` + commit del lockfile (seguro de reproducibilidad, 15 min).

**Terminado = :** `05` corre en R y reproduce la réplica Python; existe `data/clean/data_ingesta_hogar.csv`; decisión H3 documentada en HOJA_DE_RUTA; cobertura Sec3A ≥ 78% de filas.

### Oleada 2 — Diseño muestral completo, equidad y reporte base — ~3-4 días
1. **`svydesign()` con ESTRATO/UPM/FACTOR_EXPANSION** en 03/05 (las variables ya están — H5). Elimina el descargo de "IC subestimado" de todos los resultados. Conectar región/urbano-rural desde la hoja "Base".
2. **Análisis de equidad:** resultados por `GRUPO_REGION` (4 regiones), urbano/rural (`DES_ESTRATO`), y quintil (de gasto alimentario o ingreso — el archivo sociodemográfico tiene 1,132 columnas; evaluar cuál variable de ingreso usar, documentar la elección).
3. **`06_report.qmd` v1** con el contenido real de 05: los 4 nutrientes, los 3 escenarios (a/b/c-mixto nunca como baseline), top contribuyentes, cobertura reportada, limitaciones. El skeleton ya tiene la estructura correcta — llenarlo con resultados, no con prosa anticipada.
4. Sensibilidad de outliers (regla actual 5×P99.5): reportar % de filas excluidas y repetir el resultado con winsorización como anexo.

**Terminado = :** ICs con diseño completo; reporte Quarto renderizado con 4 nutrientes × escenarios × equidad básica; sin descargos metodológicos evitables.

### Oleada 3 — Ampliar nutrientes y backfill de cobertura — ~1 semana
1. **Ampliar de 4 a ~10-15 nutrientes** (zinc, B12, calcio, vit C, D, sodio — el sodio ya tiene el trabajo de campo de la sopita). La arquitectura de 05 no cambia: es añadir columnas a la transmutación y a la tabla de equivalencia (verificando unidades INCAP vs FNDDS por nutriente, como se hizo con folato).
2. **Backfill mayor de `food_factors`** (PC): hoy 144/770 alimentos. Priorizar por la lista de excluidos por filas (plátano, guineo, aguacate, tomates, ají gustoso, apio, naranja agria…). Para frutas/verdaderas frecuentes, PC de INCAP es recuperable del propio `food_composition_INCAP.xlsx` (muchas entradas ya traen EDIBLE o es 1.0 para items sin cáscara descartada — **verificar por alimento, no asumir**).
3. **Disponibilidad neta Sec2+Sec3A** para almacenables (arroz, aceite, azúcar, harina, habichuelas, leche) — la pieza metodológica grande pendiente de Fase 0 que decide si Sec 2 se usa como fuente de consumo o solo inventario.
4. Los 68 combos `REVISAR_MANUAL` de Sec 3A y los 49 candidatos de Sec 2 — solo si el impacto en filas lo justifica (la lista de excluidos manda).

**Terminado = :** cobertura Sec3A ≥ 85% de filas; ≥10 nutrientes; disponibilidad neta documentada (usada o descartada con justificación).

### Oleada 4 — Dashboard y artículo
1. Dashboard (audiencia/decisiones primero — los ítems ya están en Fase 3 de la hoja de ruta; con los datos de equidad de la Oleada 2 el prototipo tiene con qué llenarse).
2. Artículo siguiendo Tang et al. 2021 como molde; las secciones de métodos ya están casi escritas por la documentación acumulada del repo (crosswalk, FC, PC, EMA, escenarios — es su gran ventaja competitiva).
3. Revisión editorial/creativa (ítem ya anotado en Fase 3): cuando haya contenido real.

---

## 4. Matriz de riesgos (probabilidad × impacto × mitigación)

| # | Riesgo | P | I | Mitigación | Estado |
|---|---|---|---|---|---|
| R1 | **Pérdida de estrategia entre sesiones** (proyecto vivo + IA: cada sesión "olvida" el plan) | Alta | Alto | Este documento + "PRIORIDAD ACTUAL" en cabecera de HOJA_DE_RUTA + la señal de alarma acordada; nunca borrar la estrategia al reorganizar | 🟡 mitigado si se sigue el protocolo §5 |
| R2 | **Corrupción silenciosa por joins** (fan-out/filas inertes — ya ocurrió 2 veces) | Media | Alto | `verificar_claves_join()` ya instalado en 01; regla de oro: *toda fila nueva en un Excel de join se escribe por nombre de columna y se corrobora que no exista la clave* | 🟢 mitigado |
| R3 | **Conclusión errónea por línea base de fortificación invertida** (H3) | Alta (si no se decide) | Muy alto | Decisión Oleada 1 ítem 2; el mixto (c) nunca se reporta como baseline | 🔴 pendiente |
| R4 | **Sesgo de cobertura no reportado** (resultados sobre 72-91% de filas) | Media | Alto | Regla de honestidad §2.3: cobertura junto a todo resultado; recalcular con cada backfill | 🟢 regla definida |
| R5 | **Proyecto unipersonal** (continuidad, cuello de botella, conocimiento tácito) | Media | Alto | Trazabilidad total ( commits atómicos + notas en Excel + HOJA_DE_RUTA como log); este plan + auditoría permiten retomar sin contexto tácito | 🟡 en mejora |
| R6 | **Historial git de 1 commit** (principio 6 sin respaldo real) | Cierta | Medio | Commits atómicos desde ya; tag `datos-2026-09-10` tras las correcciones; nunca reescribir Excel sin nota | 🔴 corregir desde ahora |
| R7 | **Reproducibilidad** (dlookr fuera de CRAN, sin renv, sin registro de versión R) | Media | Medio | renv en Oleada 1; sessionInfo ya se guarda en `data/eda/sessionInfo_02_eda.txt` (buen hábito — extender a 01 y 05) | 🔴 pendiente (30 min) |
| R8 | **Join por texto (descripcion) en Sec 3A** (rompe por tildes sin avisar) | Baja | Alto | Migrar a `id_variedad` (backlog existente); mientras tanto, la réplica Python sirve como detector de divergencias de conteo de filas (342,046 esperadas) | 🟡 backlog |
| R9 | **Interpretación de resultados a nivel hogar como individual** (EAR cutoff en hogar-por-EMA) | Media | Alto | Etiquetar siempre como ilustrativo; el marco de probabilidad (Fase 2, método MIMI/Tang) es el paso formal | 🟡 por diseño |
| R10 | **Scope creep** (Sec 3B fuera del hogar, 65 nutrientes de una, dashboard prematuro) | Media | Medio | Alcance congelado en HOJA_DE_RUTA; la regla "4 nutrientes primero" ya lo demostró; cada ampliación pasa por el log | 🟢 disciplina existente |
| R11 | **Excel como fuente de verdad** (sin diff legible, errores de tipeo ya ocurridos ×2) | Media | Medio | A corto plazo: checks automáticos + notas en celda; a mediano: considerar exportar las tablas de join a CSV versionable (decisión del equipo, no urgente) | 🟡 decisión pendiente |
| R12 | **Dependencia de validación externa** (Daniel/Carlos/Santiago: 21 alimentos sin fuente, aprobación sopita, decisión H3) | Alta | Medio | Lista consolidada de preguntas por reunión (no ping-pong); mandar propuesta escrita antes; mientras tanto: supuesto marcado, resultado etiquetado | 🟡 gestionar |

---

## 5. Protocolo de sesión (para no perder el hilo — complementa el README)

1. **Al empezar:** leer `README.md` → "PRIORIDAD ACTUAL" de `HOJA_DE_RUTA_PROYECTO.md` → la oleada activa de este plan. Nada más.
2. **Al terminar la sesión:** actualizar README (estado + fecha), añadir entrada fechada a HOJA_DE_RUTA, commit(s) con mensaje que explique el *porqué*. Si cambió un Excel de datos: nota en la celda/columna correspondiente.
3. **Al tocar un Excel de join:** fila nueva por nombre de columna (nunca por posición — bug del 09-08); verificar clave no duplicada; el script ahora grita si se rompió, pero mejor no llegar ahí.
4. **Al publicar una cifra:** cobertura al lado, fuente/benchmark de contraste, y fecha. "Sin fecha, la cifra miente" (lección del 254,905).
5. **Contraste R↔Python:** ante cualquier resultado importante, correr `scripts/audit/verificacion_cruzada_pipeline.py` y comparar contra el pipeline R. Dos implementaciones que coinciden es el estándar de evidencia de este proyecto.

---

## 6. Criterios de terminado globales (definition of done del proyecto)

- **Pipeline:** 01→06 corre de punta a punta en una máquina limpia (renv), sin warnings ignorados, con los checks de integridad en verde.
- **Resultados:** los 4+ nutrientes con escenarios (a)-(d) de Santiago, ICs con diseño muestral completo, equidad por región/zona/quintil, cobertura reportada en cada tabla.
- **Trazabilidad:** cada cifra del artículo/dashboard traza a dato crudo + transformación, o a fuente externa citada con documento y sección (principio 3).
- **Honestidad:** limitaciones documentadas (HCES vs individual, cobertura, supuestos de fortificación, outliers) presentes en cada entregable — la lista ya existe en la auditoría y en los scripts.
