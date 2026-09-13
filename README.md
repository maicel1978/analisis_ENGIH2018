# ENGIH 2018 → Evidencia nutricional para fortificación de alimentos

Pipeline reproducible que transforma la **Encuesta Nacional de Gastos e Ingresos
de los Hogares (ENGIH 2018, República Dominicana)** en indicadores de consumo
aparente, ingesta de micronutrientes y cobertura de vehículos de fortificación.

Desarrollado en el marco de la consultoría del Programa Mundial de Alimentos
sobre cobertura, consumo y contribución de alimentos fortificados y
fortificables.

---

## Empezar por aquí

Si dispone de cinco minutos y quiere entender qué hace este proyecto y qué
encontró, lea los tres reportes. Son documentos HTML autocontenidos: se abren
con doble clic, sin instalar nada.

| Reporte | Qué responde | TdR |
|---|---|---|
| **R1 — Calidad y preparación de los datos** | ¿Sirven estos datos? Cobertura, factores de conversión, porción comestible, adaptaciones metodológicas | 4.1–4.3, 7 |
| **R2 — Modelo de base** | Consumo diario (`Q × FC × PC / PM`) y Equivalente de Mujer Adulta | 1.3, 1.4, 8.2 |
| **R3 — Cobertura de vehículos fortificables** | ¿A qué proporción de hogares alcanza cada vehículo, y cuánto consumen? | 8.1, 4.2 |

Los tres se generan automáticamente desde los datos: **ninguna cifra está
escrita a mano**. Al mejorar los datos de origen, los reportes se actualizan
solos.

---

## Qué se encontró

Tres resultados que conviene conocer antes de leer el detalle.

**La ENGIH 2018 permite implementar la metodología.** El 76% de las
observaciones de la Sección 3A y el 91% de la Sección 2 completan la cadena de
cálculo. Lo que limita el alcance no es la encuesta sino el estado de
completitud de las tablas auxiliares, que sigue ampliándose.

**Los cuatro vehículos de fortificación están cubiertos casi en su totalidad**
(97–100% de las observaciones que los mencionan), de modo que los indicadores de
cobertura son sólidos pese a que la cobertura general sea menor.

**La harina de trigo casi no se consume como producto: 8% de los hogares.** No
es un vacío de datos, es el patrón de consumo dominicano — la harina llega al
hogar ya procesada, como pan. Medir la cobertura del programa de fortificación
por "harina de trigo" mide un insumo intermedio, no la exposición de la
población al nutriente añadido. Definido como *harina y sus derivados*, el
alcance pasa de 8% a **85.7%**.

---

## El pipeline

Cinco scripts secuenciales. Cada uno consume la salida del anterior y deja
constancia en pantalla de cuántos registros entran y cuántos se pierden.

```
01_import.R          Carga, valida y une las fuentes. Aplica factores de
                     conversión y porción comestible.
02_eda.R             Exploración y diagnóstico de calidad.
03_transform.R       Consumo diario: Q × FC × PC / PM. Marca valores atípicos
                     sin eliminarlos.
04_equivalente_      Requerimiento energético por edad y sexo → EMA por hogar
adulto.R             → gramos por EMA y día.
05_ingesta_          Une con tablas de composición (INCAP / FNDDS) → ingesta
micronutrientes.R    aparente de energía, hierro, folato y vitamina A.
```

### Reproducir

```r
source(here::here("scripts", "01_import.R"))
source(here::here("scripts", "03_transform.R"))
source(here::here("scripts", "04_equivalente_adulto.R"))
source(here::here("scripts", "05_ingesta_micronutrientes.R"))

quarto::quarto_render(here::here("scripts", "R1_calidad_datos.qmd"))
quarto::quarto_render(here::here("scripts", "R2_modelo_base.qmd"))
quarto::quarto_render(here::here("scripts", "R3_cobertura_vehiculos.qmd"))
```

Requiere R con `dplyr`, `readr`, `tidyr`, `readxl`, `writexl`, `here`, `knitr`,
`srvyr`, `dlookr`, `conflicted`, y Quarto.

`scripts/_comun.R` centraliza rutas, carga de datos, definición de los vehículos
de fortificación y la regla de elegibilidad compartida por los reportes. **Una
definición se cambia allí y se propaga a todos**, lo que evita que dos reportes
publiquen cifras incompatibles.

---

## Estructura

```
data/raw/       Fuentes originales y tablas auxiliares (crosswalk, factores
                de conversión, composición de alimentos). Versionado.
data/clean/     Salidas del pipeline. NO versionado: es regenerable.
data/eda/       Diagnósticos y registros de auditoría de las decisiones
                de mapeo. Versionado.
scripts/        Pipeline y reportes.
docs/           Material metodológico de referencia y evidencia de campo.
```

**Los productos derivados no se versionan, se reproducen.** El repositorio
contiene lo que genera resultados, no los resultados.

---

## Trazabilidad de las decisiones

Cada decisión metodológica que no es evidente queda registrada con su
justificación y su evidencia:

- **[`HOJA_DE_RUTA_PROYECTO.md`](./HOJA_DE_RUTA_PROYECTO.md)** — bitácora
  completa: hitos, decisiones, hallazgos, errores cometidos y corregidos, y
  backlog priorizado. Es la fuente de verdad del proyecto.
- **[`VISION_Y_ARQUITECTURA_PROYECTO.md`](./VISION_Y_ARQUITECTURA_PROYECTO.md)** —
  marco conceptual, alcance y principios de trabajo.
- **`data/eda/log_*.csv`** — registro fila por fila de cada modificación a las
  tablas auxiliares, con el motivo de cada una.

El mapeo de alimentos a tablas de composición distingue explícitamente
equivalencias **directas** de **sustitutos por criterio**, de modo que siempre
es posible saber dónde se aplicó juicio profesional y dónde hubo
correspondencia exacta.

Cuando una tabla de composición internacional no cubría un producto dominicano,
se resolvió con **trabajo de campo propio**: pesaje directo en mercado local con
evidencia fotográfica, documentado en `docs/`.

---

## Limitaciones

Declaradas en detalle dentro de cada reporte. En resumen:

- **Consumo aparente, no ingesta individual.** Se mide lo que el hogar adquiere
  o tiene disponible, no lo que cada persona ingiere. No se captura distribución
  intrafamiliar, desperdicio ni consumo fuera del hogar.
- **Sin intervalos de confianza.** La encuesta tiene diseño muestral complejo
  (8 estratos, 933 unidades primarias, factor de expansión). Las variables están
  disponibles; hasta incorporarlas no se reportan intervalos, en lugar de
  reportarlos incorrectamente estrechos.
- **El consumo de alimentos almacenables está sobrestimado**, porque las
  Secciones 2 y 3A se solapan parcialmente en ellos. El refinamiento propuesto
  es la disponibilidad neta.
- **La ingesta reportada es un límite inferior**: los alimentos sin composición
  nutricional conocida suman cero, no se imputan.
- **La cobertura de las tablas de composición no es uniforme entre nutrientes**
  (energía 100%, hierro 96%, folato 92%, vitamina A 86%), de modo que la
  vitamina A está más subestimada que la energía.

---

## Decisiones pendientes

Corresponden al equipo técnico, no se resuelven en el código. Cada una está
documentada con su evidencia en la hoja de ruta.

1. **Línea base de fortificación.** El mapeo actual no representa ningún
   escenario real de política dominicana. Efecto medible: folato sobrestimado y
   vitamina A subestimada.
2. **Tratamiento de las Secciones 2 y 3A.** Ninguna por separado produce
   resultados fisiológicamente plausibles; la suma duplica los alimentos
   almacenables. Las tres variantes están calculadas y comparadas.
3. **Fuentes de composición** para los alimentos sin equivalencia en INCAP ni
   FNDDS.

---

*Análisis y desarrollo: Maicel E. Monzón — Consultor internacional, Programa
Mundial de Alimentos, República Dominicana.*