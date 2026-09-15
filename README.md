# ENGIH 2018 → Evidencia nutricional para fortificación de alimentos

Pipeline reproducible que transforma la **Encuesta Nacional de Gastos e Ingresos
de los Hogares (ENGIH 2018, República Dominicana)** en indicadores de consumo
aparente, ingesta de micronutrientes y cobertura de vehículos de fortificación.

Desarrollado en el marco de la consultoría del Programa Mundial de Alimentos
sobre cobertura, consumo y contribución de alimentos fortificados y
fortificables.

---

## Por dónde empezar

| Si busca… | Vaya a |
|---|---|
| **Los resultados** | Los cinco informes — ver la tabla siguiente |
| **Cómo se hizo y qué limita el análisis** | Informe de factibilidad — método, adaptaciones, limitaciones y guía de continuidad |
| **Verificar una decisión concreta** | [`data/auditoria/`](data/auditoria) — cada cambio con su valor anterior, el nuevo y el motivo |
| **El marco conceptual y el alcance** | [`docs/vision-y-arquitectura.md`](docs/vision-y-arquitectura.md) — preguntas estratégicas y principios de verificación |
| **Reproducir el análisis** | [El pipeline](#el-pipeline) — cinco scripts y los comandos exactos |
| **El código de una cifra concreta** | [`reports/`](reports) — cada informe es el código que lo genera |

Los informes se generan en `output/` al compilar. Son documentos HTML
autocontenidos: se abren con doble clic, sin instalar nada.

---

## Informes

Cinco informes generados desde los datos. **Ninguna cifra está escrita a mano**:
al ampliar las tablas auxiliares, los resultados se actualizan al recompilar.

Las estimaciones poblacionales incorporan el diseño muestral complejo de la
encuesta —8 estratos, 933 unidades primarias de muestreo y factor de expansión
por hogar— con intervalos de confianza al 95% por linealización de Taylor.

| Informe | Qué responde |
|---|---|
| **R1 — Calidad y preparación de los datos** | Qué proporción de las observaciones llega al cálculo, dónde se pierde el resto y qué adaptaciones metodológicas fueron necesarias |
| **R2 — Modelo de base** | Consumo diario (`Q × FC × PC / PM`) y normalización por Equivalente de Mujer Adulta |
| **R3 — Cobertura de vehículos fortificables** | A qué proporción de hogares alcanza cada vehículo y en qué cantidad |
| **R4 — Escenarios de fortificación** | Cómo varía la ingesta de micronutrientes según qué vehículo se fortifique |
| **R5 — Equidad** | Cómo se distribuye la ingesta por quintil de gasto y zona de residencia |

---

## Hallazgos principales

**La metodología es implementable sobre esta fuente.** El 76% de las
observaciones de la Sección 3A y el 91% de la Sección 2 completan la cadena de
cálculo. Son conteos de registros procesados, no estimaciones poblacionales. El factor limitante no es la encuesta sino la completitud de las tablas
auxiliares de conversión y composición, que continúa ampliándose: cada
ampliación mejora la cobertura sin modificar el método.

**Los vehículos de fortificación alcanzan a la mayoría de los hogares.**
Arroz 88,2% (IC 95%: 87,3–89,0), aceite 87,5% (86,6–88,3) y azúcar 79,2%
(77,9–80,4). Estimaciones ponderadas con el diseño muestral de la encuesta.

**La harina de trigo constituye una excepción: 6,2% (IC 95%: 5,4–6,9).** Ningún
hogar de la muestra la declara en existencias y solo una minoría registra su
compra, mientras los derivados de trigo aparecen en la mayoría.

Una lectura posible es que la harina llegue al hogar mayoritariamente ya
procesada. Si el patrón es ese, y dado que la fortificación se aplica en el
molino, un indicador construido sobre harina estaría midiendo un insumo
intermedio y no la exposición de la población al nutriente. Definido el vehículo
como *harina y sus derivados*, el alcance asciende a 85,7% —con la salvedad de
que la norma es obligatoria para panificación y voluntaria para pastas y
galletas, de modo que esa cifra constituye un techo.

La cuestión no es específica de República Dominicana: **concierne a cualquier
evaluación en que el vehículo fortificado se consuma mayoritariamente
transformado.**

**La fortificación de un vehículo de consumo transversal tiene efecto
distributivo progresivo.** La razón de ingesta de folato entre el quintil de
mayor y el de menor gasto pasa de 1,21 sin fortificación a 1,01 incorporando el
arroz. El mecanismo no es un mayor consumo entre los hogares de menor gasto,
sino un consumo equivalente en toda la distribución.

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
quarto::quarto_render(here::here("reports", "R5_equidad.qmd"))
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

- **Informe de factibilidad** — las decisiones metodológicas con su
  justificación: adaptaciones aplicadas, criterios de exclusión, supuestos y
  limitaciones. Es el documento de referencia sobre cómo se hizo el análisis.
- **[`docs/vision-y-arquitectura.md`](docs/vision-y-arquitectura.md)** — marco
  conceptual, alcance y principios de trabajo.
- **[`data/auditoria/`](data/auditoria)** — registro fila por fila de cada
  modificación a las tablas auxiliares, con el valor anterior, el nuevo y el
  motivo.
- **`docs/hoja-de-ruta.md`** — bitácora operativa del desarrollo, de uso
  interno.

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
