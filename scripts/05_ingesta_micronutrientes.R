# 05_ingesta_micronutrientes.R
#
# Ingesta aparente de micronutrientes por EMA/dia, a nivel de hogar.
# Alcance acotado a 4 nutrientes: Energia, Hierro, Acido folico, Vitamina A.
#
# Equivalencia de columnas (verificada 2026-09-09):
#   Nutriente     | INCAP      | FNDDS                     | Unidad
#   Energia       | ENERC_KCAL | Energy (kcal)             | kcal
#   Hierro        | FE         | Iron\n(mg)                | mg
#   Acido folico  | FOLDFE     | Folate, DFE (mcg_DFE)     | mcg DFE
#   Vitamina A    | VITA_RAE   | Vitamin A, RAE (mcg_RAE)  | mcg RAE
# FNDDS trae TRES columnas de folato; solo "Folate, DFE" corresponde a FOLDFE.
# Las 4 unidades coinciden entre tablas -- sin factor de conversion.
#
# Verificado 2026-09-10 sobre los archivos reales (no asumido):
#   - INCAP: 1,466 filas, ENHANCE_ID unico. FNDDS: 7,083 filas, Food code unico.
#   - Interseccion INCAP x FNDDS = 0 IDs. Por eso bind_rows() es seguro aqui.
#     Se deja una comprobacion en codigo (stop) para que no dependa de esa
#     verificacion puntual si alguna tabla se actualiza.
#   - En el crosswalk, ningun enhance_id validado aparece con dos `fuente`
#     distintas (211 enhance_id distintos).
#   - Trampa de nombres: la hoja "Cuest. B Sec 2" usa `variedad` y la hoja
#     "Cuest. B Sec 3A" usa `id_variedad`. Aqui no se usa ninguna de las dos
#     (el join es por enhance_id, que ya viene resuelto desde 01_import.R),
#     pero conviene saberlo antes de tocar esas hojas en otro script.
#   - `validado` es booleano en Sec 2 y 0/1 numerico en Sec 3A -> as.logical().
#
# SUPUESTO EXPLICITO, no validado con la documentacion de origen:
#   ambas tablas expresan los nutrientes por 100 g de porcion comestible.
#   Todo el calculo divide entre 100. Verificar contra la doc de INCAP/FNDDS
#   antes de reportar cifras a supervisores.

library(conflicted)
library(readr)
library(dplyr)
library(tidyr)
library(readxl)
library(here)
conflicts_prefer(dplyr::filter)

NUTRIENTES <- c("energia_kcal", "hierro_mg", "folato_mcg_dfe", "vitamina_a_mcg_rae")

# Paso 1: consumo por EMA (04_equivalente_adulto.R) -----------------------
gramos_por_ema <- read_delim(
  here("data", "clean", "data_gramos_por_ema.csv"),
  delim = ";",
  show_col_types = FALSE
)

# Paso 2: crosswalk -> de que tabla sale cada enhance_id ------------------
leer_crosswalk <- function(hoja) {
  read_excel(here("data", "raw", "crosswalk_tablas_composicion.xlsx"), sheet = hoja) |>
    filter(!is.na(enhance_id), as.logical(validado) %in% TRUE) |>
    transmute(enhance_id = as.numeric(enhance_id), fuente)
}

fuente_por_id <- bind_rows(
  leer_crosswalk("Cuest. B Sec 2"),
  leer_crosswalk("Cuest. B Sec 3A")
) |>
  distinct(enhance_id, fuente)

conflictos_fuente <- fuente_por_id |> count(enhance_id) |> filter(n > 1)
if (nrow(conflictos_fuente) > 0) {
  stop("enhance_id con mas de una `fuente` en el crosswalk: ",
       paste(conflictos_fuente$enhance_id, collapse = ", "))
}

# Paso 3: tablas de composicion, con nombres estandarizados ---------------
nutrientes_incap <- read_excel(
  here("data", "raw", "food_composition_INCAP.xlsx"),
  sheet = "nutrient_values"
) |>
  transmute(
    enhance_id = as.numeric(ENHANCE_ID),
    fuente = "INCAP",
    energia_kcal = ENERC_KCAL,
    hierro_mg = FE,
    folato_mcg_dfe = FOLDFE,
    vitamina_a_mcg_rae = VITA_RAE
  )

nutrientes_fndds <- read_excel(
  here("data", "raw", "food_composition_FNDDS.xlsx"),
  skip = 1
) |>
  transmute(
    enhance_id = as.numeric(`Food code`),
    fuente = "FNDDS",
    energia_kcal = `Energy (kcal)`,
    hierro_mg = `Iron\n(mg)`,               # el nombre real trae salto de linea
    folato_mcg_dfe = `Folate, DFE (mcg_DFE)`, # NO usar las otras 2 de folato
    vitamina_a_mcg_rae = `Vitamin A, RAE (mcg_RAE)`
  )

colisiones <- intersect(nutrientes_incap$enhance_id, nutrientes_fndds$enhance_id)
if (length(colisiones) > 0) {
  stop("Hay ", length(colisiones), " id presentes en INCAP y FNDDS a la vez. ",
       "El join debe hacerse por (enhance_id, fuente), no solo por enhance_id.")
}

composicion <- bind_rows(nutrientes_incap, nutrientes_fndds)

# Paso 4: unir consumo + composicion --------------------------------------
# left_join a proposito: las filas sin match se conservan para poder medir
# la cobertura real. Se une por enhance_id (verificado unico entre fuentes);
# `fuente` viene del crosswalk solo como trazabilidad del origen del dato.
consumo_nutrientes <- gramos_por_ema |>
  left_join(fuente_por_id, by = "enhance_id") |>
  left_join(composicion |> select(-fuente), by = "enhance_id") |>
  mutate(across(all_of(NUTRIENTES), ~ Gramos_por_EMA_dia * .x / 100))

# Paso 5: ingesta aparente por hogar --------------------------------------
ingesta_hogar <- consumo_nutrientes |>
  group_by(id_hogar_unico) |>
  summarise(across(all_of(NUTRIENTES), ~ sum(.x, na.rm = TRUE)), .groups = "drop")

# Paso 6: cobertura -- ponderada por gramos, por nutriente ----------------
# Este numero acompana al resultado siempre: sin el, la ingesta se lee como
# si fuera completa cuando en realidad es un piso (los alimentos sin match
# suman 0, no NA, y por tanto SUBESTIMAN la ingesta).
total_g <- sum(gramos_por_ema$Gramos_por_EMA_dia, na.rm = TRUE)

cobertura <- tibble(nutriente = NUTRIENTES) |>
  rowwise() |>
  mutate(
    g_con_dato = sum(
      gramos_por_ema$Gramos_por_EMA_dia[!is.na(consumo_nutrientes[[nutriente]])],
      na.rm = TRUE
    ),
    pct_gramos_cubiertos = 100 * g_con_dato / total_g
  ) |>
  ungroup()

cobertura_filas <- tibble(
  filas_totales = nrow(consumo_nutrientes),
  filas_con_composicion = sum(!is.na(consumo_nutrientes$energia_kcal)),
  pct_filas = 100 * filas_con_composicion / filas_totales,
  pct_gramos = 100 * sum(gramos_por_ema$Gramos_por_EMA_dia[
    !is.na(consumo_nutrientes$energia_kcal)], na.rm = TRUE) / total_g
)

message("\nIngesta aparente calculada para ", nrow(ingesta_hogar), " hogares.")
message("Cobertura (energia): ", round(cobertura_filas$pct_filas, 1), "% de filas, ",
        round(cobertura_filas$pct_gramos, 1), "% de gramos consumidos.")
print(cobertura)

# Paso 7: salidas ---------------------------------------------------------
write_delim(ingesta_hogar, here("data", "clean", "data_ingesta_micronutrientes_hogar.csv"), delim = ";")
write_delim(cobertura, here("data", "clean", "cobertura_composicion_nutrientes.csv"), delim = ";")

# Alimentos sin composicion, ordenados por gramos perdidos: es la lista de
# trabajo para ampliar el crosswalk por impacto real, no por orden alfabetico.
faltantes <- consumo_nutrientes |>
  filter(is.na(energia_kcal)) |>
  group_by(descripcion, enhance_id) |>
  summarise(gramos_perdidos = sum(Gramos_por_EMA_dia, na.rm = TRUE),
            filas = n(), .groups = "drop") |>
  arrange(desc(gramos_perdidos))

write_delim(faltantes, here("data", "eda", "alimentos_sin_composicion.csv"), delim = ";")

# Pendiente (no hecho aqui):
#   - Validar el supuesto "por 100 g" contra la documentacion de INCAP y FNDDS.
#   - 04_equivalente_adulto.R pierde la marca de seccion (Sec2/Sec3A) al hacer
#     bind_rows: agregar una columna `seccion` alli permitiria reportar
#     cobertura separada por seccion, que es como Daniel/Carlos la van a pedir.
#   - Comparar contra benchmark ENM 2009/2024 (siguiente script, no este).