# Plan de trabajo — ENGIH 2018 → Evidencia Nutricional
*Fecha: 2026-08-27 · Supera y complementa a README (estado operativo) y VISION (estrategia)*

## 0. Contexto: cambio de dirección

En la reunión del grupo de trabajo se redirigió el foco: **Sección 2 (despensa/refrigerador)
es la prioridad**. La Sección 3A queda **congelada en un estado operativo mínimo**
(esqueleto completo de pipeline, crosswalk a 83% de registros, sin la tabla FC por alimento).

Este documento registra, paso a paso, el estado, las decisiones y la ruta. Lo que dice
"✓ (sesión 2026-08-27)" ya está hecho y verificado; lo demás, pendiente con su dueño.

### Descubrimientos críticos de la revisión 2026-08-27 (leer primero)

1. **Dos espacios de llaves que colisionan (CRÍTICO).** Los `id_variedad` de la Sec 3A son
   códigos del **Catálogo de variedades**; los de la Sec 2 son **códigos locales del
   formulario de despensa** (1–30). El mismo número es un alimento distinto en cada sección:
   `2` = GALLETAS DULCES en Sec 2 pero PAN SOBADO en 3A (10,060 registros); `20` = SARDINAS
   EN ACEITE en Sec 2 pero Galletas dulces en 3A (902 registros). Unir por `id_variedad`
   plano habría asignado sardinas con la composición de galletas, en silencio.
   **Solución aplicada:** llave canónica con espacio de nombres — `CAT:<id>` (catálogo, 3A y
   11 códigos de Sec 2) y `SEC2:<id>` (formulario). Implementada en `00_master.R` y
   `03_transform.R`; el crosswalk de Sec 2 lleva `clave_catalogo` para compartir
   resoluciones con 3A cuando aplique.
2. **PM de Sec 2: el script decía 30; el formulario dice 7.** El formulario oficial
   (pág. 4): *"Alimentos y bebidas en existencia **el día 1 y 8 de la entrevista**"*; la
   pregunta 9 (consumo del inventario inicial) se refiere a ese período de 7 días. La guía
   WFP también usa PM=7. El 30 no aparece en ninguna fuente. **Código: `PM_SEC2 = 7`
   (configurable), pendiente de confirmación formal con MIMI.**
3. **La tabla de conversión de unidades no es tan grande como parecía.** Cada registro
   trae los campos de presentación (`cantidad_unidades_presentacion × contenido_empaque_presentacion`,
   con contenido en la unidad declarada). Con ellos + los 9 factores fijos (Gramos, Kilogramos,
   Libra, Onza, Miligramos, Mililitros, Litro, cc, Galón) se convierten a gramos:
   **Sec 2: 79.4% de los registros · Sec 3A: 63.6%**. El resto necesita FC por alimento ×
   unidad: en Sec 2 son **~20 celdas** (hoja `FC_pendientes` del crosswalk SEC2); en 3A, la
   cola grande (Fase 4).
   Evidencia: en 96–99% de las filas con presentación, `cantidad ≤ 5` y en 72% (3A)
   `cantidad == unidades` → `cantidad` es el **conteo de presentaciones**, y el total es
   `unidades × contenido` (regla por defecto `REGLA_PRESENTACION = "presentacion"`).
   Fila donde `cantidad ≠ unidades` = **ambigua** (3A: 27.8% de las filas con presentación;
   Sec 2: 76.0%) → pregunta pendiente a BCRD/MIMI.
4. **Error en la TCA INCAP:** `ENHANCE_ID 70211110` aparece dos veces con alimentos
   distintos ("Elote dulce... enlatado" y "Sal de mesa"). El crosswalk lo usa para
   *Sal en grano* (CAT:4413). El generador MASTER deduplica conservando la fila de la sal
   (con aviso) — **reportar a MIMI el error de origen**.
5. **Conflicto de fuente detectado (1):** CAT:3506 *Bizcocho envasado de vainilla* resuelto
   en INCAP (70214077) y FNDDS (53116000). Gana INCAP por la prioridad documentada.
6. **Sec 2 = 30 ítems del formulario (99.87% de los registros) + 11 códigos de catálogo
   (0.09%) + 5 códigos sin descripción (0.07%)** = 46 llaves. (La cifra "46 variedades"
   circulaba; lo operativo son los 30 ítems.)

---

## 1. Mapa de decisiones pendientes

| # | Decisión | Estado | Recomendación | Dueño |
|---|----------|--------|---------------|-------|
| D1 | PM_SEC2 (7 vs 30) | Pendiente MIMI/BCRD | 7 (formulario + guía WFP). Código ya en 7. | Maicel |
| D2 | Semántica de `cantidad` en filas con presentación (conteo vs total) | Pendiente BCRD/MIMI | Conteo (default). Regla conmutable en 03. Revisar las filas ambigüas (27.8% / 76.0%). | Maicel |
| D3 | `porcentaje_hogar` < 100 (3.8% de registros 3A; 630 con 0) | Aplicado | `Q × pct/100` (default `USAR_PCT_HOGAR=TRUE`); sensibilidad en Analizar. | Grupo |
| D4 | Pesos (`factor_anual`/`factor_expansion`) | Documentado | No usar en perfiles por hogar; ponderar en estimaciones nacionales (fase Analizar). | Grupo |
| D5 | Sec 3C (alimentos recibidos gratuitos) | Fuera de alcance (como 3B) | Documentar en VISION; relevante para la pregunta estratégica 5 (WFP). | Maicel |
| D6 | Atípicos en gramos: criterio de tratamiento (cortar vs excluir) | Flaggeados (P1–P99 por alimento, Paso 7) | Truncar en P99 como default + sensibilidad; decidir en Analizar. Hay casos extremos (p.ej. 100 L de ron "adquiridos"). | Grupo |
| D7 | Unidades de algunas columnas INCAP (p.ej. vitamina D: µg vs UI) | Pendiente | Confirmar contra el diccionario INCAP **antes de publicar** estimaciones. | Maicel |
| D8 | Almacenamiento de datos grandes (xlsx 56 MB en git; llega USDA TCA) | Pendiente | Git LFS o storage externo + reimportación; cuando cierre Sec 2 (Fase 8). | Maicel |
| D9 | Cuestionario A (roster edad/sexo + características hogar) | **Falta en el repo** | Solicitar a BCRD/WFP. Bloquea AFE/AME, adecuación por edad/sexo y estratificación (preguntas 1–2–5). | Maicel |

---

## 2. Fase 0 — Congelar 3A en estado operativo mínimo ✅ (sesión 2026-08-27)

- **0.1 ✓** `scripts/02_eda.R` corregido y ejecutable: columna real (`variedad`, no
  `alimento`), dlookr opcional con fallback a base R (el riesgo de remoción de CRAN que el
  propio script comentaba), y nuevos chequeos 6a–6d: `dia` fuera de 1–7, `porcentaje_hogar`,
  unidades faltantes, presencia de campos de presentación.
- **0.2 ✓** `scripts/03_transform.R` reescrito (era un fragmento no ejecutable):
  fórmula núcleo `Q × FC × PC / PM` implementada con: FC fijas (9 unidades), campos de
  presentación, `porcentaje_hogar`, PC del MASTER, Paso 7 de la guía WFP **sobre gramos**
  (antes se hacía sobre cantidad cruda con unidades mezcladas), agregado por hogar
  (g/día + 8 nutrientes/día), KPIs en consola. Sec 2 usa el mismo código (misma ventana
  de 7 días, `PM_SEC2`).
- **0.3 ✓** `scripts/01_import.R`: nota de PM corregida; el join con composición (que
  duplicaba trabajo de 03 y violaba la regla "solo MASTER") se eliminó y se remitió a 03.
- **0.4** *(en RStudio)* Dependencias: `conflicted, readxl, readr, here, dplyr, janitor,
  writexl` (+ `dlookr` opcional). **Recomendación: crear `DESCRIPTION` + `renv.lock`** —
  hoy el repo no fija versiones (solo un `sessionInfo` suelto); para un proyecto cuyo
  entregable es "metodología reproducible" es deuda alta.
- **0.5 ✓ KPI base (esperados; conciliar al correr en RStudio):**

  | Métrica | Sec 3A | Sec 2 |
  |---|---|---|
  | Registros | 342,046 | 47,837 |
  | Convertibles a gramos (FC fijas + presentación) | 217,505 (63.6%) | 37,993 (79.4%) |
  | Filas con composición resuelta | 285,378 (83.4%) | 0 (starter sin llenar) |
  | Gramos con composición resuelta | 42.9% | 0% |
  | Fila con presentación ambigua | 32,818 (27.8% de 118,227) | 14,768 (76.0% de 19,421) |
  | Atípicos P1–P99 (gramos) | 3,624 | 553 |
  | Top pendientes por gramos | 594 Agua purificada (111 t/sem), 623 Ron añejo, 1892 Alimentos p/animales, 645 Cerveza clara, 3588 Ñame amarillo, 117 Carne de gallina | 7 ARROZ, 16 ACEITE, 29 AZÚCARES, 27 HABICHUELAS, 13 LECHE LÍQUIDA, 26 PAPAS |

- **0.6 ✓ Higiene:** `.gitignore` actualizado (`.RDataTmp*`); `.RDataTmp*` (47 MB de
  temporales R) fuera de git. `data/clean/consumo_diario_*_hogar.csv` quedan como salidas
  generadas (gitignore'd; se regeneran con 03).

## 3. Fase 1 — Cerrar la capa MASTER ✅ (sesión 2026-08-27)

- **1.1 ✓** `scripts/00_master.R` — generador canónico de las dos capas maestras:
  - Reglas: `estado` (resuelto/excluido/pendiente), prioridad INCAP > USDA > FNDDS,
    llaves `CAT:`/`SEC2:`, nombres de ID con espacio (`INCAP:70213002`), dedup de IDs
    duplicados con aviso (caso 70211110 → fila de la sal).
  - `food_composition_MASTER`: solo filas referenciadas por el crosswalk resuelto;
    34 columnas estándar; `pc_factor` y `base_composicion` por fuente
    (INCAP: 100 g comestibles, PC = EDIBLE; FNDDS: 100 g como se consume, PC = 1).
  - Punto de extensión: un crosswalk nuevo = 1 bloque de 3 líneas (ver el de SEC2).
- **1.2 ✓** Artefactos generados y verificados:
  - `data/master/crosswalk_variedad_MASTER.xlsx`: **818 llaves** (772 CAT/3A + 11 CAT/Sec2
    + 35 SEC2) · **137 resueltas** (134 INCAP + 3 FNDDS; 1 conflicto resuelto por
    prioridad) · **10 excluidas** (tabaco, pañales…) · **671 pendientes** (visibles, con
    frecuencia y notas — la cola de trabajo).
  - `data/master/food_composition_MASTER.xlsx`: **78 alimentos** (75 INCAP + 3 FNDDS).
- **1.3 ✓** La capa está **operativa y lista para vincular**: 03 la consume; al llenar
  el crosswalk de Sec 2 y re-correr 00, se amplía sola (tabla "viva" según la visión).
- **1.5** *(pendiente)* Confirmar unidades INCAP (D7) y reportar el ID duplicado a MIMI.

## 4. Fase 2 — Crosswalk de la despensa (Sec 2) ← **TU TAREA ACTIVA**

- **2.1 ✓ Starter creado:** `data/raw/crosswalk_variedad_SEC2.xlsx`
  - Hoja `Instrucciones`: flujo, reglas de aceptación y nota de llaves.
  - Hoja `Datos`: **46 filas** (30 ítems del formulario + 11 de catálogo + 5 sin nombre),
    cada una con `freq_sec2`, `unidades_top` (las unidades reales del dato), y
    **sugerencia INCAP curada** (`sugerencia_ENHANCE_ID` + nombre + grupo + tipo + nota).
    Columnas de decisión: `fuente_composicion`, `id_composicion_final`,
    `tipo_equivalencia`, `validado`, `notas`.
  - Hoja `FC_pendientes`: la mini-tabla de conversión de despensa (~20 celdas) con
    valores referencia **placeholder** a validar.
- **2.2 Cómo llenarlo (por ítem, ~30 min c/u):**
  1. Leer `descripcion_item` + `unidades_top` (¿en qué unidades se declaró?).
  2. Validar o reemplazar la sugerencia contra `food_composition_INCAP.xlsx`; si es gap,
     elegir `fuente_composicion` = USDA/FNDDS y su ID.
  3. Copiar el ID a `id_composicion_final`, fijar `tipo_equivalencia`, marcar
     `validado = TRUE`. **Regla de aceptación:** `validado = TRUE` exige ID final no
     vacío **o** `no_alimento_excluir`. (Corrige la ambigüedad anterior donde 16 filas
     estaban TRUE sin ID y el pipeline las descartaba en silencio — p.ej. Sopita, el
     alimento #1 de 3A.)
  4. Documentar en `notas` toda decisión de representante (categorías genéricas) y
     trampa semántica (ver 2.3).
  5. Al terminar cada racha: `00_master.R` → ver KPI en consola → `03_transform.R`.
- **2.3 Decisiones que el starter señala (las difíciles, primero):**
  - **TRAMPA SEMÁNTICA (27/28):** en RD "habichuelas" = frijol (negro); en INCAP
    centroamericano "habichuelas" = ejotes/verdes (70211255). Sugerida: 70209060
    *Frijol negro, grano seco* (sustituto por criterio). La enlatada (28) **no existe en
    INCAP** → gap a USDA/FNDDS.
  - **Categorías genéricas → alimento_representativo documentado:** PANES (1,
    pan de agua), ACEITE (16, soya), PESCADO (11), MARISCOS (12, camarón), LECHE LÍQUIDA
    (13, decidir grasa/fortificación), AZÚCARES (29, blanca; ver versiones +vit A),
    ARROZ (7, "enrio" = industrializado: relevante para el escenario de fortificación).
  - **Gaps INCAP → fuentes externas:** PICA PICA (21), SARDINAS EN AGUA (19),
    HABICHUELAS ENLATADAS (28), CEREALES DE ARROZ (73), PALOMITAS (32), TURQUITOS (34),
    VIOLADOS (35). Es el trabajo que alimenta `crosswalk_variedad_USDA.xlsx` /
    `_FNDDS.xlsx` (hoy: 3 filas sin validar y 2 sin resolver).
  - **Códigos sin nombre (0, 31, 33, 45, 50; 62 registros totales):** verificar contra
    BCRD; si son "otros"/errores de codificación → `no_alimento_excluir` documentado.
- **2.4 Tabla FC de despensa (hoja `FC_pendientes`):** validar ~20 pesos de referencia
  (huevo ~60 g c/cáscara, papa ~150 g, plátano verde ~300 g c/cáscara, guineíto ~80 g,
  lata ~160 g, jarro ~1.5 L, pieza de pollo ~500 g…). Fuentes: BCRD/MIMI si tienen
  tabla de pesos, o tabla de porciones de referencia documentada. Con 30 alimentos es
  trabajo de 1–2 días, no de semanas.
- **2.5 Aplicar la FC:** en `03_transform.R` el placeholder es el tibble `FC_FIJAS`;
  se agrega un `FC_DESPENSA` (item × unidad → gramos) que se consulta cuando la FC fija
  no aplica. *(Pequeño edit listo para hacer en la sesión de cierre de Fase 2.)*
- **2.6 Cierre de Fase 2:** KPI objetivo → los 30 ítems resueltos (o excluidos
  documentados) ⇒ ~99.9% de los registros de Sec 2 con composición; re-correr 00 + 03.

## 5. Fase 3 — Pipeline de Sec 2 (se habilita solo)

1. `00_master.R` → MASTER ampliado (SE2 pasa de 0 a 137+ llaves resueltas).
2. `03_transform.R` → `data/clean/consumo_diario_2_hogar.csv` + QC en gramos.
3. Combinación Sec 2 + 3A (mismo período de 7 días): consumo del hogar =
   *descuento de inventario inicial* (Sec 2, PM=7) + *adquisiciones* (3A, /7).
   Documentar en VISION una vez MIMI confirme D1/D2 (editar la sección 4 del documento).
4. KPI de cobertura de Sec 2 contra el objetivo de 2.6; atípicos (553 en la base) a
   revisar contra D6.

## 6. Fase 4 — Reabrir 3A (cuando Sec 2 cierre)

- Faltan para el consumo aparente completo de 3A: la FC por alimento×unidad de los
  ~36.4% de registros no convertibles (772 alimentos × unidades — ahí sí es grande).
- Estrategia por tramos (ordenar por gramos, no por frecuencia):
  1. **Tramo A (quick wins, ~1 día):** resolver los top pendientes por gramos:
     agua purificada (594; 111 t/semana — decisión: excluir documentado o mapear a
     agua), ron añejo (623), alimentos para animales (1892 → excluir), cerveza clara
     (645), ñame amarillo (3588), carne de gallina (117).
  2. **Tramo B (2 semanas):** top 100 variedades por gramos de la cola → cubrir ~90%
     del resto; unidades "Unidad"/"Atado"/"Diente" requieren pesos de referencia por
     alimento (mismo mecanismo de 2.4, a mayor escala).
  3. **Tramo C (long tail):** documentar como gap con % de gramos afectado.
- El SOPITA (569, 5.3% de registros) sigue siendo el pendiente insignia: decidir
  modelado (USDA *chicken broth/bouillon dry* — la nota del crosswalk ya cuantifica el
  riesgo de usar la versión preparada de FNDDS).

## 7. Fase 5 — Insumos faltantes: Cuestionario A (D9)

- Roster de miembros (edad/sexo) → AFE/AME (`04_equivalente_adulto.R`, hoy vacío),
  adecuación por edad/sexo (`05`, hoy vacío).
- Características del hogar (quintil de gasto, región, urbano/rural) → covariables de
  estratificación y mapas (prometidas en la hoja de ruta de VISION).
- **Acción: solicitar los microdatos Cuestionario A a BCRD/WFP.** Es el único bloqueador
  externo de las preguntas estratégicas 1–2–5.

## 8. Fase 6 — Analizar / Modelar / Comunicar (marco Tang)

- Cobertura de vehículos fortificables (alcance + cantidad por AFE), densidad
  (mg/1000 kcal), equidad (quintil/región/urbano-rural), escenarios de fortificación
  (observado → cumplimiento actual → mejorado → alternativas, con chequeo de UL).
- Pesos muestrales en estimaciones nacionales (D4). `06_report.qmd` (hoy plantilla).

## 9. Fase 7 — Higiene de repositorio (cuando cierre Sec 2)

- Git LFS o storage externo para `Registros_Cuestionario_B.xlsx` (56 MB; .git = 116 MB)
  y para la TCA USDA que llegue (D8).
- `DESCRIPTION` + `renv` (0.4). Un solo commit en el histórico del repo: empezar a
  commitear por fase desde ya (cada cierre de fase = 1 commit con su KPI).

---

## 10. Registro de cambios — sesión 2026-08-27

**Creados**
- `scripts/00_master.R` (generador de capas maestras)
- `scripts/03_transform.R` (reescrito; esqueleto operativo)
- `data/raw/crosswalk_variedad_SEC2.xlsx` (starter: Instrucciones + Datos 46 + FC_pendientes)
- `data/master/crosswalk_variedad_MASTER.xlsx` (818 llaves)
- `data/master/food_composition_MASTER.xlsx` (78 alimentos)
- `data/clean/consumo_diario_3A_hogar.csv`, `data/clean/consumo_diario_2_hogar.csv` (salidas)
- `data/eda/qc_gramos_3A.csv`, `data/eda/qc_gramos_2.csv`
- `PLAN_DE_TRABAJO.md` (este documento)

**Modificados**
- `scripts/02_eda.R` (corregido: columna `variedad`, dlookr opcional, chequeos 6a–6d)
- `scripts/01_import.R` (nota PM corregida; join de composición removido → 03)
- `README.md` (estado operativo)
- `VISION_Y_ARQUITECTURA_PROYECTO.md` (correcciones menores + decisión 2026-08-27)
- `.gitignore` (`.RDataTmp*`, salidas de 03)

**Verificado contra datos (no asumido)**
- Colisión de llaves 3A/Sec 2 (tabla completa en el descubrimiento 1)
- `PM`: formulario pág. 4 ("día 1 y 8"); guía WFP (PM=7); comentario previo del script (30)
- Estructura de presentación: 96–99% `cantidad ≤ 5`; 72% (3A) `cantidad == unidades`
- ID duplicado en TCA INCAP: 70211110 (elote enlatado / sal de mesa)
- KPIs de la tabla 0.5 (generados con espejo de verificación; conciliar en RStudio)

**Nota de verificación:** R no está disponible en este entorno (CRAN bloqueado). Los
artefactos `data/master/*` y `data/clean/consumo_diario_*` fueron generados con un
espejo de verificación (Python) que implementa **regla por regla** la misma lógica de
`00_master.R` y `03_transform.R`. Al correr `00_master.R` y `03_transform.R` en RStudio,
los KPI de la tabla 0.5 deben reproducirse; cualquier desvío es un bug a reportar.
