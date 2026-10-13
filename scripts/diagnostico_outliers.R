# diagnostico_outliers.R
#
# Huella de la exclusion de valores atipicos sobre la estimacion principal.
#
# El tratamiento esta documentado en el Anexo B del informe: 03_transform.R
# marca por alimento y 04_equivalente_adulto.R excluye las filas marcadas. Lo
# que no estaba medido es CUANTO retira esa exclusion. Este diagnostico lo
# acota sin rehacer la cadena:
#
#   - filas marcadas sobre el total, por seccion
#   - gramos retirados sobre el total de gramos
#   - hogares con al menos una fila retirada
#   - aporte de nutriente retirado sobre el total, por nutriente
#
# Criterio de lectura. Si la fraccion de nutriente retirada es de pocas
# decimas, la exclusion no puede mover una mediana de forma material y el
# Anexo B queda cerrado con esta cifra. Si es de varios puntos, hace falta
# rehacer 04 a 07 sin la exclusion y comparar las estimaciones, que es un
# trabajo mayor.
#
# Requiere haber corrido 01, 03 y 04. De un solo uso: la salida se escribe en
# data/diagnosticos/ y no alimenta a ningun script posterior.

library(dplyr)
library(tidyr)
library(readr)
library(srvyr)
library(here)

leer <- function(...) {
  read_delim(here(...), delim = ";", show_col_types = FALSE,
             locale = locale(decimal_mark = "."), guess_max = 100000)
}

NUTRIENTES <- c("energia_kcal", "hierro_mg", "folato_mcg_dfe", "zinc_mg",
                "vitamina_b12_mcg", "vitamina_a_mcg_rae")

# Guarda: si 04 dejara de excluir, este diagnostico mediria algo que ya no
# ocurre. Se comprueba contra el codigo, no contra la memoria.
src04 <- readLines(here("scripts", "04_equivalente_adulto.R"), warn = FALSE)
if (!any(grepl("!es_outlier", src04, fixed = TRUE))) {
  stop("04_equivalente_adulto.R ya no excluye las filas marcadas como atipicas. ",
       "Este diagnostico no aplica: revisar el Anexo B del informe.", call. = FALSE)
}

comp  <- leer("data", "clean", "composicion_unificada.csv") |>
  select(enhance_id, all_of(NUTRIENTES))
hogar <- leer("data", "clean", "data_ema_hogar.csv") |>
  select(id_hogar_unico, estrato, upm, factor_expansion, EMA_hogar)

filas <- bind_rows(
  leer("data", "clean", "data_sec2_consumo.csv")  |>
    select(id_hogar_unico, enhance_id, Consumo_diario_g, es_outlier) |>
    mutate(seccion = "Sec 2"),
  leer("data", "clean", "data_sec3a_consumo.csv") |>
    select(id_hogar_unico, enhance_id, Consumo_diario_g, es_outlier) |>
    mutate(seccion = "Sec 3A")
) |>
  filter(!is.na(Consumo_diario_g)) |>
  mutate(retirada = coalesce(es_outlier, FALSE))

# 1. Filas y gramos ---------------------------------------------------------
por_seccion <- filas |>
  group_by(seccion) |>
  summarise(filas = n(),
            filas_retiradas = sum(retirada),
            pct_filas = 100 * mean(retirada),
            gramos = sum(Consumo_diario_g),
            gramos_retirados = sum(Consumo_diario_g[retirada]),
            .groups = "drop") |>
  mutate(pct_gramos = 100 * gramos_retirados / gramos)

message("Filas y gramos retirados por la exclusion de atipicos:")
print(as.data.frame(por_seccion), digits = 4)

# 2. Hogares afectados ------------------------------------------------------
# Ponderado con el diseno completo, que es como se reporta cualquier otra
# proporcion de este analisis.
afectados <- filas |>
  group_by(id_hogar_unico) |>
  summarise(alguna = any(retirada), .groups = "drop") |>
  inner_join(hogar, by = "id_hogar_unico") |>
  as_survey_design(ids = upm, strata = estrato, weights = factor_expansion,
                   nest = TRUE) |>
  summarise(pct_hogares = 100 * survey_mean(alguna, vartype = "ci"),
            n = unweighted(n()))

message("\nHogares con al menos una fila retirada (ponderado):")
print(as.data.frame(afectados), digits = 4)

# 3. Nutriente retirado -----------------------------------------------------
# Sin ponderar por diseno: es una fraccion del total de nutriente del archivo,
# no una estimacion poblacional.
nutri <- filas |>
  inner_join(comp, by = "enhance_id") |>
  mutate(across(all_of(NUTRIENTES), ~ .x * Consumo_diario_g / 100)) |>
  pivot_longer(all_of(NUTRIENTES), names_to = "nutriente", values_to = "aporte") |>
  group_by(nutriente) |>
  summarise(total = sum(aporte, na.rm = TRUE),
            retirado = sum(aporte[retirada], na.rm = TRUE),
            .groups = "drop") |>
  mutate(pct_retirado = 100 * retirado / total) |>
  arrange(desc(pct_retirado))

message("\nAporte de nutriente retirado, sobre el total del archivo:")
print(as.data.frame(nutri |> select(nutriente, pct_retirado)), digits = 3)

dir.create(here("data", "diagnosticos"), showWarnings = FALSE, recursive = TRUE)
write_delim(por_seccion, here("data", "diagnosticos", "outliers_por_seccion.csv"), delim = ";")
write_delim(nutri,       here("data", "diagnosticos", "outliers_por_nutriente.csv"), delim = ";")

message("\nLectura: si pct_retirado es de pocas decimas en los nutrientes del ",
        "analisis, la exclusion no mueve las medianas de forma material. ",
        "Si supera un punto, rehacer 04 a 07 sin la exclusion y comparar.")
