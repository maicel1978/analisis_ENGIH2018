# ==============================================================================
# _comun.R  --  Base compartida por TODOS los reportes (R1..R5)
#
# Por qué existe: si cada .qmd carga y define lo suyo, al mejorar un dato hay
# que tocar cinco archivos y se desincronizan. Acá se cambia una vez.
#
# No calcula resultados. Solo: rutas, carga, definiciones editables y helpers.
# ==============================================================================

library(dplyr)
library(readr)
library(tidyr)
library(readxl)
library(here)
library(knitr)

options(scipen = 999)

# --- Parámetros editables -----------------------------------------------------
# Esto es lo que se toca cuando cambia una definición. Nada más.

# Vehículos de fortificación (actuales y potenciales en RD).
# El patrón se aplica sobre `descripcion` de la ENGIH, sin distinguir
# mayúsculas ni acentos. Editar acá si se decide incluir/excluir algo:
# el cambio se propaga a todos los reportes.
VEHICULOS <- tribble(
  ~vehiculo,            ~patron,
  "Arroz",              "arroz",
  "Harina de trigo",    "harina de trigo|harina integral",
  "Aceite",             "aceite",
  "Azucar",             "azucar|az\u00facar"
)

# Nutrientes iniciales del análisis (hoja de ruta: empezar con 4, no con 65)
NUTRIENTES_INICIALES <- c("Energia", "Hierro", "Acido folico", "Vitamina A")

# --- Rutas --------------------------------------------------------------------
RUTA_CLEAN <- here("data", "clean")
RUTA_RAW   <- here("data", "raw")

# --- Carga --------------------------------------------------------------------
# Los CSV de data/clean NO están en git (son regenerables). Si faltan, hay que
# correr el pipeline. Fallar acá con mensaje claro es mejor que un reporte
# a medias.
exigir_archivo <- function(ruta, script_que_lo_genera) {
  if (!file.exists(ruta)) {
    stop(
      "Falta: ", basename(ruta), "\n",
      "Generalo corriendo scripts/", script_que_lo_genera,
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# delim=";" explícito y decimal "." : read_csv2() asume coma decimal y corrompe
# las columnas numéricas (bug real, 2026-09-08).
leer_limpio <- function(ruta) {
  read_delim(ruta, delim = ";", show_col_types = FALSE,
             locale = locale(decimal_mark = "."),
             na = c("", "NA", "N/A"))
}

cargar_consumo <- function() {
  f2  <- file.path(RUTA_CLEAN, "data_sec2_consumo.csv")
  f3a <- file.path(RUTA_CLEAN, "data_sec3a_consumo.csv")
  exigir_archivo(f2,  "03_transform.R")
  exigir_archivo(f3a, "03_transform.R")
  
  sec2 <- leer_limpio(f2) |>
    mutate(seccion = "Sec 2", peso = factor_anual)
  sec3a <- leer_limpio(f3a) |>
    mutate(seccion = "Sec 3A", peso = factor_expansion)
  
  list(sec2 = sec2, sec3a = sec3a)
}

cargar_crosswalk <- function(hoja) {
  f <- file.path(RUTA_RAW, "crosswalk_tablas_composicion.xlsx")
  exigir_archivo(f, "99_aplicar_correcciones_crosswalk.R (o el archivo original)")
  read_excel(f, sheet = hoja, col_types = "text")
}

# --- Helpers ------------------------------------------------------------------

# Normaliza texto para emparejar descripciones sin depender de acentos/mayúsculas
norm_txt <- function(x) {
  x |> as.character() |> tolower() |>
    iconv(to = "ASCII//TRANSLIT") |>
    trimws()
}

# Marca a qué vehículo pertenece cada fila (NA si a ninguno)
marcar_vehiculo <- function(df, col = "descripcion") {
  d <- norm_txt(df[[col]])
  v <- rep(NA_character_, length(d))
  for (i in seq_len(nrow(VEHICULOS))) {
    hit <- grepl(VEHICULOS$patron[i], d) & is.na(v)
    v[hit] <- VEHICULOS$vehiculo[i]
  }
  df$vehiculo <- v
  df
}

# Una fila "entra al cálculo" solo si tiene las tres piezas de la fórmula
# Q x FC x PC / PM y no fue marcada como atípica.
marcar_elegible <- function(df) {
  df |>
    mutate(
      tiene_Q       = !is.na(Q),
      tiene_fc      = !is.na(fc),
      tiene_enhance = !is.na(enhance_id),
      tiene_pc      = !is.na(edible),
      es_outlier    = if ("es_outlier" %in% names(df)) coalesce(es_outlier, FALSE) else FALSE,
      entra_calculo = tiene_Q & tiene_fc & tiene_enhance & tiene_pc & !es_outlier
    )
}

# Porcentaje formateado, para no repetir round() en cada reporte.
# VECTORIZADO a proposito: se usa dentro de mutate() sobre columnas enteras,
# donde un if() ordinario falla ("the condition has length > 1").
pct <- function(x, n, dec = 1) {
  v <- ifelse(is.na(n) | n == 0, NA_real_, 100 * x / n)
  ifelse(is.na(v), "--", paste0(round(v, dec), "%"))
}

# Toda cifra de cobertura se reporta como "valor (n/N, %)" -- regla del
# proyecto: ninguna cifra agregada se cita sin su cobertura.
con_cobertura <- function(x, n) {
  paste0(format(x, big.mark = ",", trim = TRUE), " (", pct(x, n), ")")
}