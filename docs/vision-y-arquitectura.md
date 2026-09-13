---
title: "Visión y Arquitectura del Proyecto"
author: "Maicel E. Monzón"
subtitle: ENGIH 2018 → Evidencia Nutricional para WFP
---

# 1. Propósito

Transformar datos de encuestas de hogares en evidencia nutricional útil para la toma de decisiones.

La ENGIH 2018 de República Dominicana constituye el caso de aplicación de una metodología reproducible.

Este documento define el problema, las preguntas estratégicas y la ruta general para resolverlo.

Para el estado operativo y los próximos pasos consultar `README.md`.

---

# 2. Problema

Las Encuestas de Gasto y Consumo de Hogares (HCES) contienen información valiosa sobre alimentación, pero normalmente no producen estimaciones directas de:

- Consumo alimentario.
- Ingesta de micronutrientes.
- Riesgo de inadecuación.
- Cobertura de programas de fortificación.

El objetivo del proyecto es construir una metodología que permita generar esos indicadores de forma reproducible.

---

# 3. Preguntas estratégicas

1. ¿Qué micronutrientes presentan mayor riesgo de ingesta inadecuada?
2. ¿Qué grupos poblacionales son más vulnerables?
3. ¿Qué alimentos aportan la mayor proporción de micronutrientes clave?
4. ¿Qué cobertura tienen los principales vehículos de fortificación?
5. ¿Qué grupos quedan fuera del alcance de las intervenciones actuales?
6. ¿Cuál sería la contribución potencial de diferentes escenarios de fortificación?

---

# 4. Marco metodológico y decisiones de alcance

- **Núcleo (todo lo demás depende de esto):** Guía MIMI/WFP (dic. 2025), *Modelo de Base — Cálculos de consumo*. Fórmula:

```text
Consumo diario (g) = Q × FC × PC / PM
```

Sin este cálculo bien hecho, ningún indicador de las fases siguientes es confiable.

- **Capa de análisis y modelado, construida sobre el núcleo:** marco de Tang et al. (2021, Malawi). Incluye cobertura de vehículos de fortificación, densidad de nutrientes (por 1000 kcal), consumo aparente por AFE, escenarios de fortificación y análisis de equidad. No reemplaza a MIMI; consume sus resultados.

- **Tabla de composición de alimentos (fase actual):** INCAP.

"TCA" se utiliza como término genérico para cualquier tabla de composición de alimentos. Durante la fase actual del proyecto la fuente principal es INCAP, aunque la arquitectura contempla la incorporación futura de otras fuentes (USDA, FNDDS u otras) cuando existan vacíos de cobertura.

- **Benchmark externo para verificación de resultados:** Encuesta Nacional de Micronutrientes (ENM), República Dominicana, MSP. Hay dos versiones con resultados muy distintos: 2009 (MSP/CESDEM — anemia 28% en niños 6-59 meses, deficiencia de vitamina A) y 2024 (MSP/Inabie/FAO/PMA — mejoras sustanciales, baja deficiencia). Usar la versión 2024 como referencia principal una vez que su informe completo esté disponible; citar siempre el informe primario del MSP, nunca una síntesis de segunda mano sin bibliografía verificable.
- **Registro de decisiones del crosswalk:** vive dentro del propio archivo de trabajo del crosswalk (`crosswalk_tablas_composicion.xlsx`, columnas `enhance_id`, `tipo_equivalencia`, `validado` y `notas`). No se mantiene un archivo adicional de decisiones.

- **Fuera de alcance en esta iteración:** Sección 3B de la ENGIH (alimentos preparados fuera del hogar). Requiere factores de receta y rendimiento que todavía no están construidos. Es una decisión metodológica explícita, no un olvido. Revisar únicamente si el TdR exige su inclusión.

## Arquitectura de tablas de composición y crosswalks

**Actualizado 2026-09-09 — la estrategia descrita en versiones anteriores de esta sección (múltiples crosswalks por fuente + tablas "MASTER" generadas automáticamente) fue abandonada. Esto es lo que realmente existe y usa el pipeline hoy:**

- **Un solo archivo de crosswalk:** `crosswalk_tablas_composicion.xlsx`, con una pestaña por sección de la ENGIH ("Cuest. B Sec 2", "Cuest. B Sec 3A"). Columnas clave: `id_variedad`/`descripcion_engih`, `enhance_id` (apunta a la tabla de composición), `fuente` (marca si ese `enhance_id` viene de INCAP o de FNDDS), `tipo_equivalencia`, `validado`, `notas`.
- **Dos tablas de composición nutricional, usadas directamente, sin tabla "MASTER" que las una:** `food_composition_INCAP.xlsx` (fuente principal) y `food_composition_FNDDS.xlsx` (para alimentos que INCAP no cubre — bebidas alcohólicas, condimentos concentrados, platos combinados, etc.). **No existe ni se va a construir `food_composition_USDA.xlsx` por separado** — FNDDS (que ya es de origen USDA) cumple ese rol.
- **No existen** `crosswalk_variedad_INCAP.xlsx`, `crosswalk_variedad_FNDDS.xlsx`, `crosswalk_variedad_USDA.xlsx`, `crosswalk_variedad_MASTER.xlsx` ni `food_composition_MASTER.xlsx` — son nombres de una arquitectura planeada que nunca se construyó así. Si aparecen en commits viejos o en versiones anteriores de este documento, no reflejan el proyecto real.
- **Para `05_ingesta_micronutrientes.R`:** por cada fila con `enhance_id`+`fuente` validados en el crosswalk, buscar el nutriente en `food_composition_INCAP.xlsx` o `food_composition_FNDDS.xlsx` según diga `fuente` — no hay una sola tabla ya unificada, hay que resolver la fuente fila por fila.

---

# 5. Hoja de ruta

## Importar

*(Fase activa. Ver `README.md` para el estado operativo.)*

Scripts:

```text
/scripts/01_import.R 
```

Objetivo: construir el dataset unido (ENGIH + composición alimentaria) que alimenta los cálculos posteriores.

Incluye:

1. Importar ENGIH Sección 2 (inventario despensa/refrigerador) y Sección 3A (adquisiciones diarias del hogar).
2. Identificar las variables críticas:
   - Q = cantidad registrada.
   - FC = factor de conversión a gramos.
   - PC = porción comestible.
   - PM = periodo de medición.
3. Construir los joins necesarios para conectar ENGIH con:
   - tablas de unidades;
   - crosswalks de alimentos;
   - tablas de composición nutricional.

Salidas:

```text
data/clean/data_sec2.csv
data/clean/data_sec3a.csv
data/clean/data_sociodemografia.csv
```

las versiones limpias utilizadas por el resto del pipeline (no comiteadas a git — regenerables corriendo `01_import.R`, ver `.gitignore`).

## Limpieza y Análisis Exploratorio de Datos (EDA)

Script:

```text
/scripts/02_eda.R
```

Objetivo: validar la calidad de los datos antes de los cálculos nutricionales.

Incluye:

- Tratamiento de datos perdidos
- Detección de atípicos por alimento.
- Alimentos con frecuencia insuficiente.
- Revisión de distribuciones.


## Transformar

Objetivo: convertir las cantidades observadas en consumo diario y aporte nutricional.

Incluye:

- Cálculo:

```text
Q × FC × PC / PM
```

- Gramos diarios por alimento.
- Consumo por hogar.
- AFE (Adult Female Equivalent).
- AME (Adult Male Equivalent).
- Densidad de nutrientes.
- Integración con las tablas de composición alimentaria.
- Incoporación de covariable para análisis estratificado, modelación multivarida y mapas

## Analizar

Objetivo: responder las preguntas estratégicas del proyecto.

Incluye:

- Adecuación de micronutrientes.
- Principales alimentos contribuyentes.
- Cobertura de vehículos de fortificación.
- Equidad por quintil, región y área urbana/rural.

## Modelar

Objetivo: evaluar escenarios contrafactuales de fortificación.

Incluye:

- Situación observada.
- Escenario de cumplimiento actual.
- Escenario de cumplimiento mejorado.
- Escenarios alternativos de política pública.

## Comunicar

Objetivo: transformar los resultados en evidencia utilizable.

Incluye:

- Reportes.
- Visualizaciones.
- Productos para WFP.
- Material de comunicación técnica.

---

# 6. Principio rector

Cada fase se cierra y se documenta (código, salida y decisión) antes de abrir la siguiente.

La ENGIH es el caso de aplicación.

La metodología reproducible es el verdadero entregable.

---

# 7. Principios de rigor y verificación

Reglas de trabajo, no aspiraciones. Aplican a cualquier persona o herramienta que contribuya al proyecto.

1. Ningún valor heredado de un archivo previo se usa "porque ya está ahí" — se verifica contra el dato crudo o la fuente oficial antes de entrar a un cálculo final.
2. Ninguna nota o etiqueta heredada (ej. "revisar", un comentario antiguo) se repite como hecho sin comprobarla de nuevo.
3. Toda cifra que llegue a un resultado final (FC, prevalencia, cobertura, consumo aparente) debe ser trazable a: (a) el dato crudo más la transformación exacta que la produjo, o (b) una fuente externa citada con documento y sección específicos.
4. Ningún vacío de información se llena con un valor "plausible" sin marcarlo explícitamente como supuesto pendiente de validar. Un supuesto sin validar no entra al pipeline final.
5. Antes de reportar una cifra agregada importante, se contrasta su orden de magnitud contra un benchmark externo conocido (ENM 2009/2024, líneas de pobreza, ENDESA). Si no cuadra, se investiga antes de publicar.
6. Cualquier corrección a un dato existente conserva el valor original (columna aparte o historial de git) junto con la justificación y la fuente del cambio.
7. Citas de literatura (Tang et al., Imhoff-Kunsch, guía MIMI/WFP, ENM) se usan solo verificadas contra el documento primario — nunca una síntesis sin bibliografía comprobable.
8. No se guardan en el repositorio transcripciones de conversaciones con asistentes de IA ni borradores sin fuente verificable. Si algo de valor sale de esas conversaciones, se reescribe como decisión propia, verificada, e incorporada al documento correspondiente.