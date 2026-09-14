# ENGIH 2018 → Evidencia nutricional para fortificación de alimentos

Pipeline reproducible que transforma la **Encuesta Nacional de Gastos e Ingresos
de los Hogares (ENGIH 2018, República Dominicana)** en indicadores de consumo
aparente, ingesta de micronutrientes y cobertura de vehículos de fortificación.

Desarrollado en el marco de la consultoría del Programa Mundial de Alimentos
sobre cobertura, consumo y contribución de alimentos fortificados y
fortificables.

---

## Informes

Cuatro informes generados desde los datos. **Ninguna cifra está escrita a mano**:
al ampliar las tablas auxiliares, los resultados se actualizan al recompilar.

| Informe | Qué responde |
|---|---|
| **R1 — Calidad y preparación de los datos** | Qué proporción de las observaciones llega al cálculo, dónde se pierde el resto y qué adaptaciones metodológicas fueron necesarias |
| **R2 — Modelo de base** | Consumo diario (`Q × FC × PC / PM`) y normalización por Equivalente de Mujer Adulta |
| **R3 — Cobertura de vehículos fortificables** | A qué proporción de hogares alcanza cada vehículo y en qué cantidad |
| **R4 — Escenarios de fortificación** | Cómo varía la ingesta de micronutrientes según qué vehículo se fortifique |

---

## Hallazgos principales

**La metodología es implementable sobre esta fuente.** El 76% de las
observaciones de la Sección 3A y el 91% de la Sección 2 completan la cadena de
cálculo. El factor limitante no es la encuesta sino la completitud de las tablas
auxiliares de conversión y composición, que continúa ampliándose: cada
ampliación mejora la cobertura sin modificar el método.

**Los vehículos de fortificación están bien cubiertos.** Entre las observaciones
que los mencionan, la cadena de cálculo se completa en el 97–100% de los casos.
Los indicadores de cobertura son por tanto sólidos aun cuando la cobertura
general sea menor.

**El indicador de harina de trigo mide el insumo equivocado.** Solo el 8% de los
hogares adquiere harina como producto —ningún hogar la declara en existencias—,
lo que sugeriría un programa de fortificación de alcance marginal. El patrón de
consumo dominicano explica la discrepancia: la harina llega al hogar ya
procesada, principalmente como pan. Definido el vehículo como *harina y sus
derivados*, el alcance pasa de 8% a **85,7%**.

Este último hallazgo no es específico de República Dominicana: **afecta a
cualquier evaluación donde el vehículo fortificado se consuma mayoritariamente
transformado.**

---

## Estructura del repositorio

```
.
├── scripts/           Pipeline de procesamiento (01 → 05)
├── reports/           Fuentes de los informes e infraestructura compartida
├── output/            Informes renderizados (no versionado — se regeneran)
│
├── data/
│   ├── raw/           Fuentes originales y tablas auxiliares
│   ├── clean/         Salidas del pipeline (no versionado — se regeneran)
│   ├── auditoria/     Registro de decisiones: qué cambió, por qué y cuándo
│   └── diagnosticos/  Exploración de calidad de datos (regenerable)
│
├── docs/              Documentación del proyecto
├── referencias/       Material metodológico externo consultado
└── media/             Evidencia fotográfica del trabajo de campo
```

**Convención de nombres.** Minúsculas, sin acentos ni espacios. Guiones en
documentos, guiones bajos en código. Prefijo numérico únicamente donde el orden
de ejecución importa.

**Los productos derivados no se versionan, se reproducen.** El repositorio
contiene lo que genera resultados, no los resultados. Esto aplica a
`data/clean/`, `output/` y a los diagnósticos regenerables.

---

## El pipeline

Cinco scripts secuenciales. Cada uno consume la salida del anterior y deja
constancia en pantalla de cuántos registros entran y cuántos se pierden.

```
01_import.R               Carga, valida y une las fuentes. Aplica factores de
                          conversión y porción comestible.
02_eda.R                  Exploración y diagnóstico de calidad.
03_transform.R            Consumo diario: Q × FC × PC / PM. Marca valores
                          atípicos sin eliminarlos.
04_equivalente_adulto.R   Requerimiento energético por edad y sexo → EMA por
                          hogar → gramos por EMA y día.
05_ingesta_micronutrientes.R
                          Une con tablas de composición (INCAP / FNDDS) →
                          ingesta aparente de energía, hierro, folato y
                          vitamina A.
```

### Reproducir

```r
source(here::here("scripts", "01_import.R"))
source(here::here("scripts", "03_transform.R"))
source(here::here("scripts", "04_equivalente_adulto.R"))
source(here::here("scripts", "05_ingesta_micronutrientes.R"))

quarto::quarto_render(here::here("reports", "R1_calidad_datos.qmd"))
quarto::quarto_render(here::here("reports", "R2_modelo_base.qmd"))
quarto::quarto_render(here::here("reports", "R3_cobertura_vehiculos.qmd"))
quarto::quarto_render(here::here("reports", "R4_escenarios_fortificacion.qmd"))
```

Requiere R con `dplyr`, `readr`, `tidyr`, `readxl`, `writexl`, `here`, `knitr`,
`janitor`, `srvyr`, `dlookr`, `conflicted`, `ggplot2`, y Quarto.

`reports/_comun.R` centraliza rutas, carga de datos, definición de los vehículos
de fortificación, escenarios y la regla de elegibilidad compartida. **Una
definición se cambia allí y se propaga a todos los informes**, lo que evita que
dos documentos publiquen cifras incompatibles.

---

## Trazabilidad de las decisiones

Cada decisión metodológica que no es evidente queda registrada con su
justificación y su evidencia:

- **[`docs/hoja-de-ruta.md`](docs/hoja-de-ruta.md)** — bitácora completa: hitos,
  decisiones, hallazgos, errores cometidos y corregidos, y backlog priorizado.
  Es la fuente de verdad del proyecto.
- **[`docs/vision-y-arquitectura.md`](docs/vision-y-arquitectura.md)** — marco
  conceptual, alcance y principios de trabajo.
- **`data/auditoria/`** — registro fila por fila de cada modificación a las
  tablas auxiliares, con el valor anterior, el nuevo y el motivo.

El mapeo de alimentos a tablas de composición distingue explícitamente
equivalencias **directas** de **sustitutos por criterio**, de modo que siempre
es posible saber dónde se aplicó juicio profesional y dónde hubo
correspondencia exacta.

### Construcción del crosswalk

La correspondencia entre los alimentos de la encuesta y las tablas de
composición se construyó en dos fases: generación asistida de candidatos y
revisión manual registro a registro, contrastando cada asignación contra la
descripción de la tabla fuente.

La revisión identificó errores en el **6,1%** de las asignaciones, todos de tres
tipos recurrentes: parte del alimento consumida, estado de preparación y grado
de procesamiento. Un ejemplo ilustra la importancia del criterio local: en
República Dominicana *cereza* designa la acerola, cuyo contenido de vitamina C
supera en más de dos órdenes de magnitud al de la guinda dulce.

Cuando una tabla de composición internacional no cubría un producto dominicano,
se resolvió con **trabajo de campo**: pesaje directo en mercado local con
registro fotográfico, documentado en `media/`.

---

## Limitaciones

Declaradas en detalle dentro de cada informe. En resumen:

- **Consumo aparente, no ingesta individual.** Se mide lo que el hogar adquiere
  o tiene disponible, no lo que cada persona ingiere. No se captura distribución
  intrafamiliar, desperdicio ni consumo fuera del hogar.
- **Estimaciones con diseño muestral complejo.** Se incorporan la
  estratificación (8 estratos), la conglomeración (933 unidades primarias) y el
  factor de expansión, con intervalos de confianza por linealización de Taylor.
  Las cifras de cobertura del procesamiento son conteos de registros y no llevan
  intervalo.
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

*Análisis y desarrollo: Maicel E. Monzón, PhD — Consultor internacional,
Programa Mundial de Alimentos, República Dominicana.*
