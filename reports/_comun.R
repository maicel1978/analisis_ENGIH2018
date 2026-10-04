# ==============================================================================
# _comun.R -- definiciones compartidas por los informes R1 a R5.
#
# Rutas, carga de datos, parametros del analisis y funciones auxiliares.
# No calcula resultados.
# ==============================================================================

library(dplyr)
library(readr)
library(tidyr)
library(readxl)
library(here)
library(knitr)

options(scipen = 999)

# --- Parametros del analisis --------------------------------------------------

# Vehiculos de fortificacion. El patron se aplica sobre `descripcion`,
# normalizada sin acentos ni mayusculas.
VEHICULOS <- tribble(
  ~vehiculo,            ~patron,
  "Arroz",              "arroz",
  "Harina de trigo",    "harina de trigo|harina integral",
  "Aceite",             "aceite",
  "Azúcar",             "azucar|az\u00facar",
  "Harina de maíz",     "^harinas? de maiz",
  "Avena",              "^avena",
  "Sal",                "^sal (molida|en grano|marina)"
)

# Definicion ampliada del vehiculo trigo: harina y derivados de consumo directo.
# La fortificacion se aplica en el molino, de modo que la harina llega al hogar
# mayoritariamente procesada.
#
# Las exclusiones evitan falsos positivos: "Pasta de tomate" (12.150 registros),
# "Ajo en pasta", derivados de maiz y "Buen pan o castana" (fruta de pan).
# Sin ellas la cifra se infla un 47%.
TRIGO_INCLUIR <- paste0(
  "\\bpan\\b|panecillo|galleta|fideo|macarron|espagueti|espaguetti|lasagn|",
  "harina de trigo|harina integral|bizcocho|croissant|hojaldre|\\bpasta\\b|",
  "tortilla|dona|sobado"
)
TRIGO_EXCLUIR <- paste0(
  "pasta de tomate|ajo en pasta|pasta de ajo|harina de maiz|harinas de maiz|",
  "maicena|de maiz|castana|fruta de pan|pan de fruta|masapan|negrito|arroz"
)

# Nutrientes incluidos en esta etapa del analisis.
NUTRIENTES_INICIALES <- c("Energia", "Hierro", "Acido folico", "Vitamina A")

# Escenarios de fortificacion. Codigos ENHANCE_ID de INCAP.
#
# El marco normativo vigente esta pendiente de confirmacion, de modo que los
# resultados se presentan como rango entre los tres escenarios.
#
# El aceite no se modela: los 19 aceites de INCAP tienen VITA_RAE = 0 y no
# existe par fortificado / sin fortificar.
ESCENARIOS <- tribble(
  ~escenario,               ~vehiculo,         ~enhance_id,
  # Escenario 0 -- sin fortificación (línea base biológica)
  "0. Sin fortificar",      "Arroz",            70213004,  # blanco grano mediano crudo, s/enriquecer
  "0. Sin fortificar",      "Harina de trigo",  70213038,  # todo uso, s/enriquecer
  # Escenario 1 -- solo harina de trigo
  "1. Solo harina",         "Arroz",            70213004,
  "1. Solo harina",         "Harina de trigo",  70213039,  # enriquecida, todo uso
  # Escenario 2 -- harina y arroz
  "2. Harina y arroz",      "Arroz",            70213002,  # blanco grano mediano crudo, enriquecido
  "2. Harina y arroz",      "Harina de trigo",  70213039
)

# --- Rutas --------------------------------------------------------------------
RUTA_CLEAN <- here("data", "clean")
RUTA_RAW   <- here("data", "raw")

# --- Carga --------------------------------------------------------------------
# data/clean no esta versionado: se regenera con el pipeline.
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

# read_csv2() asume coma decimal y corrompe las columnas numericas.
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

# Consumo por EMA, salida de 04_equivalente_adulto.R.
# Por defecto excluye las adquisiciones marcadas como almacenadas por la regla
# de agotamiento; `incluir_almacenado = TRUE` devuelve la suma simple.
cargar_gramos_por_ema <- function(incluir_almacenado = FALSE) {
  f <- file.path(RUTA_CLEAN, "data_gramos_por_ema.csv")
  exigir_archivo(f, "04_equivalente_adulto.R")
  d <- leer_limpio(f)
  faltan <- setdiff(c("seccion", "almacenado"), names(d))
  if (length(faltan) > 0) {
    stop("`data_gramos_por_ema.csv` no tiene: ", paste(faltan, collapse = ", "),
         ". Volver a correr scripts/04_equivalente_adulto.R.", call. = FALSE)
  }
  if (!incluir_almacenado) d <- d |> filter(!almacenado)
  d
}

# Peso muestral por hogar. Se toma el primer registro: el factor es propiedad
# del hogar, y sumarlo por filas lo multiplicaria por el numero de alimentos.
pesos_hogar <- function() {
  d <- cargar_consumo()
  bind_rows(
    d$sec2  |> select(id_hogar_unico, peso),
    d$sec3a |> select(id_hogar_unico, peso)
  ) |>
    filter(!is.na(peso)) |>
    group_by(id_hogar_unico) |>
    summarise(peso = first(peso), .groups = "drop")
}

# Composicion unificada INCAP + FNDDS, generada por 05_ingesta_micronutrientes.R.
# Tipos declarados: una columna con muchos vacios al inicio no debe leerse
# como logica.
cargar_composicion <- function() {
  f <- file.path(RUTA_CLEAN, "composicion_unificada.csv")
  exigir_archivo(f, "05_ingesta_micronutrientes.R")
  read_delim(f, delim = ";", col_types = cols(.default = col_double()),
             locale = locale(decimal_mark = "."), na = c("", "NA"))
}

# --- Diseno muestral ----------------------------------------------------------
# Muestra estratificada por conglomerados: 8 estratos, 933 UPM, factor de
# expansion por hogar. Ignorar la estructura subestima los errores estandar.
#
# Requiere estrato, upm y factor_expansion en data_ema_hogar.csv.

cargar_ema_hogar <- function() {
  f <- file.path(RUTA_CLEAN, "data_ema_hogar.csv")
  exigir_archivo(f, "04_equivalente_adulto.R")
  d <- leer_limpio(f)
  faltan <- setdiff(c("estrato", "upm", "factor_expansion"), names(d))
  if (length(faltan) > 0) {
    stop("`data_ema_hogar.csv` no tiene: ", paste(faltan, collapse = ", "),
         ". Volver a correr scripts/04_equivalente_adulto.R.", call. = FALSE)
  }
  d
}

# `datos` debe estar a nivel de hogar y traer id_hogar_unico. Las variables de
# diseno se unen desde data_ema_hogar.csv.
diseno_muestral <- function(datos) {
  if (!requireNamespace("srvyr", quietly = TRUE)) {
    stop("Falta el paquete `srvyr`. Instalar con install.packages(\"srvyr\").",
         call. = FALSE)
  }

  dis <- cargar_ema_hogar() |>
    select(id_hogar_unico, estrato, upm, factor_expansion,
           quintil, zona, grupo_region, id_provincia, des_provincia)

  d <- datos |>
    inner_join(dis, by = "id_hogar_unico", suffix = c("", "_dis"))

  perdidos <- nrow(datos) - nrow(d)
  if (perdidos > 0) {
    warning(perdidos, " filas sin correspondencia en el marco muestral; ",
            "quedan fuera de la estimacion.", call. = FALSE)
  }

  srvyr::as_survey_design(d, ids = upm, strata = estrato,
                          weights = factor_expansion, nest = TRUE)
}

# Media con intervalo por linealizacion de Taylor y mediana ponderada.
# `por`: quintil, zona o grupo_region.
estimar <- function(diseno, variable, por = NULL, nivel = 0.95) {
  v <- rlang::ensym(variable)
  d <- if (is.null(por)) diseno else dplyr::group_by(diseno, dplyr::across(all_of(por)))

  media <- d |>
    srvyr::summarise(
      n        = srvyr::unweighted(dplyr::n()),
      media    = srvyr::survey_mean(!!v, vartype = "ci", level = nivel,
                                    na.rm = TRUE)
    )

  mediana <- d |>
    srvyr::summarise(
      mediana = srvyr::survey_median(!!v, vartype = NULL, na.rm = TRUE)
    )

  if (is.null(por)) dplyr::bind_cols(media, mediana)
  else dplyr::left_join(media, mediana, by = por)
}

# Proporcion ponderada con intervalo, para indicadores de cobertura.
# `condicion` debe ser una columna logica ya calculada en `datos`.
estimar_proporcion <- function(diseno, condicion, por = NULL, nivel = 0.95) {
  v <- rlang::ensym(condicion)
  d <- if (is.null(por)) diseno else dplyr::group_by(diseno, dplyr::across(all_of(por)))

  d |>
    srvyr::summarise(
      n = srvyr::unweighted(dplyr::n()),
      p = srvyr::survey_mean(!!v, vartype = "ci", level = nivel, na.rm = TRUE)
    ) |>
    dplyr::mutate(dplyr::across(dplyr::starts_with("p"), ~ .x * 100))
}

# --- Tablas -------------------------------------------------------------------
FUENTE_ENGIH <- paste(
  "Fuente: Encuesta Nacional de Gastos e Ingresos de los Hogares 2018,",
  "Banco Central de la República Dominicana."
)
NOTA_DISENO <- paste(
  "Estimaciones ponderadas con el diseño muestral complejo de la encuesta",
  "(8 estratos, 933 unidades primarias de muestreo, factor de expansión por",
  "hogar); intervalos de confianza por linealización de Taylor."
)
NOTA_EMA <- "EMA: Equivalente de Mujer Adulta. IC: intervalo de confianza."

# Devuelve gt en HTML y flextable en Word, con la nota al pie dentro del objeto.
#
#   datos    data frame ya formateado (columnas con su unidad en el nombre)
#   fuente   linea de procedencia; por defecto la ENGIH
#   notas    vector de notas adicionales (método, definiciones, abreviaturas)
#   ancho    ancho de la tabla en la salida HTML
tabla <- function(datos, fuente = FUENTE_ENGIH, notas = NULL, ancho = "100%") {

  es_word <- knitr::pandoc_to("docx")

  if (es_word && requireNamespace("flextable", quietly = TRUE)) {
    ft <- flextable::flextable(as.data.frame(datos))
    ft <- flextable::theme_booktabs(ft)
    ft <- flextable::autofit(ft)
    pie <- c(fuente, notas)
    for (p in rev(pie)) {
      ft <- flextable::add_footer_lines(ft, values = p)
    }
    ft <- flextable::fontsize(ft, size = 8, part = "footer")
    ft <- flextable::italic(ft, part = "footer")
    return(ft)
  }

  if (!requireNamespace("gt", quietly = TRUE)) return(knitr::kable(datos))

  g <- gt::gt(datos) |>
    gt::tab_options(
      table.width               = ancho,
      table.font.size           = gt::pct(88),
      heading.align             = "left",
      column_labels.font.weight = "bold",
      column_labels.background.color = "#f5f8fa",
      table.border.top.style    = "none",
      table_body.hlines.color   = "#eef2f4",
      data_row.padding          = gt::px(5),
      source_notes.font.size    = gt::pct(72),
      footnotes.font.size       = gt::pct(72)
    ) |>
    gt::opt_table_font(font = gt::google_font("Source Sans Pro"))

  for (p in c(fuente, notas)) {
    g <- gt::tab_source_note(g, source_note = p)
  }
  g
}

# --- Helpers ------------------------------------------------------------------

# Normaliza texto para emparejar descripciones sin depender de acentos/mayúsculas
norm_txt <- function(x) {
  x |> as.character() |> tolower() |>
    iconv(to = "ASCII//TRANSLIT") |>
    trimws()
}

# Asigna vehiculo a cada fila, NA si no corresponde a ninguno.
# ampliado = TRUE sustituye "Harina de trigo" por "Trigo y derivados".
marcar_vehiculo <- function(df, col = "descripcion", ampliado = FALSE) {
  d <- norm_txt(df[[col]])
  v <- rep(NA_character_, length(d))
  
  if (ampliado) {
    hit <- grepl(TRIGO_INCLUIR, d) & !grepl(TRIGO_EXCLUIR, d)
    v[hit] <- "Trigo y derivados"
  }
  
  for (i in seq_len(nrow(VEHICULOS))) {
    if (ampliado && VEHICULOS$vehiculo[i] == "Harina de trigo") next
    hit <- grepl(VEHICULOS$patron[i], d) & is.na(v)
    v[hit] <- VEHICULOS$vehiculo[i]
  }
  df$vehiculo <- v
  df
}

# Una fila entra al calculo si tiene Q, FC y PC, y no es atipica.
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

# Formato numerico espanol. `kable(format.args = ...)` no alcanza a los valores
# construidos con paste0, como los intervalos de confianza.
fmt <- function(x, dec = 1) {
  formatC(round(x, dec), format = "f", digits = dec,
          big.mark = ".", decimal.mark = ",")
}

# Intervalo formateado, con guion largo como separador.
ic <- function(lo, hi, dec = 1) paste0(fmt(lo, dec), " – ", fmt(hi, dec))

# Porcentaje formateado. Vectorizado: se usa dentro de mutate() sobre columnas.
pct <- function(x, n, dec = 1) {
  # OJO: no usar ifelse() con la condicion sobre `n`. ifelse() devuelve un
  # resultado del largo de la CONDICION, asi que si `n` es un escalar (un total
  # de hogares, por ejemplo) el resultado se colapsa a un solo valor y todas las
  # filas muestran el mismo porcentaje. Bug real, detectado en R3 el 2026-09-12.
  v <- 100 * x / n
  v[!is.finite(v)] <- NA_real_
  out <- paste0(round(v, dec), "%")
  out[is.na(v)] <- "--"
  out
}

# Toda cifra de cobertura se reporta como "valor (n/N, %)" -- regla del
# proyecto: ninguna cifra agregada se cita sin su cobertura.
con_cobertura <- function(x, n) {
  paste0(format(x, big.mark = ",", trim = TRUE), " (", pct(x, n), ")")
}
