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

- **Registro de decisiones del crosswalk:** vive dentro del propio archivo de trabajo del crosswalk (columnas `ENHANCE_ID_final`, `tipo_equivalencia`, `validado` y `notas`). No se mantiene un archivo adicional de decisiones.

- **Fuera de alcance en esta iteración:** Sección 3B de la ENGIH (alimentos preparados fuera del hogar). Requiere factores de receta y rendimiento que todavía no están construidos. Es una decisión metodológica explícita, no un olvido. Revisar únicamente si el TdR exige su inclusión.

## Arquitectura de tablas de composición y crosswalks

La ENGIH contiene alimentos que no siempre están representados adecuadamente en una única tabla de composición nutricional.

Por esta razón, la curación manual se realizará por fuente.

Ejemplos:

```text
crosswalk_variedad_INCAP.xlsx
crosswalk_variedad_USDA.xlsx
crosswalk_variedad_FNDDS.xlsx
```

Cada crosswalk se mantiene de forma independiente durante la etapa de construcción y validación para facilitar:

- Auditoría manual.
- Trazabilidad de decisiones.
- Revisión experta.
- Control de calidad por fuente.

Durante esta etapa cada archivo puede evolucionar de forma independiente.

Ejemplo:

```text
crosswalk_variedad_INCAP.xlsx
crosswalk_variedad_FNDDS.xlsx
crosswalk_variedad_USDA.xlsx
```

contienen únicamente asignaciones validadas contra las tablas de composición de alimentos.

Los crosswalks crosswalk_variedad_FNDDS.xlsx y crosswalk_variedad_USDA.xlsx son para los alimentos que INCAP no cubra adecuadamente.

Ejemplos:

```text
Caldo de pollo (Sopita Concentrada)
Mayonesa
Vinagre dorado
Bizcocho envasado de vainilla
Jugo de frutas en polvo
Snacks y picaderas de todo tipo
Ensalada cruda (Varias hortalizas)
Sazon liquido
Malta

```

La existencia de múltiples crosswalks es únicamente una estrategia de construcción y mantenimiento.

hasta el momento hay tres tablas de composición de alimentos con toda la informacion nutricional

```text
food_composition_USDA.xlsx
food_composition_FNDDS.xlsx
food_composition_USDA.xlsx # todavia por hacer
```

## Principio rector de integración

Los scripts analíticos no deben depender directamente de:

```text
INCAP
USDA
FNDDS
```

Los scripts deben depender de una capa de abstracción única.

Antes de ejecutar los análisis nutricionales se generará automáticamente una tabla consolidada:

```text
crosswalk_variedad_MASTER.xlsx
```

Esta será la única tabla puente utilizada por los procesos analíticos.

No debe editarse manualmente.

Será producida automáticamente a partir de los crosswalks específicos por fuente para los aliementos validados como TRUE.

La estructura conceptual esperada es:

```text
id_variedad
descripcion_engih
fuente_composicion
id_composicion
```

Ejemplo:

```text
367 | Habichuelas negras secas | INCAP | 70209060
541 | Mayonesa                | USDA  | XXXXXXX  
649 | Malta                   | USDA  | XXXXXXX  
```

## Tabla maestra de composición nutricional

La misma lógica se aplicará a las tablas de composición.

Fuentes:

```text
food_composition_INCAP.xlsx
food_composition_USDA.xlsx
food_composition_FNDDS.xlsx
```

serán integradas posteriormente en una única tabla:

```text
food_composition_MASTER
```

Preferiblemente en formato xlsx.

El food_composition_MASTER es una tabla viva basada prioritariamente en INCAP, ampliada de forma selectiva con USDA y gobernada por frecuencia de uso (freq_registros) y estado de validación (validado), con el objetivo de maximizar la cobertura analítica y mejorar progresivamente la calidad de las estimaciones nutricionales.

Cuando un alimento tenga equivalentes válidos en múltiples fuentes, la prioridad será INCAP > USDA > FNDDS, salvo decisión técnica específica documentada en el crosswalk correspondiente.

La armonización deberá estandarizar:

- Identificadores.
- Energía.
- Macronutrientes.
- Micronutrientes.
- Factores de porción comestible.
- Nombres de variables.
- Unidades de medida.

El objetivo es que las fases posteriores del pipeline no necesiten conocer la fuente original de cada alimento.

nota: El food_composition_MASTER.xlsx constituye una capa técnica de integración entre las tablas de composición alimentaria y la ENGIH. Su objetivo es permitir la construcción de un único dataset_nutricional, donde cada registro alimentario de la encuesta queda asociado a variables nutricionales estandarizadas e independientes de la fuente original (INCAP, USDA, FNDDS u otras). Todas las fases posteriores del pipeline consumirán preferentemente este dataset integrado.

## Regla de gobernanza

Se editan manualmente:

```text
crosswalk_variedad_INCAP.xlsx
crosswalk_variedad_USDA.xlsx
crosswalk_variedad_FNDDS.xlsx
```

Se generan automáticamente:

```text
crosswalk_variedad_MASTER.xlsx
food_composition_MASTER
```

## Decisión arquitectónica congelada

Durante la etapa de construcción se mantendrán crosswalks separados por fuente.

Antes de los análisis definitivos se generará automáticamente:

```text
crosswalk_variedad_MASTER.xlsx
```

y una:

```text
food_composition_MASTER.xlsx
```

homogeneizada.

Los scripts analíticos deberán depender exclusivamente de estas dos capas maestras y no de fuentes individuales.

Esta decisión busca minimizar futuras refactorizaciones, facilitar la incorporación de nuevas tablas de composición y mantener la trazabilidad completa de las decisiones de correspondencia alimentaria.

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
data/raw/data_raw_sec2.csv
data/raw/data_raw_sec3a.csv
```

las versiones limpias utilizadas por el resto del pipeline.

las tablas crosswalk_variedad_MASTER y food_composition_MASTER

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


