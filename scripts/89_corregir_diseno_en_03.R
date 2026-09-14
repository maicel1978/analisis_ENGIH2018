# ==============================================================================
# 89_corregir_diseno_en_03.R
# Uso unico (2026-09-14). Borrar del repo una vez commiteado el resultado.
#
# QUE CORRIGE
# `03_transform.R` construye un ejemplo de estimacion ponderada con
# `as_survey_design(ids = 1, ...)` — es decir, sin conglomerados ni estratos —
# y advierte en pantalla que el intervalo "esta probablemente subestimado".
#
# Esa advertencia dejo de ser cierta el 2026-09-13: `01_import.R` escribe ahora
# `estrato` y `upm` en data/clean/data_sociodemografia.csv. El ejemplo puede
# declarar el diseno completo.
#
# Dejarlo como estaba tiene un costo concreto: el pipeline imprime en cada
# corrida una advertencia que contradice lo que hacen los reportes.
# ==============================================================================

library(here)

ruta <- here("scripts", "03_transform.R")
if (!file.exists(ruta)) stop("No encuentro scripts/03_transform.R", call. = FALSE)

txt <- paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

if (grepl("strata = estrato", txt, fixed = TRUE)) {
  stop("Ya esta corregido. Nada que hacer.", call. = FALSE)
}

# --- 1. El bloque del ejemplo -------------------------------------------------
viejo <- '# Paso 5: Ejemplo de agregado PONDERADO (demuestra el método correcto) -------
# OJO: `ids = ~1` porque no tenemos las variables de conglomerado/estrato
# (ver advertencia al inicio del script). El punto estimado (media, total,
# proporción) es correcto; el error estándar es una aproximación.'

nuevo <- '# Paso 5: Ejemplo de agregado PONDERADO (demuestra el método correcto) -------
# Desde 2026-09-13 el diseño muestral se declara COMPLETO: estrato, UPM y factor
# de expansión. `01_import.R` escribe estrato y upm en data_sociodemografia.csv.
#
# La diferencia no es menor: con `ids = 1` (sin conglomerados) el error estándar
# se subestima de forma sistemática y los intervalos salen demasiado estrechos.
# El punto estimado apenas cambia; la precisión declarada, mucho.'

if (regexpr(viejo, txt, fixed = TRUE) == -1) {
  stop("No encuentro el comentario del Paso 5", call. = FALSE)
}
txt <- sub(viejo, nuevo, txt, fixed = TRUE)

# --- 2. Cargar las variables de diseño ----------------------------------------
viejo2 <- 'sec3a_hogar <- sec3a_data |>
  filter(!is.na(Consumo_diario_g), !es_outlier) |>
  distinct(id_hogar_unico, factor_expansion) |>
  filter(!is.na(factor_expansion))

diseno_ejemplo <- sec3a_hogar |>
  as_survey_design(ids = 1, weights = factor_expansion)'

nuevo2 <- '# Variables de diseño, a nivel de hogar. Se toma el primer registro de cada
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
  filter(!is.na(estrato), !is.na(upm), !is.na(factor_expansion))'

if (regexpr(viejo2, txt, fixed = TRUE) == -1) {
  stop("No encuentro el bloque de sec3a_hogar", call. = FALSE)
}
txt <- sub(viejo2, nuevo2, txt, fixed = TRUE)

# --- 3. La estimación, con el diseño completo ---------------------------------
viejo3 <- 'cobertura_hogares <- sec3a_data |>
  filter(!es_outlier | is.na(es_outlier)) |>
  mutate(consume_item = if_else(enhance_id == ejemplo_enhance_id & !is.na(Consumo_diario_g), 1, 0)) |>
  group_by(id_hogar_unico) |>
  summarise(consume_item = max(consume_item), factor_expansion = first(factor_expansion), .groups = "drop") |>
  filter(!is.na(factor_expansion)) |>
  as_survey_design(ids = 1, weights = factor_expansion) |>
  summarise(cobertura_pct = survey_mean(consume_item, vartype = "ci") * 100)'

nuevo3 <- 'cobertura_hogares <- sec3a_data |>
  filter(!es_outlier | is.na(es_outlier)) |>
  mutate(consume_item = if_else(enhance_id == ejemplo_enhance_id & !is.na(Consumo_diario_g), 1, 0)) |>
  group_by(id_hogar_unico) |>
  summarise(consume_item = max(consume_item), .groups = "drop") |>
  inner_join(diseno_vars, by = "id_hogar_unico") |>
  as_survey_design(ids = upm, strata = estrato,
                   weights = factor_expansion, nest = TRUE) |>
  summarise(cobertura_pct = survey_mean(consume_item, vartype = "ci") * 100)'

if (regexpr(viejo3, txt, fixed = TRUE) == -1) {
  stop("No encuentro el bloque de cobertura_hogares", call. = FALSE)
}
txt <- sub(viejo3, nuevo3, txt, fixed = TRUE)

# --- 4. El mensaje ------------------------------------------------------------
viejo4 <- '  "%) -- ojo: IC probablemente subestimado, ver advertencia de diseño muestral arriba."'
nuevo4 <- '  "%) -- diseño completo: ", n_distinct(diseno_vars$estrato), " estratos, ",
  n_distinct(diseno_vars$upm), " UPM."'

if (regexpr(viejo4, txt, fixed = TRUE) == -1) {
  stop("No encuentro el mensaje del ejemplo", call. = FALSE)
}
txt <- sub(viejo4, nuevo4, txt, fixed = TRUE)

writeLines(strsplit(txt, "\n")[[1]], ruta, useBytes = TRUE)

cat("\n--------------------------------------------------\n")
cat("scripts/03_transform.R corregido.\n")
cat("--------------------------------------------------\n")
cat("\nVerificar con:\n")
cat('  source(here::here("scripts", "03_transform.R"))\n\n')
cat("El mensaje del ejemplo debe terminar en:\n")
cat("  diseño completo: 8 estratos, 933 UPM.\n\n")
cat("Y el intervalo debe ser MAS ANCHO que antes (29.3-31.6): esa es la\n")
cat("correccion. Con conglomerados el error estandar sube.\n")
