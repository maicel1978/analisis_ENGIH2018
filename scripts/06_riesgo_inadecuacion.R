# 06_riesgo_inadecuacion.R
#
# Riesgo de ingesta inadecuada por nutriente, sobre la estimacion principal
# (Sec 2 + Sec 3A con regla de agotamiento).
#
#   - Punto de corte: proporcion de hogares con ingesta por EMA bajo el EAR.
#   - Hierro: enfoque de probabilidad, con la distribucion del requerimiento.
#   - Proporcion de hogares sobre el limite superior tolerable (UL).
#   - Densidad de nutrientes por 1.000 kcal (mediana).
#
# Cada resultado se calcula con todos los hogares y solo con los de energia
# plausible: las colas de la distribucion determinan estas proporciones.
#
# Desagregacion: nacional, region, zona, quintil y provincia. Region y zona son
# dominios de estimacion de la encuesta; la provincia no lo es, y sus
# estimaciones se marcan como de precision baja cuando hay menos de 50 hogares
# o la semiamplitud del intervalo de confianza supera 10 puntos porcentuales.
# En proporciones el coeficiente de variacion penaliza las prevalencias bajas
# aunque sean precisas; se conserva en la salida como referencia.
#
# Los valores de referencia se leen de data/raw/valores_referencia.csv y
# data/raw/hierro_requerimiento.csv. Para cambiar de referencia se sustituyen
# esos archivos; este script no cambia.
#
# Lo que estas cifras no son: prevalencia de deficiencia. La ingesta es
# aparente, a nivel de hogar y por equivalente de mujer adulta; el reparto
# dentro del hogar se supone proporcional al requerimiento energetico.
#
# Requiere haber corrido 04 y 05.

library(dplyr)
library(tidyr)
library(readr)
library(srvyr)
library(here)

leer <- function(...) {
  read_delim(here(...), delim = ";", show_col_types = FALSE,
             locale = locale(decimal_mark = "."), guess_max = 100000)
}

# El requerimiento de hierro tabulado supone 18% de biodisponibilidad. Para
# otra biodisponibilidad el requerimiento dietetico se escala por 0,18 / b.
BIODISPONIBILIDAD_TABLA  <- 0.18
BIODISPONIBILIDAD_HIERRO <- c(0.10, 0.18)

referencia <- leer("data", "raw", "valores_referencia.csv")
req_hierro <- leer("data", "raw", "hierro_requerimiento.csv")

ingesta <- leer("data", "clean", "data_ingesta_micronutrientes_hogar.csv") |>
  filter(variante == "Sec 2 + Sec 3A")
DOMINIOS <- c(Nacional = "nacional", Region = "grupo_region", Zona = "zona",
              Quintil = "quintil", Provincia = "des_provincia")
SEMIAMPLITUD_MAX <- 10   # puntos porcentuales del intervalo de confianza
HOGARES_MIN <- 50

diseno_hogar <- leer("data", "clean", "data_ema_hogar.csv") |>
  mutate(nacional = "Total", quintil = as.character(quintil)) |>
  select(id_hogar_unico, estrato, upm, factor_expansion, all_of(unname(DOMINIOS)))

nutrientes <- intersect(referencia$nutriente, names(ingesta))
faltan <- setdiff(referencia$nutriente, nutrientes)
if (length(faltan) > 0) {
  stop("Nutrientes de la referencia ausentes en la ingesta: ",
       paste(faltan, collapse = ", "), call. = FALSE)
}

largo <- ingesta |>
  select(id_hogar_unico, energia_kcal, energia_plausible, all_of(nutrientes)) |>
  pivot_longer(all_of(nutrientes), names_to = "nutriente", values_to = "ingesta") |>
  left_join(referencia |> select(nutriente, ear, ul, metodo), by = "nutriente") |>
  inner_join(diseno_hogar, by = "id_hogar_unico") |>
  mutate(
    bajo_ear = as.numeric(ingesta < ear),
    sobre_ul = as.numeric(ingesta > ul),
    densidad = if_else(energia_kcal > 0, 1000 * ingesta / energia_kcal, NA_real_)
  )

# Probabilidad de que el requerimiento de hierro supere la ingesta observada.
prob_inadecuacion_hierro <- function(ingesta, biodisponibilidad) {
  req <- req_hierro$requerimiento_mg * BIODISPONIBILIDAD_TABLA / biodisponibilidad
  1 - approx(req, req_hierro$percentil / 100, xout = ingesta,
             yleft = 0, yright = 1)$y
}

resumir <- function(d, variable) {
  d |>
    summarise(
      n                = unweighted(n()),
      inadecuado       = survey_mean({{ variable }}, vartype = c("ci", "cv")),
      pct_sobre_ul     = 100 * survey_mean(sobre_ul, vartype = NULL, na.rm = TRUE),
      densidad_mediana = survey_median(densidad, vartype = NULL, na.rm = TRUE),
      .groups = "drop"
    )
}

estimar <- function(df, hogares, dominio) {
  d <- df |>
    mutate(nivel = .data[[DOMINIOS[[dominio]]]]) |>
    as_survey_design(ids = upm, strata = estrato,
                     weights = factor_expansion, nest = TRUE)

  corte <- d |>
    filter(metodo == "punto_de_corte") |>
    group_by(nivel, nutriente) |>
    resumir(bajo_ear) |>
    mutate(metodo = "Punto de corte")

  hierro <- lapply(BIODISPONIBILIDAD_HIERRO, function(b) {
    d |>
      filter(nutriente == "hierro_mg") |>
      mutate(prob = prob_inadecuacion_hierro(ingesta, b)) |>
      group_by(nivel, nutriente) |>
      resumir(prob) |>
      mutate(metodo = paste0("Probabilidad, biodisponibilidad ", 100 * b, "%"))
  }) |> bind_rows()

  bind_rows(corte, hierro) |>
    mutate(hogares = hogares, dominio = dominio, .before = 1)
}

combinaciones <- expand.grid(dominio = names(DOMINIOS),
                             hogares = c("Todos", "Energia plausible"),
                             stringsAsFactors = FALSE)

riesgo <- lapply(seq_len(nrow(combinaciones)), function(k) {
  df <- if (combinaciones$hogares[k] == "Todos") largo else largo |> filter(energia_plausible)
  estimar(df, combinaciones$hogares[k], combinaciones$dominio[k])
}) |>
  bind_rows() |>
  left_join(referencia |> select(nutriente, ear, ul, unidad, estado), by = "nutriente") |>
  transmute(
    dominio, nivel, hogares, nutriente, metodo, n, ear, ul, unidad,
    pct_inadecuado     = 100 * inadecuado,
    pct_inadecuado_low = 100 * inadecuado_low,
    pct_inadecuado_upp = 100 * inadecuado_upp,
    cv                 = inadecuado_cv,
    semiamplitud_ic    = (pct_inadecuado_upp - pct_inadecuado_low) / 2,
    precision_baja     = n < HOGARES_MIN | semiamplitud_ic > SEMIAMPLITUD_MAX,
    pct_sobre_ul       = if_else(is.na(ul), NA_real_, pct_sobre_ul),
    densidad_mediana, estado
  ) |>
  arrange(match(dominio, names(DOMINIOS)), nivel, nutriente, metodo, hogares)

message("Riesgo de ingesta inadecuada, total nacional (ponderado; valores de referencia: ",
        paste(unique(referencia$estado), collapse = ", "), "):")
print(as.data.frame(
  riesgo |> filter(dominio == "Nacional") |>
    select(hogares, nutriente, metodo, n, pct_inadecuado, pct_inadecuado_low,
           pct_inadecuado_upp, pct_sobre_ul, densidad_mediana)
), digits = 3)

message("\nPrecision por dominio (todos los hogares): celdas totales y de precision baja")
print(as.data.frame(
  riesgo |> filter(hogares == "Todos") |>
    group_by(dominio) |>
    summarise(niveles = n_distinct(nivel), celdas = n(),
              precision_baja = sum(precision_baja),
              hogares_min = min(n),
              semiamplitud_max = round(max(semiamplitud_ic, na.rm = TRUE), 1))
))

write_delim(riesgo, here("data", "clean", "riesgo_inadecuacion.csv"), delim = ";")
