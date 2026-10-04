# diagnostico_solapamiento.R
#
# Solapamiento entre la Seccion 2 (existencias) y la Seccion 3A (adquisiciones)
# en alimentos almacenables. No modifica el pipeline: lee data/clean y escribe
# en data/diagnosticos.
#
# 1. Comprueba que la pregunta 9 de la Seccion 2 equivale a existencia inicial
#    menos existencia final. Si es asi, la "disponibilidad neta"
#    (inicial + adquisiciones - final) es la suma que el pipeline ya calcula.
#
# 2. Evalua una regla alternativa, de agotamiento: si al dia 8 el hogar
#    conserva existencia inicial de un alimento, las adquisiciones de ese
#    alimento durante la semana se consideran almacenadas y no consumidas.
#
# Requiere haber corrido 01, 03, 04 y 05.

library(dplyr)
library(readr)
library(here)

leer <- function(archivo) {
  read_delim(here("data", "clean", archivo), delim = ";", show_col_types = FALSE,
             locale = locale(decimal_mark = "."), guess_max = 100000)
}
norm_txt <- function(x) trimws(iconv(tolower(as.character(x)), to = "ASCII//TRANSLIT"))

# Alimentos almacenables presentes en ambas secciones. Los perecederos (pollo,
# carnes, pescado, pan, platano, papa) se excluyen: comprar mas con existencia
# en el congelador no implica que lo comprado no se consuma.
CLAVES <- tribble(
  ~clave,                  ~patron_sec2,              ~patron_sec3a,
  "Arroz",                 "^arroz",                  "^arroz",
  "Aceite",                "^aceite",                 "^aceite",
  "Azúcar",                "^azucar",                 "^azucar (morena|blanca)",
  "Habichuelas secas",     "^habichuelas sueltas",    "^habichuelas .*secas",
  "Habichuelas enlatadas", "^habichuelas enlatadas",  "^habichuelas? .*(enlatadas|en lata)",
  "Leche líquida",         "^leche liquida",          "^leche .*liquida|^leche fresca",
  "Leche en polvo",        "^leche en polvo",         "^leche en polvo",
  "Harina de maíz",        "^harina de maiz",         "^harinas? de maiz",
  "Avena",                 "^avena",                  "^avena",
  "Pastas",                "spaguetti",               "^spaghetti|^fideos|^coditos|^macarrones|^espirales",
  "Galletas saladas",      "^galletas saladas",       "^galletas (saladas|de soda)",
  "Galletas dulces",       "^galletas dulces",        "^galletas dulces",
  "Salami",                "^salami",                 "^salami",
  "Chocolate",             "^chocolate",              "^chocolate en|^cocoa",
  "Sardinas",              "^sardinas",               "^sardinas en",
  "Atún",                  "^atun",                   "^atun en"
)

asignar_clave <- function(descripcion, patrones) {
  d <- norm_txt(descripcion)
  clave <- rep(NA_character_, length(d))
  for (i in seq_len(nrow(CLAVES))) {
    clave[is.na(clave) & grepl(patrones[i], d)] <- CLAVES$clave[i]
  }
  clave
}

sec2   <- leer("data_sec2.csv")
gramos <- leer("data_gramos_por_ema.csv")
comp   <- leer("composicion_unificada.csv") |> select(enhance_id, energia_kcal)

# 1. Pregunta 9 frente a inicial - final ------------------------------------
p9 <- sec2 |>
  mutate(diferencia = cantidad_inicial - cantidad_final) |>
  summarise(
    filas                 = n(),
    pct_q_igual_dif       = 100 * mean(abs(Q - diferencia) < 1e-6),
    pct_q_menor_dif       = 100 * mean(Q < diferencia - 1e-6),
    filas_final_mayor_ini = sum(cantidad_final > cantidad_inicial)
  )
message("Pregunta 9 frente a existencia inicial - final:")
print(p9)

# 2. Regla de agotamiento ---------------------------------------------------
resto <- sec2 |>
  mutate(clave = asignar_clave(descripcion, CLAVES$patron_sec2)) |>
  filter(!is.na(clave)) |>
  group_by(id_hogar_unico, clave) |>
  summarise(existencia_final = sum(cantidad_final), .groups = "drop") |>
  filter(existencia_final > 0)

gramos <- gramos |>
  left_join(comp, by = "enhance_id") |>
  mutate(
    energia = coalesce(Gramos_por_EMA_dia * energia_kcal / 100, 0),
    clave   = if_else(seccion == "Sec 3A",
                      asignar_clave(descripcion, CLAVES$patron_sec3a), NA_character_)
  ) |>
  left_join(resto |> mutate(almacenado = TRUE), by = c("id_hogar_unico", "clave")) |>
  mutate(almacenado = coalesce(almacenado, FALSE))

resumir <- function(df, variante) {
  df |>
    group_by(id_hogar_unico) |>
    summarise(energia = sum(energia), .groups = "drop") |>
    summarise(variante        = variante,
              hogares         = n(),
              energia_mediana = median(energia),
              energia_media   = mean(energia),
              sobre_6000_kcal = sum(energia > 6000),
              bajo_500_kcal   = sum(energia < 500))
}

comparacion <- bind_rows(
  resumir(gramos, "Sec 2 + Sec 3A"),
  resumir(gramos |> filter(!almacenado), "Con regla de agotamiento")
)
message("\nEnergia por EMA y dia (sin ponderar), con y sin la regla:")
print(comparacion)

por_alimento <- gramos |>
  filter(!is.na(clave)) |>
  group_by(clave) |>
  summarise(hogares_con_compra    = n_distinct(id_hogar_unico),
            hogares_excluidos     = n_distinct(id_hogar_unico[almacenado]),
            pct_gramos_excluidos  = 100 * sum(Gramos_por_EMA_dia[almacenado]) / sum(Gramos_por_EMA_dia),
            .groups = "drop") |>
  arrange(desc(hogares_excluidos))
message("\nAdquisiciones excluidas por alimento:")
print(por_alimento, n = Inf)

dir.create(here("data", "diagnosticos"), showWarnings = FALSE, recursive = TRUE)
write_delim(comparacion,  here("data", "diagnosticos", "solapamiento_variantes.csv"),    delim = ";")
write_delim(por_alimento, here("data", "diagnosticos", "solapamiento_por_alimento.csv"), delim = ";")
