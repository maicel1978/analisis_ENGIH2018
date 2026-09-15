# =============================================================================
# 03_transform.R
# Proyecto: ENGIH 2018 - Consumo de alimentos y nutrición (WFP)
# =============================================================================
#
# Objetivo de esta etapa
#   Tomar la salida de 01_import.R (Q, fc, enhance_id, edible, PM/dias_observados
#   por sección) y:
#     1. Calcular Consumo_diario_g = Q * fc * edible / PM
#     2. Detectar (NO corregir automáticamente) outliers por alimento (Paso 7
#        de la guía MIMI/WFP)
#     3. Conectar los pesos muestrales (factor_anual / factor_expansion) para
#        que cualquier agregado sea representativo a nivel nacional
#
# Lo que esta etapa no hace
#   - Disponibilidad neta Sec 2 + Sec 3A para alimentos almacenables
#     (inventario_inicial + adquisiciones - inventario_final). Requiere decidir
#     antes el tratamiento de las dos secciones.
#   - Corrección de outliers. Aquí solo se marcan (`es_outlier`); el método de
#     corrección es una decisión metodológica pendiente de documentar.
#   - Control de outliers a nivel de hogar. La detección opera por alimento, de
#     modo que un hogar puede acumular varios valores altos sin que ninguno sea
#     individualmente extremo.
#
# Diseño muestral
#   Las variables de estratificación y conglomeración (ESTRATO, UPM) están en el
#   módulo sociodemográfico y se incorporaron al pipeline el 2026-09-13. El
#   ejemplo de estimación ponderada de este script declara el diseño completo
#   (strata, ids, weights), no solo los pesos.
#
#   Ver docs/hoja-de-ruta.md para el estado de las decisiones abiertas.

# Configuración general ---------------------------------------------------
rm(list = ls())
options(stringsAsFactors = FALSE)

library(conflicted)
library(readr)
library(here)
library(dplyr)
library(srvyr)   # wrapper de `survey` en sintaxis tidyverse
conflicts_prefer(dplyr::filter)

# Rutas ---------------------------------------------------------------------
ruta_sec2  <- here("data", "clean", "data_sec2.csv")
ruta_sec3a <- here("data", "clean", "data_sec3a.csv")

# Paso 1: Leer datos de 01_import.R ------------------------------------------
sec2_data  <- read_delim(ruta_sec2,  delim = ";", show_col_types = FALSE)
sec3a_data <- read_delim(ruta_sec3a, delim = ";", show_col_types = FALSE)

# Paso 2: Calcular consumo diario en gramos comestibles ----------------------
# Consumo_diario_g = Q * fc * edible / PM
#
# Sec 2: PM es la constante de diseño (7 días, inventario inicial/final).
# Sec 3A: PM = dias_observados_hogar (ya calculado en 01_import.R) -- NO la
#   constante sec3a_PM=1 que quedó declarada por diseño original pero que
#   confirmamos incorrecta contra los datos reales (ver CHANGELOG de
#   01_import.R, punto 1).

sec2_data <- sec2_data |>
  mutate(
    Consumo_diario_g = (Q * fc * edible) / PM
  )

sec3a_data <- sec3a_data |>
  mutate(
    PM_real = if_else(!is.na(dias_observados_hogar) & dias_observados_hogar > 0,
                      dias_observados_hogar, PM),
    Consumo_diario_g = (Q * fc * edible) / PM_real
  )
# 
# message(
#   "Sec 2  -- Consumo_diario_g calculado en ", sum(!is.na(sec2_data$Consumo_diario_g)),
#   " de ", nrow(sec2_data), " filas (el resto queda NA por FC/enhance_id/PC pendientes)."
# )
# message(
#   "Sec 3A -- Consumo_diario_g calculado en ", sum(!is.na(sec3a_data$Consumo_diario_g)),
#   " de ", nrow(sec3a_data), " filas."
# )

# Paso 3: Detección de outliers (Paso 7, guía MIMI/WFP) -----------------------
# Se MARCA, no se corrige. El método de corrección (reemplazo por mediana,
# winsorizar, excluir) es una decisión metodológica que hay que documentar
# explícitamente en el análisis de sensibilidad (ver HOJA_DE_RUTA, Fase 0.5) --
# no algo para decidir en silencio adentro de un script.
#
# Regla acá: para cada enhance_id con al menos 20 observaciones, marca como
# outlier cualquier valor > 5x el percentil 99.5 o < percentil 0.5 / 5 (misma
# regla que usamos para diagnosticar CANTIDAD_ADQUIRIDA en la auditoría).

marcar_outliers <- function(df) {
  df |>
    group_by(enhance_id) |>
    mutate(
      n_grupo = n(),
      p995 = if_else(n_grupo >= 20, quantile(Consumo_diario_g, 0.995, na.rm = TRUE), NA_real_),
      p005 = if_else(n_grupo >= 20, quantile(Consumo_diario_g, 0.005, na.rm = TRUE), NA_real_),
      es_outlier = !is.na(Consumo_diario_g) & !is.na(p995) &
        (Consumo_diario_g > p995 * 5 | (Consumo_diario_g < p005 / 5 & Consumo_diario_g > 0))
    ) |>
    ungroup() |>
    select(-n_grupo, -p995, -p005)
}

sec2_data  <- marcar_outliers(sec2_data)
sec3a_data <- marcar_outliers(sec3a_data)

message(
  "Sec 2  -- filas marcadas como posible outlier: ", sum(sec2_data$es_outlier, na.rm = TRUE)
)
message(
  "Sec 3A -- filas marcadas como posible outlier: ", sum(sec3a_data$es_outlier, na.rm = TRUE)
)

# Paso 4: Guardar datos con consumo calculado --------------------------------
write_delim(sec2_data,  here("data", "clean", "data_sec2_consumo.csv"),  delim = ";")
write_delim(sec3a_data, here("data", "clean", "data_sec3a_consumo.csv"), delim = ";")

# Paso 5: Ejemplo de agregado PONDERADO (demuestra el método correcto) -------
# Desde 2026-09-13 el diseño muestral se declara COMPLETO: estrato, UPM y factor
# de expansión. `01_import.R` escribe estrato y upm en data_sociodemografia.csv.
#
# La diferencia no es menor: con `ids = 1` (sin conglomerados) el error estándar
# se subestima de forma sistemática y los intervalos salen demasiado estrechos.
# El punto estimado apenas cambia; la precisión declarada, mucho.

# Variables de diseño, a nivel de hogar. Se toma el primer registro de cada
# hogar: el diseño es propiedad del hogar, no de la persona.
diseno_vars <- read_delim(
  here("data", "clean", "data_sociodemografia.csv"),
  delim = ";", show_col_types = FALSE
) |>
  group_by(id_hogar_unico) |>
  summarise(estrato          = first(estrato),
            upm              = first(upm),
            factor_expansion = first(factor_expansion),
            .groups = "drop") |>
  filter(!is.na(estrato), !is.na(upm), !is.na(factor_expansion))

# Ejemplo: cobertura ponderada de un alimento (reemplazar 70213002 = arroz
# blanco enriquecido, ya validado, por el enhance_id que se quiera revisar)
ejemplo_enhance_id <- 70213002

cobertura_hogares <- sec3a_data |>
  filter(!es_outlier | is.na(es_outlier)) |>
  mutate(consume_item = if_else(enhance_id == ejemplo_enhance_id & !is.na(Consumo_diario_g), 1, 0)) |>
  group_by(id_hogar_unico) |>
  summarise(consume_item = max(consume_item), .groups = "drop") |>
  inner_join(diseno_vars, by = "id_hogar_unico") |>
  as_survey_design(ids = upm, strata = estrato,
                   weights = factor_expansion, nest = TRUE) |>
  summarise(cobertura_pct = survey_mean(consume_item, vartype = "ci") * 100)

message(
  "Ejemplo (enhance_id ", ejemplo_enhance_id, ") -- cobertura ponderada: ",
  round(cobertura_hogares$cobertura_pct, 1), "% (IC ",
  round(cobertura_hogares$cobertura_pct_low, 1), "-",
  round(cobertura_hogares$cobertura_pct_upp, 1),
  "%) -- diseño completo: ", n_distinct(diseno_vars$estrato), " estratos, ",
  n_distinct(diseno_vars$upm), " UPM."
)

# Resumen y siguientes pasos --------------------------------------------------
# Este script deja:
#   Consumo_diario_g, es_outlier, PM_real (Sec 3A)
# guardados en data/clean/data_sec{2,3a}_consumo.csv, más un ejemplo de
# agregado ponderado correcto (cobertura de un alimento).
#
# PENDIENTE (no acá, ver docs/hoja-de-ruta.md):
#   - Disponibilidad neta Sec 2 + Sec 3A para alimentos almacenables.
#   - Decidir y documentar el método de corrección de outliers (hoy solo
#     se marcan, no se corrigen).
#   - Control de outliers a nivel de hogar, una vez resuelto el tratamiento de
#     las dos secciones.
