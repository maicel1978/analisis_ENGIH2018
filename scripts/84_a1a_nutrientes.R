# 84_a1a_nutrientes.R -- USO UNICO
#
# Bloque A1a: agrega zinc, B12, D y E a 05_ingesta_micronutrientes.R.
# Sustituye la lista fija de nutrientes por la tabla MAPA_NUTRIENTES.
#
# Cada sustitucion exige que su ancla aparezca exactamente una vez; si no,
# se detiene sin escribir nada. Tras aplicarlo y verificar, este archivo se
# elimina (el historial de git lo conserva).
#
# Uso, desde la consola de R con el proyecto abierto:
#   source(here::here("scripts", "84_a1a_nutrientes.R"))

library(here)

ruta <- here("scripts", "05_ingesta_micronutrientes.R")

# Conserva el fin de linea original del archivo (LF o CRLF).
bytes <- readBin(ruta, "raw", file.info(ruta)$size)
fin_linea <- if (any(bytes == as.raw(13))) "\r\n" else "\n"
lineas <- readLines(ruta, encoding = "UTF-8", warn = FALSE)

if (any(grepl("MAPA_NUTRIENTES", lineas, fixed = TRUE))) {
  stop("El bloque A1a ya esta aplicado: no se modifica nada.", call. = FALSE)
}

# Sustituye las lineas [inicio, fin] por `nuevo`. `inicio` debe aparecer una
# sola vez; `fin` es la primera coincidencia desde `inicio`.
reemplazar <- function(lineas, inicio, fin = inicio, nuevo) {
  i <- grep(inicio, lineas)
  if (length(i) != 1) {
    stop("El ancla '", inicio, "' aparece ", length(i),
         " veces (deberia ser 1). No se modifico nada.", call. = FALSE)
  }
  j <- i - 1 + grep(fin, lineas[i:length(lineas)])[1]
  if (is.na(j)) stop("No se encontro el cierre '", fin, "'.", call. = FALSE)
  message("  lineas ", i, "-", j, " sustituidas (", inicio, ")")
  c(lineas[seq_len(i - 1)], nuevo, lineas[-seq_len(j)])
}

# 1. Encabezado ---------------------------------------------------------------
lineas <- reemplazar(
  lineas,
  inicio = "^# Alcance acotado a 4 nutrientes",
  nuevo = c(
    "# Nutrientes: los de MAPA_NUTRIENTES (energia, hierro, folato, vitamina A,",
    "# zinc, B12, D y E).",
    "#",
    "# SUPUESTO sobre unidades de INCAP para ZN (mg), VITB12 (mcg), VITD (mcg) y",
    "# VITE (mg): el archivo no trae hoja de unidades. Se asumen las de los",
    "# identificadores INFOODS, coherentes con los maximos observados (94 / 90 /",
    "# 170 / 43). Pendiente de confirmar contra la documentacion de la tabla."
  )
)

# 2. Lista de nutrientes -> tabla ---------------------------------------------
lineas <- reemplazar(
  lineas,
  inicio = "^NUTRIENTES <- c\\(",
  nuevo = c(
    "# Nutrientes y su columna en cada tabla de composicion. Para agregar uno,",
    "# se agrega una fila.",
    "MAPA_NUTRIENTES <- tribble(",
    "  ~nutriente,            ~incap,        ~patron_fndds,",
    "  \"energia_kcal\",        \"ENERC_KCAL\",  \"^Energy \\\\(kcal\\\\)$\",",
    "  \"hierro_mg\",           \"FE\",          \"^Iron ?\\\\(mg\\\\)$\",",
    "  \"folato_mcg_dfe\",      \"FOLDFE\",      \"^Folate, DFE\",",
    "  \"vitamina_a_mcg_rae\",  \"VITA_RAE\",    \"^Vitamin A, RAE\",",
    "  \"zinc_mg\",             \"ZN\",          \"^Zinc ?\\\\(mg\\\\)$\",",
    "  \"vitamina_b12_mcg\",    \"VITB12\",      \"^Vitamin B-12 ?\\\\(mcg\\\\)$\",",
    "  \"vitamina_d_mcg\",      \"VITD\",        \"^Vitamin D\",",
    "  \"vitamina_e_mg\",       \"VITE\",        \"^Vitamin E \\\\(alpha\"",
    ")",
    "NUTRIENTES <- MAPA_NUTRIENTES$nutriente"
  )
)

# 3. Lectura de INCAP ---------------------------------------------------------
lineas <- reemplazar(
  lineas,
  inicio = "^nutrientes_incap <- read_excel\\(",
  fin    = "^  \\)$",
  nuevo = c(
    "cols_incap <- setNames(MAPA_NUTRIENTES$incap, MAPA_NUTRIENTES$nutriente)",
    "",
    "nutrientes_incap <- read_excel(",
    "  here(\"data\", \"raw\", \"food_composition_INCAP.xlsx\"),",
    "  sheet = \"nutrient_values\"",
    ") |>",
    "  select(enhance_id = ENHANCE_ID, all_of(cols_incap)) |>",
    "  mutate(enhance_id = as.numeric(enhance_id), fuente = \"INCAP\", .after = enhance_id)"
  )
)

# 4. Lectura de FNDDS ---------------------------------------------------------
lineas <- reemplazar(
  lineas,
  inicio = "^nutrientes_fndds <- fndds_raw \\|>",
  fin    = "^  \\)$",
  nuevo = c(
    "cols_fndds <- setNames(",
    "  mapply(col_fndds, MAPA_NUTRIENTES$patron_fndds, MAPA_NUTRIENTES$nutriente),",
    "  MAPA_NUTRIENTES$nutriente",
    ")",
    "",
    "# De las cuatro columnas de folato de FNDDS solo DFE corresponde a FOLDFE de",
    "# INCAP. De las dos de vitamina E se usa alfa-tocoferol total, no la anadida.",
    "nutrientes_fndds <- cols_fndds |>",
    "  lapply(\\(col) as.numeric(fndds_raw[[col]])) |>",
    "  as_tibble() |>",
    "  mutate(",
    "    enhance_id = as.numeric(fndds_raw[[col_fndds(\"^Food code$\", \"id\")]]),",
    "    fuente     = \"FNDDS\",",
    "    .before    = 1",
    "  )"
  )
)

# Escritura en binario para no alterar los fines de linea.
con <- file(ruta, "wb")
writeLines(enc2utf8(lineas), con, sep = fin_linea, useBytes = TRUE)
close(con)

message("05_ingesta_micronutrientes.R actualizado. Revisar con: git diff scripts/05_ingesta_micronutrientes.R")
