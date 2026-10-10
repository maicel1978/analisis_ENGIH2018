# diagnostico_densidad_critica.R
#
# Decision E1 de docs/hoja-de-ruta.md: densidad de nutrientes frente a ingesta
# absoluta para comparacion geografica. Este script aporta la evidencia y
# cuantifica la diferencia entre los dos criterios.
#
# CONSTRUCCION. No introduce valores de referencia nuevos. El denominador del
# Equivalente de Mujer Adulta son 2.291 kcal, que es el requerimiento
# energetico de la mujer adulta de 18 a 30 anos, no embarazada ni lactando
# (FAO/WHO/UNU 2004; ver el encabezado de 04_equivalente_adulto.R). Los
# Requerimientos Promedio Estimados de data/raw/valores_referencia.csv son de
# esa misma mujer de referencia (IOM, 19 a 30 anos). De modo que la densidad
# que esa mujer necesita queda determinada por los dos parametros que el
# proyecto ya usa:
#
#   densidad_critica = RPE / 2291 * 1000      (por 1.000 kcal)
#
# IDENTIDAD. Para un hogar cualquiera, con la ingesta y la energia expresadas
# por EMA y dia:
#
#   densidad / densidad_critica = (ingesta / RPE) * (2291 / energia)
#
# Los dos criterios coinciden cuando la energia registrada por EMA es 2.291
# kcal, y divergen por el factor exacto en que la supera. El criterio de punto
# de corte sobre la ingesta es mas indulgente donde se registra mas energia.
# Por eso el patron provincial del riesgo seguia a la energia registrada
# (r = -0,73 en folato) y no a la composicion de la dieta.
#
# ALCANCE. Solo nutrientes de punto de corte. El hierro se evalua por el
# enfoque de probabilidad sobre la distribucion del requerimiento y su
# equivalente en densidad exigiria escalar esa distribucion: queda fuera y se
# declara.
#
# LIMITACION. El criterio de densidad supone que el sobrerregistro es
# multiplicativo, es decir, que afecta por igual a todos los alimentos del
# hogar. En estos datos el supuesto esta respaldado y no solo asumido: en las
# tres provincias de mayor energia las dos secciones se inflan por factores
# parecidos (1,64x y 1,55x) y la composicion de la dieta es la del resto del
# pais (79,4% del folato desde cereales y raices frente a 81,7% nacional).
#
# No modifica el pipeline: lee data/clean y data/raw, e imprime.
# Requiere haber corrido 04, 05, 06 y 07.
#
# Uso: source(here::here("scripts", "diagnostico_densidad_critica.R"))

library(dplyr); library(tidyr); library(readr); library(here); library(srvyr)

leer <- function(...) read_delim(here(...), delim = ";", show_col_types = FALSE,
                                locale = locale(decimal_mark = "."), guess_max = 100000)

KCAL_EMA        <- 2291                               # FAO/WHO/UNU 2004
ESCENARIO_BASE  <- "1a. Norma nacional: harina y pan"
DOMINIOS        <- c(Nacional = "nacional", Region = "grupo_region", Zona = "zona",
                     Quintil = "quintil", Provincia = "des_provincia")

# Guarda: si cambia la base energetica del EMA en 04, la densidad critica de
# este script queda obsoleta en silencio. Se verifica contra el propio script.
src04 <- readLines(here("scripts", "04_equivalente_adulto.R"), warn = FALSE)
if (!any(grepl(as.character(KCAL_EMA), src04, fixed = TRUE))) {
  stop("04_equivalente_adulto.R no menciona ", KCAL_EMA, " kcal. La base ",
       "energetica del EMA cambio: revisar la densidad critica antes de seguir.",
       call. = FALSE)
}

# --- 1. Densidad critica por nutriente --------------------------------------
referencia <- leer("data", "raw", "valores_referencia.csv") |>
  mutate(densidad_critica = 1000 * ear / KCAL_EMA)

message("\n== Densidad critica, derivada del RPE y del denominador del EMA (",
        KCAL_EMA, " kcal) ==")
print(as.data.frame(
  referencia |>
    transmute(nutriente, unidad, ear, metodo,
              densidad_critica = round(densidad_critica, 2),
              estado)
), digits = 4)

corte <- referencia |> filter(metodo == "punto_de_corte")

# --- 2. Ingesta por hogar, armada igual que en 07 ---------------------------
ingesta <- leer("data", "clean", "data_ingesta_micronutrientes_hogar.csv") |>
  filter(variante == "Sec 2 + Sec 3A")
escenarios <- leer("data", "clean", "escenarios_ingesta_hogar.csv") |>
  filter(escenario == ESCENARIO_BASE)

fijos <- setdiff(corte$nutriente, unique(escenarios$nutriente))
sin_escenario <- ingesta |>
  select(id_hogar_unico, all_of(fijos)) |>
  pivot_longer(all_of(fijos), names_to = "nutriente", values_to = "ingesta")

hogar <- leer("data", "clean", "data_ema_hogar.csv") |>
  mutate(nacional = "Total", quintil = as.character(quintil)) |>
  select(id_hogar_unico, estrato, upm, factor_expansion, all_of(unname(DOMINIOS)))

largo <- bind_rows(
  escenarios |> filter(nutriente %in% corte$nutriente) |>
    select(id_hogar_unico, nutriente, ingesta),
  sin_escenario
) |>
  inner_join(ingesta |> select(id_hogar_unico, energia_kcal), by = "id_hogar_unico") |>
  inner_join(corte |> select(nutriente, ear, densidad_critica), by = "nutriente") |>
  inner_join(hogar, by = "id_hogar_unico") |>
  mutate(densidad   = if_else(energia_kcal > 0, 1000 * ingesta / energia_kcal, NA_real_),
         bajo_ear   = as.numeric(ingesta < ear),
         bajo_dens  = as.numeric(densidad < densidad_critica))

# Los dos criterios se calculan sobre los mismos hogares. Sin energia
# registrada la densidad no esta definida, y comparar criterios con
# denominadores distintos no es comparar criterios.
sin_energia <- largo |> filter(is.na(densidad)) |> distinct(id_hogar_unico) |> nrow()
if (sin_energia > 0) {
  message("AVISO: ", sin_energia, " hogares sin energia registrada quedan fuera ",
          "de los dos criterios.")
  largo <- largo |> filter(!is.na(densidad))
}

estimar <- function(dominio) {
  largo |>
    mutate(nivel = .data[[DOMINIOS[[dominio]]]]) |>
    as_survey_design(ids = upm, strata = estrato, weights = factor_expansion,
                     nest = TRUE) |>
    group_by(nivel, nutriente) |>
    summarise(n          = unweighted(n()),
              energia    = survey_median(energia_kcal, vartype = NULL),
              pct_ingesta = 100 * survey_mean(bajo_ear,  vartype = NULL),
              pct_densidad = 100 * survey_mean(bajo_dens, vartype = NULL),
              .groups = "drop") |>
    mutate(dominio = dominio, .before = 1)
}

res <- bind_rows(lapply(names(DOMINIOS), estimar))

# Guarda: la columna de punto de corte sobre la ingesta debe reproducir
# riesgo_inadecuacion.csv. Si no, la armada de este script divergio de 07.
ref07 <- leer("data", "clean", "riesgo_inadecuacion.csv") |>
  filter(escenario == ESCENARIO_BASE, hogares == "Todos",
         metodo == "Punto de corte") |>
  select(dominio, nivel, nutriente, pct_ref = pct_inadecuado)
chk <- inner_join(res, ref07, by = c("dominio", "nivel", "nutriente"))
if (nrow(chk) != nrow(ref07) || any(abs(chk$pct_ingesta - chk$pct_ref) > 0.01)) {
  print(as.data.frame(chk |> filter(abs(pct_ingesta - pct_ref) > 0.01)))
  stop("El criterio de ingesta no reproduce 07. Revisar antes de interpretar.",
       call. = FALSE)
}
message("\nGuarda superada: el criterio de ingesta reproduce riesgo_inadecuacion.csv ",
        "en las ", nrow(chk), " celdas comparables.")

# --- 3. Nacional: cuanto se aparta la energia registrada de la de referencia -
e_nac <- res |> filter(dominio == "Nacional") |> pull(energia) |> median()
message("\n== Nacional ==")
message("Energia registrada, mediana por EMA y dia: ", round(e_nac), " kcal")
message("Requerimiento de la mujer de referencia:   ", KCAL_EMA, " kcal")
message("Factor: ", sprintf("%.3f", e_nac / KCAL_EMA),
        "  (los dos criterios coinciden cuando vale 1)")
print(as.data.frame(
  res |> filter(dominio == "Nacional") |>
    transmute(nutriente,
              ingesta  = round(pct_ingesta, 1),
              densidad = round(pct_densidad, 1),
              dif      = round(pct_densidad - pct_ingesta, 1))
))

# --- 4. Dominios de estimacion: el confundidor alcanza a region y zona? -----
message("\n== Dominios de estimacion de la encuesta (folato) ==")
print(as.data.frame(
  res |> filter(dominio %in% c("Region", "Zona", "Quintil"),
                nutriente == "folato_mcg_dfe") |>
    transmute(dominio, nivel, n,
              energia  = round(energia),
              factor_kcal = round(energia / KCAL_EMA, 2),
              ingesta  = round(pct_ingesta, 1),
              densidad = round(pct_densidad, 1),
              dif      = round(pct_densidad - pct_ingesta, 1))
))

# --- 5. Provincias: reordena la densidad el mapa? ---------------------------
prov <- res |> filter(dominio == "Provincia", nutriente == "folato_mcg_dfe")

message("\n== Provincias de folato, ordenadas por energia registrada ==")
print(as.data.frame(
  prov |> arrange(desc(energia)) |>
    transmute(nivel, n, energia = round(energia),
              factor_kcal = round(energia / KCAL_EMA, 2),
              ingesta  = round(pct_ingesta, 1),
              densidad = round(pct_densidad, 1),
              dif      = round(pct_densidad - pct_ingesta, 1))
))

message("\n== Dispersion provincial bajo cada criterio (32 provincias) ==")
message(sprintf("  ingesta   min %5.1f  max %5.1f  rango %5.1f  DE %5.1f",
                min(prov$pct_ingesta), max(prov$pct_ingesta),
                diff(range(prov$pct_ingesta)), sd(prov$pct_ingesta)))
message(sprintf("  densidad  min %5.1f  max %5.1f  rango %5.1f  DE %5.1f",
                min(prov$pct_densidad), max(prov$pct_densidad),
                diff(range(prov$pct_densidad)), sd(prov$pct_densidad)))
message(sprintf("  correlacion con la energia registrada: ingesta %5.2f  densidad %5.2f",
                cor(prov$energia, prov$pct_ingesta),
                cor(prov$energia, prov$pct_densidad)))

write_delim(res, here("data", "clean", "sensibilidad_densidad_critica.csv"), delim = ";")
message("\nSalida en data/clean/sensibilidad_densidad_critica.csv")
