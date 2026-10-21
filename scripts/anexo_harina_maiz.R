# anexo_harina_maiz.R
#
# Cobertura y consumo de harina de maíz, como vehículo adicional evaluado a
# petición de la revisión. No modifica la cadena principal ni los escenarios:
# no se modela fortificación de la harina de maíz porque el texto del RTD 334
# no se consultó y los niveles disponibles tienen unidades incoherentes
# (data/raw/parametros_normativos.csv).
#
# Alimentos incluidos: descripciones que empiezan por "harina(s) de maíz"
# (Sección 2, id 4; Sección 3A, id 56). Se excluye la harina de maíz dulce
# (id 2785). La fécula de maíz (Maicena) no es harina y no entra.
#
# Mismo criterio que 06: consumo no almacenado, gramos por EMA y día, diseño
# muestral complejo. Requiere haber corrido 04 y 05.
#
# Salida: data/clean/anexo_harina_maiz.csv

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

PATRON  <- "^harinas? de maiz"
EXCLUIR <- "dulce"

hogar <- leer("data", "clean", "data_ema_hogar.csv") |>
  select(id_hogar_unico, estrato, upm, factor_expansion, quintil, zona) |>
  mutate(quintil = as.character(quintil))

consumo <- leer("data", "clean", "data_gramos_por_ema.csv") |>
  filter(!almacenado) |>
  mutate(d = norm_txt(descripcion),
         maiz = grepl(PATRON, d) & !grepl(EXCLUIR, d))

message("Descripciones asignadas a harina de maíz:")
print(consumo |> filter(maiz) |> count(descripcion, name = "registros"))

por_hogar <- consumo |>
  filter(maiz) |>
  group_by(id_hogar_unico) |>
  summarise(g = sum(Gramos_por_EMA_dia), .groups = "drop") |>
  right_join(hogar, by = "id_hogar_unico") |>
  mutate(g = coalesce(g, 0), nacional = "Total")

diseno <- por_hogar |>
  as_survey_design(ids = upm, strata = estrato, weights = factor_expansion, nest = TRUE)

estimar <- function(por, dominio) {
  diseno |>
    group_by(nivel = .data[[por]]) |>
    summarise(pct_hogares = 100 * survey_mean(g > 0, vartype = "ci"),
              mediana_consumidores = survey_median(if_else(g > 0, g, NA_real_),
                                                   vartype = "ci", na.rm = TRUE),
              n = unweighted(n())) |>
    mutate(dominio = dominio, nivel = as.character(nivel), .before = 1)
}

resultado <- bind_rows(estimar("nacional", "Nacional"),
                       estimar("zona", "Zona"),
                       estimar("quintil", "Quintil"))

message("\nHarina de maíz: hogares que la adquieren (%) y mediana entre quienes la adquieren (g por EMA y día):")
print(as.data.frame(resultado), digits = 3)

write_delim(resultado, here("data", "clean", "anexo_harina_maiz.csv"), delim = ";")
