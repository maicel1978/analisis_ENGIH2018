# 08_grupos_alimentos.R
#
# Analisis por grupos de alimentos, sobre la estimacion principal.
#
# Clasificacion: los diez grupos de la diversidad alimentaria minima en mujeres
# (MDD-W, FAO 2021) mas las categorias que esa guia deja fuera (grasas, dulces,
# bebidas azucaradas, condimentos). La asignacion de cada alimento esta en
# data/raw/agrupacion_alimentos.csv y se edita ahi.
#
# Lo que este analisis no es: el indicador MDD-W. Ese indicador mide el consumo
# individual de mujeres en 24 horas; aqui se clasifican las adquisiciones del
# hogar durante una semana.
#
# Requiere haber corrido 04 y 05.

library(dplyr)
library(readr)
library(here)

leer <- function(...) {
  read_delim(here(...), delim = ";", show_col_types = FALSE,
             locale = locale(decimal_mark = "."), guess_max = 100000)
}

agrupacion <- leer("data", "raw", "agrupacion_alimentos.csv")

# Guardas: una clave por alimento y un solo grupo por alimento agrupado.
stopifnot(!anyDuplicated(agrupacion[c("seccion", "descripcion")]))
varios <- agrupacion |> distinct(alimento_agrupado, grupo_mddw) |> count(alimento_agrupado) |> filter(n > 1)
if (nrow(varios) > 0) {
  stop("Alimentos agrupados con mas de un grupo: ", paste(varios$alimento_agrupado, collapse = ", "), call. = FALSE)
}

# Nutrientes del analisis. La energia se usa para el aporte energetico; el
# resto, para el aporte a cada micronutriente.
NUTRIENTES <- c("hierro_mg", "folato_mcg_dfe", "zinc_mg", "vitamina_a_mcg_rae",
                "vitamina_b12_mcg", "vitamina_d_mcg", "vitamina_e_mg")

comp  <- leer("data", "clean", "composicion_unificada.csv") |>
  select(enhance_id, energia_kcal, all_of(NUTRIENTES))
hogar <- leer("data", "clean", "data_ema_hogar.csv") |> select(id_hogar_unico, peso = factor_expansion)

consumo <- leer("data", "clean", "data_gramos_por_ema.csv") |>
  filter(!almacenado) |>
  left_join(agrupacion |> select(seccion, descripcion, alimento_agrupado, grupo_mddw),
            by = c("seccion", "descripcion")) |>
  left_join(comp, by = "enhance_id") |>
  inner_join(hogar, by = "id_hogar_unico") |>
  mutate(energia = coalesce(Gramos_por_EMA_dia * energia_kcal / 100, 0))

sin_grupo <- consumo |> filter(is.na(grupo_mddw))
message("Registros sin grupo asignado: ", nrow(sin_grupo), " de ", nrow(consumo))
if (nrow(sin_grupo) > 0.01 * nrow(consumo)) {
  print(sin_grupo |> count(seccion, descripcion, sort = TRUE) |> head(10))
  stop("Mas del 1% de los registros no tiene grupo. Revisar agrupacion_alimentos.csv.", call. = FALSE)
}
consumo <- consumo |> filter(!is.na(grupo_mddw))

peso_total    <- sum(hogar$peso[hogar$id_hogar_unico %in% consumo$id_hogar_unico])
energia_total <- sum(consumo$peso * consumo$energia)

# Por grupo: hogares que lo adquieren y aporte a la energia (ponderados).
por_grupo <- consumo |>
  group_by(grupo_mddw) |>
  summarise(pct_hogares     = 100 * sum(peso[!duplicated(id_hogar_unico)]) / peso_total,
            pct_energia     = 100 * sum(peso * energia) / energia_total,
            .groups = "drop") |>
  arrange(desc(pct_energia))
message("\nGrupos de alimentos: hogares que los adquieren y aporte a la energia (%):")
print(as.data.frame(por_grupo), digits = 3)

# Alimentos agrupados que mas energia aportan.
por_alimento <- consumo |>
  group_by(alimento_agrupado, grupo_mddw) |>
  summarise(pct_hogares = 100 * sum(peso[!duplicated(id_hogar_unico)]) / peso_total,
            pct_energia = 100 * sum(peso * energia) / energia_total,
            .groups = "drop") |>
  arrange(desc(pct_energia))
message("\nLos quince alimentos que mas energia aportan:")
print(as.data.frame(head(por_alimento |> select(-grupo_mddw), 15)), digits = 3)

# Numero de grupos MDD-W distintos adquiridos por el hogar en la semana.
n_grupos <- consumo |>
  filter(grepl("^[0-9]{2} ", grupo_mddw)) |>
  distinct(id_hogar_unico, peso, grupo_mddw) |>
  count(id_hogar_unico, peso, name = "grupos")
message("\nGrupos MDD-W adquiridos por hogar en la semana (no es el indicador MDD-W): media ponderada ",
        round(weighted.mean(n_grupos$grupos, n_grupos$peso), 2))

write_delim(por_grupo,    here("data", "clean", "grupos_alimentos.csv"), delim = ";")
write_delim(por_alimento, here("data", "clean", "grupos_alimentos_detalle.csv"), delim = ";")

# --- Aporte de cada grupo a cada micronutriente -----------------------------
#
# Es el reparto del total nacional de cada nutriente entre los grupos, no la
# adecuacion. Un grupo puede aportar mucho de un nutriente y poco de otro: eso
# es lo que identifica que vehiculo sirve para que.
#
# Los gramos van sin ponderar dentro de la suma porque `peso` ya pondera el
# hogar; la cantidad consumida es por EMA y dia.

aporte <- consumo |>
  mutate(across(all_of(NUTRIENTES),
                ~ coalesce(Gramos_por_EMA_dia * .x / 100, 0) * peso))

por_grupo_nutriente <- aporte |>
  group_by(grupo_mddw) |>
  summarise(across(all_of(NUTRIENTES), sum), .groups = "drop") |>
  mutate(across(all_of(NUTRIENTES), ~ 100 * .x / sum(.x))) |>
  arrange(desc(folato_mcg_dfe))

# Guarda: cada nutriente debe repartir el 100% entre los grupos.
suma <- sapply(por_grupo_nutriente[NUTRIENTES], sum)
if (any(abs(suma - 100) > 0.01)) {
  print(round(suma, 3))
  stop("El reparto por grupo no suma 100% en algun nutriente.", call. = FALSE)
}

message("\nAporte de cada grupo de alimentos a cada micronutriente (%):")
print(as.data.frame(por_grupo_nutriente), digits = 3)

por_alimento_nutriente <- aporte |>
  group_by(alimento_agrupado, grupo_mddw) |>
  summarise(across(all_of(NUTRIENTES), sum), .groups = "drop") |>
  mutate(across(all_of(NUTRIENTES), ~ 100 * .x / sum(.x))) |>
  arrange(desc(folato_mcg_dfe))

message("\nLos diez alimentos que mas folato aportan:")
print(as.data.frame(head(por_alimento_nutriente |>
                           select(alimento_agrupado, folato_mcg_dfe, hierro_mg,
                                  zinc_mg, vitamina_a_mcg_rae), 10)), digits = 3)

write_delim(por_grupo_nutriente,
            here("data", "clean", "grupos_micronutrientes.csv"), delim = ";")
write_delim(por_alimento_nutriente,
            here("data", "clean", "grupos_micronutrientes_detalle.csv"), delim = ";")
