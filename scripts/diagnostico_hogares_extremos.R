# diagnostico_hogares_extremos.R
#
# Hogares con energia implausible por EMA y dia, sobre la estimacion principal
# (Sec 2 + Sec 3A con regla de agotamiento). No modifica el pipeline.
#
# Compara tres criterios para marcar hogares extremos y muestra cuanto cambia
# la distribucion con cada uno. Requiere haber corrido 04 y 05.

library(dplyr)
library(readr)
library(here)

leer <- function(archivo) {
  read_delim(here("data", "clean", archivo), delim = ";", show_col_types = FALSE,
             locale = locale(decimal_mark = "."), guess_max = 100000)
}

ingesta <- leer("data_ingesta_micronutrientes_hogar.csv") |>
  filter(variante == "Sec 2 + Sec 3A") |>
  select(id_hogar_unico, energia = energia_kcal)

hogar <- leer("data_ema_hogar.csv") |>
  select(id_hogar_unico, quintil, zona)

d <- ingesta |> left_join(hogar, by = "id_hogar_unico")

# Limites en escala logaritmica: la energia por EMA es asimetrica a la derecha.
log_e   <- log(d$energia[d$energia > 0])
centro  <- median(log_e)
mad_log <- mad(log_e)                 # desviacion absoluta mediana, escalada
q       <- quantile(log_e, c(.25, .75))
ric     <- q[2] - q[1]

criterios <- tribble(
  ~criterio,                        ~inferior,                 ~superior,
  "Fijo: 500 a 6.000 kcal",         500,                       6000,
  "Mediana +/- 3 MAD (log)",        exp(centro - 3 * mad_log), exp(centro + 3 * mad_log),
  "Cuartiles +/- 3 RIC (log)",      exp(q[1] - 3 * ric),       exp(q[2] + 3 * ric)
)

resumen <- criterios |>
  rowwise() |>
  mutate(
    hogares_bajo    = sum(d$energia < inferior),
    hogares_sobre   = sum(d$energia > superior),
    pct_excluido    = 100 * (hogares_bajo + hogares_sobre) / nrow(d),
    mediana_restante = median(d$energia[d$energia >= inferior & d$energia <= superior]),
    media_restante   = mean(d$energia[d$energia >= inferior & d$energia <= superior])
  ) |>
  ungroup()

message("Hogares: ", nrow(d), " | mediana: ", round(median(d$energia)),
        " | media: ", round(mean(d$energia)),
        " | con energia cero: ", sum(d$energia == 0))
message("\nCriterios comparados (limites en kcal por EMA y dia):")
print(as.data.frame(resumen), digits = 4)

# Si los extremos se concentran en un quintil o zona, excluirlos sesga la
# comparacion entre grupos. Se muestra con el criterio de 3 MAD.
lim <- criterios |> filter(criterio == "Mediana +/- 3 MAD (log)")
por_grupo <- d |>
  mutate(extremo = case_when(energia < lim$inferior ~ "bajo",
                             energia > lim$superior ~ "sobre",
                             TRUE ~ "dentro")) |>
  count(quintil, extremo) |>
  group_by(quintil) |>
  mutate(pct = round(100 * n / sum(n), 1)) |>
  ungroup()
message("\nDistribucion por quintil con el criterio de 3 MAD:")
print(as.data.frame(por_grupo))

dir.create(here("data", "diagnosticos"), showWarnings = FALSE, recursive = TRUE)
write_delim(resumen,   here("data", "diagnosticos", "hogares_extremos_criterios.csv"),   delim = ";")
write_delim(por_grupo, here("data", "diagnosticos", "hogares_extremos_por_quintil.csv"), delim = ";")
