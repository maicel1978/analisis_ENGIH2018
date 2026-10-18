# ENGIH 2018: cobertura, consumo y contribución de alimentos fortificables

Cadena de análisis reproducible que estima, con la Encuesta Nacional de Gastos
e Ingresos de los Hogares 2018 de República Dominicana, la cobertura y el
consumo de los vehículos de fortificación, la ingesta aparente de
micronutrientes, el riesgo de ingesta inadecuada y el efecto de escenarios de
fortificación. Desarrollada en la consultoría del Programa Mundial de Alimentos
sobre módulos e-learning de cobertura, consumo y contribución de alimentos
fortificados y fortificables.

## Entregables

| Documento | Fuente | Términos de referencia |
|---|---|---|
| Informe de factibilidad | `reports/INFORME_factibilidad.qmd` | 4.1–4.3, 7 |
| Informe analítico final | `reports/INFORME_final.qmd` | 7, 8.1–8.5 |
| Manual técnico | `reports/MANUAL_tecnico.qmd` | 18 |
| Presentación de resultados | `reports/presentacion_cierre.qmd` | — |

Cada documento es el código que lo genera: ninguna cifra está escrita a mano.
Se compilan en `output/`, que no se versiona.

## Reproducir

1. Obtener los microdatos de la Oficina Nacional de Estadística y colocarlos
   en `data/raw/`: `Registros_Cuestionario_B.xlsx` y
   `Sociodemograficas_e_ingresos.xlsx`. No se versionan.
   `scripts/00_descargar_datos.R` los descarga y verifica su resumen MD5 una
   vez registrada la dirección en `data/raw/fuentes_datos.csv`.
2. Abrir `analisis_ENGIH2018.Rproj` y ejecutar en la consola de R:

```r
for (s in c("01_import", "02_eda", "03_transform", "04_equivalente_adulto",
            "05_ingesta_micronutrientes", "06_escenarios_fortificacion",
            "07_riesgo_inadecuacion", "08_grupos_alimentos", "09_mapas")) {
  source(here::here("scripts", paste0(s, ".R")))
}
quarto::quarto_render(here::here("reports", "INFORME_final.qmd"))
quarto::quarto_render(here::here("reports", "MANUAL_tecnico.qmd"))
```

Cifras de control de una corrida correcta: 36.840 registros de la Sección 3A
sin correspondencia de composición, 328.173 registros de consumo con gramos por
equivalente de mujer adulta y 8.778 hogares con ingesta estimada.

## Estructura

```
scripts/      cadena de cálculo, 00 a 09, y diagnósticos de un solo uso
reports/      informes, manual y presentación (Quarto)
data/raw/     parámetros del análisis: valores de referencia, normas,
              escenarios, agrupación de alimentos, tablas de composición,
              factores de conversión y geometría provincial
data/auditoria/     registro de cambios y verificaciones
data/diagnosticos/  salidas de los diagnósticos que sustentan decisiones
media/        mapas y fotografías de la verificación en punto de venta
```

Los parámetros se editan en `data/raw/` sin tocar el código; al recompilar,
los resultados se actualizan. El manual técnico describe cada etapa, sus
supuestos y lo que deliberadamente no hace.

## Adaptación a otra encuesta

El código está escrito para la estructura de la ENGIH 2018. Otra encuesta exige
rehacer los nombres de variables, las tablas de factores de conversión y de
porción comestible, y la correspondencia con la tabla de composición. El
capítulo de adaptación del manual técnico indica qué se reutiliza y en qué
orden se trabaja.
