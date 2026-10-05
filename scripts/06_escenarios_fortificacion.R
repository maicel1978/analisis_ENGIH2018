# 06_escenarios_fortificacion.R
#
# Escenarios de fortificacion sobre la estimacion principal.
#
# Metodo aditivo: se parte del alimento sin fortificar y se suma el nutriente
# que anade cada escenario, en mg por kg de vehiculo.
#
#   - Arroz y harina de trigo: composicion de la version sin enriquecer.
#   - Derivados de trigo (pan, pastas, galletas, reposteria): la tabla de
#     composicion los trae elaborados con harina enriquecida. Su hierro y su
#     folato se sustituyen por los de la harina sin enriquecer, en proporcion a
#     la harina que contienen. Los demas nutrientes no se tocan.
#   - Lo anadido a un derivado es el nivel del escenario por su fraccion de
#     harina.
#
# Parametros, todos en data/raw:
#   vehiculos_escenarios.csv      vehiculo, patron de descripcion, fraccion de harina
#   escenarios_fortificacion.csv  escenario, vehiculo, nutriente, nivel (mg/kg)
#
# No se descuentan perdidas por almacenamiento ni coccion: los aportes son un
# maximo. Requiere haber corrido 04 y 05.

library(dplyr)
library(tidyr)
library(readr)
library(srvyr)
library(here)

leer <- function(...) {
  read_delim(here(...), delim = ";", show_col_types = FALSE,
             locale = locale(decimal_mark = "."), guess_max = 100000)
}
norm_txt <- function(x) trimws(iconv(tolower(as.character(x)), to = "ASCII//TRANSLIT"))

ID_ARROZ_SIN_ENRIQUECER  <- 70213004
ID_HARINA_SIN_ENRIQUECER <- 70213038
DERIVADOS_TRIGO <- c("Pan", "Pastas", "Galletas saladas", "Galletas dulces", "Reposter\u00eda")
NUTRIENTES <- c("hierro_mg", "folato_mcg_dfe", "zinc_mg", "vitamina_b12_mcg", "vitamina_a_mcg_rae")

# De mg/kg de vehiculo a unidades del nutriente por 100 g de vehiculo.
# Acido folico: 1 ug equivale a 1,7 ug DFE. Vitamina A: mg de retinol.
A_UNIDAD_POR_100G <- c(hierro_mg = 0.1, zinc_mg = 0.1, folato_mcg_dfe = 100 * 1.7,
                       vitamina_b12_mcg = 100, vitamina_a_mcg_rae = 100)
UL_ACIDO_FOLICO_UG <- 1000

vehiculos  <- leer("data", "raw", "vehiculos_escenarios.csv")
escenarios <- leer("data", "raw", "escenarios_fortificacion.csv")
comp       <- leer("data", "clean", "composicion_unificada.csv") |>
  select(enhance_id, energia_kcal, all_of(NUTRIENTES))
hogar      <- leer("data", "clean", "data_ema_hogar.csv") |>
  select(id_hogar_unico, estrato, upm, factor_expansion, quintil)

faltan <- setdiff(unique(escenarios$vehiculo), vehiculos$vehiculo)
if (length(faltan) > 0) stop("Vehiculos sin definir: ", paste(faltan, collapse = ", "), call. = FALSE)
faltan <- setdiff(unique(escenarios$nutriente), NUTRIENTES)
if (length(faltan) > 0) stop("Nutrientes no previstos: ", paste(faltan, collapse = ", "), call. = FALSE)

asignar_vehiculo <- function(descripcion) {
  d <- norm_txt(descripcion)
  v <- rep(NA_character_, length(d))
  for (i in seq_len(nrow(vehiculos))) {
    hit <- grepl(vehiculos$patron[i], d) & is.na(v)
    if (!is.na(vehiculos$excluir[i])) hit <- hit & !grepl(vehiculos$excluir[i], d)
    v[hit] <- vehiculos$vehiculo[i]
  }
  v
}

base_arroz  <- comp |> filter(enhance_id == ID_ARROZ_SIN_ENRIQUECER)
base_harina <- comp |> filter(enhance_id == ID_HARINA_SIN_ENRIQUECER)
stopifnot(nrow(base_arroz) == 1, nrow(base_harina) == 1)

# Consumo con composicion de linea base sin fortificar ----------------------
consumo <- leer("data", "clean", "data_gramos_por_ema.csv") |>
  filter(!almacenado) |>
  mutate(vehiculo = asignar_vehiculo(descripcion)) |>
  left_join(vehiculos |> select(vehiculo, fraccion_harina), by = "vehiculo") |>
  left_join(comp, by = "enhance_id") |>
  mutate(
    hierro_mg = case_when(
      vehiculo == "Arroz"           ~ base_arroz$hierro_mg,
      vehiculo == "Harina de trigo" ~ base_harina$hierro_mg,
      vehiculo %in% DERIVADOS_TRIGO ~ fraccion_harina * base_harina$hierro_mg,
      TRUE ~ hierro_mg),
    folato_mcg_dfe = case_when(
      vehiculo == "Arroz"           ~ base_arroz$folato_mcg_dfe,
      vehiculo == "Harina de trigo" ~ base_harina$folato_mcg_dfe,
      vehiculo %in% DERIVADOS_TRIGO ~ fraccion_harina * base_harina$folato_mcg_dfe,
      TRUE ~ folato_mcg_dfe),
    gramos_vehiculo = Gramos_por_EMA_dia * coalesce(fraccion_harina, 1)
  )

# Consumo de cada vehiculo, en gramos de vehiculo por EMA y dia --------------
consumo_vehiculo <- consumo |>
  mutate(grupo = case_when(vehiculo %in% c("Harina de trigo", DERIVADOS_TRIGO) ~ "Trigo, en equivalentes de harina",
                           !is.na(vehiculo) ~ vehiculo)) |>
  filter(!is.na(grupo)) |>
  group_by(id_hogar_unico, grupo) |>
  summarise(g = sum(gramos_vehiculo), .groups = "drop") |>
  complete(id_hogar_unico = hogar$id_hogar_unico, grupo, fill = list(g = 0)) |>
  inner_join(hogar, by = "id_hogar_unico") |>
  as_survey_design(ids = upm, strata = estrato, weights = factor_expansion, nest = TRUE) |>
  group_by(grupo) |>
  summarise(pct_hogares = 100 * survey_mean(g > 0, vartype = NULL),
            media_todos = survey_mean(g, vartype = NULL),
            mediana_consumidores = survey_median(if_else(g > 0, g, NA_real_),
                                                 vartype = NULL, na.rm = TRUE))
message("Consumo de vehiculos (g por EMA y dia, ponderado):")
print(as.data.frame(consumo_vehiculo), digits = 3)

# Ingesta por hogar y escenario ----------------------------------------------
base_hogar <- consumo |>
  group_by(id_hogar_unico) |>
  summarise(across(all_of(NUTRIENTES), ~ sum(Gramos_por_EMA_dia * .x / 100, na.rm = TRUE)),
            .groups = "drop")

anadido <- escenarios |>
  mutate(por_100g = nivel_mg_kg * A_UNIDAD_POR_100G[nutriente]) |>
  select(escenario, vehiculo, nutriente, por_100g) |>
  inner_join(consumo |> filter(!is.na(vehiculo)) |>
               select(id_hogar_unico, vehiculo, gramos_vehiculo),
             by = "vehiculo", relationship = "many-to-many") |>
  group_by(escenario, id_hogar_unico, nutriente) |>
  summarise(anadido = sum(gramos_vehiculo * por_100g / 100), .groups = "drop")

nombres <- c("0. Sin fortificaci\u00f3n", sort(unique(escenarios$escenario)))

ingesta <- expand_grid(escenario = nombres, id_hogar_unico = base_hogar$id_hogar_unico) |>
  left_join(base_hogar |> pivot_longer(all_of(NUTRIENTES), names_to = "nutriente", values_to = "base"),
            by = "id_hogar_unico", relationship = "many-to-many") |>
  left_join(anadido, by = c("escenario", "id_hogar_unico", "nutriente")) |>
  mutate(anadido = coalesce(anadido, 0), ingesta = base + anadido) |>
  inner_join(hogar, by = "id_hogar_unico")

d <- ingesta |>
  as_survey_design(ids = upm, strata = estrato, weights = factor_expansion, nest = TRUE)

resumen <- d |>
  group_by(escenario, nutriente) |>
  summarise(mediana = survey_median(ingesta, vartype = NULL),
            media   = survey_mean(ingesta, vartype = "ci"),
            .groups = "drop")

# Acido folico sintetico sobre el limite superior (el limite no aplica al
# folato natural). El anadido esta en ug DFE; se divide por 1,7.
sobre_ul <- d |>
  filter(nutriente == "folato_mcg_dfe") |>
  group_by(escenario) |>
  summarise(pct_folico_sobre_ul = 100 * survey_mean(anadido / 1.7 > UL_ACIDO_FOLICO_UG, vartype = NULL))

# Gradiente social del folato: razon de medianas entre quintiles 5 y 1.
gradiente <- d |>
  filter(nutriente == "folato_mcg_dfe", quintil %in% c(1, 5)) |>
  group_by(escenario, quintil) |>
  summarise(mediana = survey_median(ingesta, vartype = NULL), .groups = "drop") |>
  pivot_wider(names_from = quintil, values_from = mediana, names_prefix = "q") |>
  transmute(escenario, folato_q1 = q1, folato_q5 = q5, razon_q5_q1 = q5 / q1)

message("\nIngesta mediana por EMA y dia, segun escenario (ponderada):")
print(as.data.frame(
  resumen |> select(escenario, nutriente, mediana) |>
    pivot_wider(names_from = nutriente, values_from = mediana)
), digits = 3)
message("\nFolato: acido folico anadido sobre el limite superior y gradiente por quintil:")
print(as.data.frame(left_join(sobre_ul, gradiente, by = "escenario")), digits = 3)

write_delim(resumen |> left_join(sobre_ul, by = "escenario") |> left_join(gradiente, by = "escenario"),
            here("data", "clean", "escenarios_resumen.csv"), delim = ";")
write_delim(ingesta |> select(escenario, id_hogar_unico, nutriente, base, anadido, ingesta),
            here("data", "clean", "escenarios_ingesta_hogar.csv"), delim = ";")
write_delim(consumo_vehiculo, here("data", "clean", "escenarios_consumo_vehiculos.csv"), delim = ";")
