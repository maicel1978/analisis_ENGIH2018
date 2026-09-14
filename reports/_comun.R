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
  "Azúcar",             "azucar|az\u00facar"
)

# Definición AMPLIADA del vehículo trigo: harina + derivados de consumo directo.
#
# Por qué: la norma dominicana obliga a fortificar la harina EN EL MOLINO. Esa
# harina llega al hogar dentro del pan, no como harina. Medir la cobertura solo
# por "harina de trigo" mide el consumo de un insumo intermedio (8% de los
# hogares), no la exposición de la población al nutriente añadido. Es un
# problema de definición de indicador, no una cuestión nutricional.
#
# CUIDADO con el patrón: sin exclusiones captura falsos positivos graves --
# "Pasta de tomate" (12,150 registros), "Ajo en pasta", "Harinas de maíz",
# "Maicena", "Buen pan o castaña" (fruta de pan, no trigo) y los derivados de
# maíz. Verificado 2026-09-12: con exclusiones quedan 67 alimentos y 26,935
# registros; sin ellas la cifra se infla ~47%.
TRIGO_INCLUIR <- paste0(
  "\\bpan\\b|panecillo|galleta|fideo|macarron|espagueti|espaguetti|lasagn|",
  "harina de trigo|harina integral|bizcocho|croissant|hojaldre|\\bpasta\\b|",
  "tortilla|dona|sobado"
)
TRIGO_EXCLUIR <- paste0(
  "pasta de tomate|ajo en pasta|pasta de ajo|harina de maiz|harinas de maiz|",
  "maicena|de maiz|castana|fruta de pan|pan de fruta|masapan|negrito|arroz"
)

# Nutrientes iniciales del análisis (hoja de ruta: empezar con 4, no con 65)
NUTRIENTES_INICIALES <- c("Energia", "Hierro", "Acido folico", "Vitamina A")

# Escenarios de fortificación.
#
# IMPORTANTE: cuál de estos corresponde al marco normativo dominicano vigente
# es una pregunta para la contraparte técnica, NO un supuesto del análisis.
# Se modelan los tres y el resultado se presenta como RANGO, nunca como cifra
# única. Los códigos son ENHANCE_ID de INCAP, verificados 2026-09-12.
#
# Nota: INCAP NO tiene aceite fortificado con vitamina A (los 19 aceites del
# catálogo tienen VITA_RAE = 0), así que ese vehículo no es modelable con esta
# fuente. Se declara como limitación, no se inventa un valor.
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

# Consumo por EMA (salida de 04_equivalente_adulto.R). Trae `seccion` desde
# 2026-09-12; si falta, hay que volver a correr el 04.
cargar_gramos_por_ema <- function() {
  f <- file.path(RUTA_CLEAN, "data_gramos_por_ema.csv")
  exigir_archivo(f, "04_equivalente_adulto.R")
  d <- leer_limpio(f)
  if (!"seccion" %in% names(d)) {
    stop("`data_gramos_por_ema.csv` no tiene la columna `seccion`. ",
         "Volver a correr scripts/04_equivalente_adulto.R.", call. = FALSE)
  }
  d
}

# Peso muestral por hogar. Se toma el primero de cada hogar: el factor es una
# propiedad del hogar, no de la fila, asi que sumarlo por filas lo multiplicaria
# por el numero de alimentos registrados.
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

# Tabla de composición unificada INCAP + FNDDS, con los 4 nutrientes iniciales.
# Misma lógica que 05_ingesta_micronutrientes.R (pendiente: que el 05 escriba
# esta tabla a data/clean y que ambos la lean de ahí, en vez de duplicarla).
cargar_composicion <- function() {
  incap <- read_excel(file.path(RUTA_RAW, "food_composition_INCAP.xlsx"),
                      sheet = "nutrient_values") |>
    transmute(
      enhance_id         = as.numeric(ENHANCE_ID),
      energia_kcal       = as.numeric(ENERC_KCAL),
      hierro_mg          = as.numeric(FE),
      folato_mcg_dfe     = as.numeric(FOLDFE),
      vitamina_a_mcg_rae = as.numeric(VITA_RAE)
    )
  
  # Los encabezados de FNDDS traen saltos de línea internos: se resuelven por
  # patrón, con error si no identifican exactamente una columna.
  fn <- read_excel(file.path(RUTA_RAW, "food_composition_FNDDS.xlsx"),
                   sheet = "nutrient_values", skip = 1, .name_repair = "minimal")
  col_fn <- function(patron, etiqueta) {
    nn <- gsub("[[:space:]]+", " ", trimws(names(fn)))
    i <- grep(patron, nn, ignore.case = TRUE, perl = TRUE)
    if (length(i) != 1) {
      stop("El patron de '", etiqueta, "' identifica ", length(i),
           " columnas en FNDDS (deberia ser 1)", call. = FALSE)
    }
    names(fn)[i]
  }
  fndds <- fn |>
    transmute(
      enhance_id         = as.numeric(.data[[col_fn("^Food code$", "id")]]),
      energia_kcal       = as.numeric(.data[[col_fn("^Energy \\(kcal\\)$", "energia")]]),
      hierro_mg          = as.numeric(.data[[col_fn("^Iron ?\\(mg\\)$", "hierro")]]),
      folato_mcg_dfe     = as.numeric(.data[[col_fn("^Folate, DFE", "folato")]]),
      vitamina_a_mcg_rae = as.numeric(.data[[col_fn("^Vitamin A, RAE", "vitamina A")]])
    )
  
  bind_rows(incap, fndds) |>
    filter(!is.na(enhance_id)) |>
    distinct(enhance_id, .keep_all = TRUE)
}

# --- Diseno muestral complejo -------------------------------------------------
# La ENGIH es una muestra estratificada por conglomerados: 8 estratos, 933
# unidades primarias de muestreo (UPM) y factor de expansion por hogar.
#
# Ignorar la estructura NO sesga las estimaciones puntuales de forma
# sistematica, pero SI subestima los errores estandar: los intervalos salen
# demasiado estrechos y cualquier contraste se vuelve optimista.
#
# Requiere que 04_equivalente_adulto.R haya conservado estrato, upm y
# factor_expansion en data_ema_hogar.csv (desde 2026-09-13).

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

# Construye el objeto de diseno a partir de un data frame a nivel de HOGAR.
# `datos` debe traer id_hogar_unico; las variables de diseno se unen desde
# data_ema_hogar.csv, que es donde viven.
diseno_muestral <- function(datos) {
  if (!requireNamespace("srvyr", quietly = TRUE)) {
    stop("Falta el paquete `srvyr`. Instalar con install.packages(\"srvyr\").",
         call. = FALSE)
  }

  dis <- cargar_ema_hogar() |>
    select(id_hogar_unico, estrato, upm, factor_expansion,
           quintil, zona, grupo_region)

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

# Media ponderada con intervalo (Taylor) + mediana ponderada como descriptivo.
# `por` admite variables de agrupacion: quintil, zona, grupo_region.
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

# --- Helpers ------------------------------------------------------------------

# Normaliza texto para emparejar descripciones sin depender de acentos/mayúsculas
norm_txt <- function(x) {
  x |> as.character() |> tolower() |>
    iconv(to = "ASCII//TRANSLIT") |>
    trimws()
}

# Marca a qué vehículo pertenece cada fila (NA si a ninguno).
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

# Formato numerico en convencion espanola: miles con punto, decimales con coma.
#
# Necesario porque `kable(format.args = ...)` NO alcanza a los valores que se
# construyen con paste0 antes de llegar a la tabla -- tipicamente los intervalos
# de confianza. Sin esto, una misma tabla mezcla "1.831,6" con "2084.3".
fmt <- function(x, dec = 1) {
  formatC(round(x, dec), format = "f", digits = dec,
          big.mark = ".", decimal.mark = ",")
}

# Intervalo formateado, con guion largo como separador.
ic <- function(lo, hi, dec = 1) paste0(fmt(lo, dec), " – ", fmt(hi, dec))

# Porcentaje formateado, para no repetir round() en cada reporte.
# VECTORIZADO a proposito: se usa dentro de mutate() sobre columnas enteras,
# donde un if() ordinario falla ("the condition has length > 1").
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
