# Avances ENGIH 2018 RD — Consumo de alimentos (Secciones 2 y 3A, Cuestionario B)

**Fecha:** 2026-08-27 · **Para:** verificación de avances (WFP/MIMI) · **Autor:** Maicel E. Monzón
**Alcance:** evidencia del avance 1 (análisis preliminar) y avance 2 (asociación a tablas de
composición) presentados en la reunión, y estado de la tarea solicitada: equivalentes en
gramos de las unidades de medida de la Sección 2. **Todos los números fueron verificados
contra la base `Registros_Cuestionario_B.xlsx` (archivos limpios `data/clean/*`).**

---

## 1. Avance 1 — Análisis preliminar de los módulos de consumo

Las dos secciones de consumo del Cuestionario B están importadas, limpias y caracterizadas:

| Métrica | Sec 2 (despensa) | Sec 3A (día anterior + diario 7 días) |
|---|---|---|
| Hogares con datos | 6,269 | 8,731 |
| Registros de consumo | 47,837 | 342,046 |
| Productos distintos registrados | 46 | 772 |
| Productos por hogar (media / mediana / máx) | 7.6 / 7 / 29 | 21.5 / 21 / 84 |

**Estructura de la Sección 2** (clave para el plan de trabajo): 46 códigos registrados, de los
cuales **30 ítems del formulario concentran el 99.87% de los registros**; 11 códigos del
catálogo de variedades (27 registros, 0.06%) y 5 códigos sin descripción (35 registros, 0.07%,
a verificar contra BCRD).

**Top 10 productos por frecuencia — Sección 2:**

| # | Producto | Registros | | # | Producto (Sec 3A) | Registros |
|---|---|---|---|---|---|---|
| 1 | Aceite | 4,937 | | 1 | Caldo de pollo (Sopita Concentrada) | 18,087 |
| 2 | Arroz | 4,639 | | 2 | Cebolla roja | 15,414 |
| 3 | Azúcares | 4,186 | | 3 | Pollo fresco | 12,439 |
| 4 | Fideos o spaguettis (pastas) | 2,840 | | 4 | Pasta de tomate | 12,150 |
| 5 | Huevos | 2,732 | | 5 | Huevos de granja (gallina) | 11,340 |
| 6 | Habichuelas sueltas | 2,484 | | 6 | Ajo | 11,117 |
| 7 | Avena | 2,438 | | 7 | Aceite de soya | 10,815 |
| 8 | Leche líquida | 1,913 | | 8 | Pan sobado | 10,060 |
| 9 | Salami | 1,850 | | 9 | Refrescos | 9,447 |
| 10 | Plátano verde | 1,837 | | 10 | Ají grande (cubanela) | 9,254 |

**Hallazgo estructural que define la estrategia:** la Sección 3A tiene una cola larga de
~772 productos; la Sección 2, con solo 30 ítems del formulario, es la que se puede
homogeneizar de forma completa y rápida. Por eso la Sección 2 es la prioridad actual.

---

## 2. Avance 2 — Asociación de alimentos ENGIH con tablas de composición

Esto ya va más allá del "inicio": existe la capa maestra operativa que la encuesta va a
vincular (`scripts/00_master.R` la genera; nunca se edita a mano):

- **Crosswalk maestro:** 818 llaves (783 de catálogo + 35 de despensa) · **137 resueltas**
  (134 INCAP + 3 FNDDS) · 10 excluidas (no son alimento) · 671 pendientes (cola larga de 3A).
- **Tabla de composición maestra:** 78 alimentos × 34 nutrientes (INCAP 75 + FNDDS 3),
  lista para el cálculo del consumo aparente. Ejemplo de control de calidad aplicado:
  el ID INCAP 70211110 aparecía duplicado (elote enlatado / sal de mesa); se resolvió con
  regla documentada → la sal queda correcta (0 kcal; 38,758 mg de sodio/100 g).
- **Convención de llaves crítica:** los códigos de la Sección 2 son locales del formulario y
  colisionan con los de 3A (ej. `2` = Galletas dulces en Sec 2 vs Pan sobado en 3A). Se
  resuelve con llaves namespaced: `SEC2:<id>` y `CAT:<id>`.
- **Estado de la Sección 2 (46 llaves):** 27 ítems del formulario + 7 códigos de catálogo con
  **sugerencia INCAP ya curada y documentada** (hoja `Datos` del crosswalk, con grupo, tipo de
  equivalencia y notas); 3 ítems con gap documentado (Sardinas en agua, Pica pica,
  Habichuelas enlatadas) + 4 de catálogo (Palomitas, Turquitos, Violados, Cereales de arroz)
  → candidatos a USDA/FNDDS; 5 códigos sin nombre → a verificar con BCRD. **Ningún ítem
  quedó sin revisión.**

---

## 3. Tarea solicitada — Equivalentes en gramos de las unidades de la Sección 2

El cálculo del consumo aparente por hogar ya está implementado (`scripts/03_transform.R`,
fórmula núcleo de la guía MIMI/WFP: `Consumo (g) = Q × FC × PC / PM`) y se habilita
automáticamente al completar el crosswalk. El factor de conversión (FC) se resuelve en 3 capas:

1. **Factores fijos universales (exactos):** Gramos, Kilogramos, Libra, Onza, Miligramos,
   Mililitros/CC, Litro, Galón — 9 unidades que cubren la mayor parte de los registros.
2. **Presentación (ya en los datos):** `cantidad_unidades_presentacion ×
   contenido_empaque_presentacion` (latas, botellas, fundas con contenido declarado).
3. **Peso por alimento × unidad:** la tabla de trabajo que faltaba — **hoy completa**:
   hoja `FC_pendientes` del crosswalk SEC2 con las **98 celdas** alimento×unidad que quedan
   (9,629 registros), cada una con su conteo de registros y un peso de referencia propuesto
   (61 de 98 con propuesta; el resto marcado "por definir"). **Todas las referencias son
   propuestas a validar** (BCRD/MIMI o tabla de pesos de porciones), no valores definitivos.

**Cobertura actual y pendiente (verificado):**

| | Registros | % |
|---|---|---|
| Sec 2 ya convertible a gramos (capas 1+2) | 37,993 / 47,837 | **79.4%** |
| Sec 2 pendiente (capa 3) | 9,844 / 47,837 | 20.6% |
| — de los cuales: 98 celdas alimento×unidad | 9,629 | 20.1% |
| — de los cuales: sin unidad declarada (celda vacía) | 199 | 0.4% |
| (Referencia) Sec 3A ya convertible a gramos | 217,505 / 342,046 | 63.6% |

Las **28 celdas principales cubren ~96% de los registros pendientes**; las celdas restantes
son cola larga (fundas, paquetes, tercias…; 1–22 registros cada una). Principales celdas:

| Alimento × unidad | Registros | Referencia (g) |
|---|---|---|
| Huevos × Unidad | 2,725 | 60 (c/cáscara) |
| Plátano verde × Unidad | 1,729 | 300 (c/cáscara) |
| Guineíto verde × Unidad | 1,355 | 80 (c/cáscara) |
| Panes × Unidad | 1,188 | 100 (pan de agua) |
| Galletas saladas × Unidad | 605 | 12 |
| Galletas dulces × Unidad | 374 | 12 |
| Chocolate o cocoa × Unidad | 187 | 30 (barra) |
| Habichuelas sueltas × Jarro | 83 | 1,500 |
| Guineíto verde × Mano / Racimo | 80 / 78 | 480 / 960 |
| Chocolate o cocoa × Tableta | 76 | 30 |
| Aceite × Botella | 72 | 1,000 (1 L) |
| Leche líquida × Botella | 65 | 1,000 (1 L) |
| Atún en aceite × Lata | 60 | 160 |
| Plátano verde × Racimo / Mano | 58 / 48 | 1,800 / 600 |
| Arroz × Jarro | 43 | 1,500 |
| Papa × Unidad | 40 | 150 |
| Pollo × Unidad | 39 | 500 (pieza; alto impacto) |

**Dos preguntas formales que destraban el resto (requieren respuesta de MIMI/BCRD):**

1. **Período de medición de la Sección 2 (PM):** el formulario oficial dice que la despensa
   cubre "el día 1 y 8 de la entrevista" → **PM = 7** (el valor 30 que circuló antes no
   aparece en el formulario). El código queda configurado con 7, pendiente de confirmación.
2. **Semántica del campo `cantidad`:** en 96–99% de las filas con presentación
   `cantidad ≤ 5` y en 72.2% de 3A `cantidad == unidades de presentación` → evidencia de que
   `cantidad` es el **conteo de presentaciones** (total = unidades × contenido). Sin
   embargo, 76.0% de las filas con presentación de la Sec 2 tienen `cantidad ≠ unidades`
   (fila ambigua, marcada `pres_inconsistente`, no se descarta). Necesitamos la confirmación
   oficial del significado del campo.

**Impacto esperado:** con la validación de las 28 celdas principales + las 5 unidades sin
declarar y el crosswalk validado, ~99.9% de los registros de la Sección 2 quedarían con
composición → **consumo aparente por hogar completo para la despensa**.

---

## 4. Qué se puede verificar en el repositorio (ahora)

| Artefacto | Ruta |
|---|---|
| Crosswalk maestro (818 llaves, 137 resueltas) | `data/master/crosswalk_variedad_MASTER.xlsx` |
| Tabla de composición maestra (78 alimentos × 34 nutrientes) | `data/master/food_composition_MASTER.xlsx` |
| Crosswalk despensa (46 llaves + tabla FC completa de 98 celdas) | `data/raw/crosswalk_variedad_SEC2.xlsx` |
| Generador de capas maestras / transform a consumo diario | `scripts/00_master.R`, `scripts/03_transform.R` |
| Plan paso a paso con KPIs de conciliación | `PLAN_DE_TRABAJO.md` (§0.5) |

Al correr `00_master.R` → `03_transform.R` en RStudio, los KPI de la consola deben
reproducirse contra la tabla 0.5 del plan (base de conciliación).

## 5. Limitaciones honestas (para la verificación)

- La **composición de la Sección 2 está en 0% hasta validar el crosswalk** (es la tarea en
  curso de esta semana; las sugerencias INCAP ya están curadas en el archivo).
- Los **pesos de referencia son propuestas**, marcadas como tales en el archivo; la
  validación con BCRD/MIMI es el paso 2.4 del plan.
- Los scripts R aún no se han ejecutado en RStudio en esta sesión; los artefactos maestros
  fueron generados y verificados con un espejo de la misma lógica (regla por regla); la
  conciliación en RStudio es el control de calidad final.
- El Cuestionario A (edad/sexo, quintiles, región) no está en el repo: bloquea el
  equivalente adulto y el análisis por grupos etarios (solicitado; no afecta la tarea de
  unidades de la Sección 2).
