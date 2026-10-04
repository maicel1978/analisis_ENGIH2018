# 71_relleno_composicion.R -- USO UNICO
#
# Relleno de vacios de la tabla de composicion en 05_ingesta_micronutrientes.R.
#
# INCAP deja sin valor algunos nutrientes de alimentos de alto consumo (platano
# verde, guineo verde, naranja agria). Un vacio suma cero a la ingesta. Dos reglas:
#
#   1. Valores puntuales de data/raw/composicion_relleno.csv, cada uno con su
#      fuente. Solo llenan vacios: nunca sustituyen un valor existente.
#   2. Vitamina B12 y vitamina D = 0 en alimentos vegetales sin procesar
#      (frutas, verduras, raices y platanos, legumbres), donde el vacio de la
#      tabla corresponde a un cero real.
#
# Si un ancla no aparece exactamente una vez, no se escribe nada.
#
# Uso: source(here::here("scripts", "71_relleno_composicion.R"))

library(here)

ruta  <- here("scripts", "05_ingesta_micronutrientes.R")
bytes <- readBin(ruta, "raw", file.info(ruta)$size)
fin   <- if (any(bytes == as.raw(13))) "\r\n" else "\n"
x     <- readLines(ruta, encoding = "UTF-8", warn = FALSE)

if (any(grepl("composicion_relleno", x, fixed = TRUE))) {
  stop("Ya esta aplicado: no se modifica nada.", call. = FALSE)
}
if (!file.exists(here("data", "raw", "composicion_relleno.csv"))) {
  stop("Falta data/raw/composicion_relleno.csv.", call. = FALSE)
}

pos <- function(texto) {
  i <- which(trimws(x) == texto)
  if (length(i) != 1) stop("'", texto, "' aparece ", length(i), " veces.", call. = FALSE)
  i
}
i1 <- pos("select(enhance_id = ENHANCE_ID, all_of(cols_incap)) |>")
i2 <- pos("composicion <- bind_rows(nutrientes_incap, nutrientes_fndds)")
stopifnot(i2 > i1)

bloque <- c(
  "composicion <- bind_rows(nutrientes_incap, nutrientes_fndds)",
  "",
  "# Relleno de vacios de composicion -------------------------------------------",
  "# Un nutriente sin valor suma cero a la ingesta. Se completan dos casos:",
  "# valores puntuales con fuente declarada (composicion_relleno.csv), que solo",
  "# llenan vacios, y B12 y vitamina D en alimentos vegetales sin procesar, donde",
  "# el vacio de la tabla es un cero real.",
  "GRUPOS_VEGETALES <- c(\"Fruits\", \"Vegetables\", \"Roots, tubers, and plantains\",",
  "                      \"Pulses, seeds and nuts\")",
  "",
  "relleno <- read_delim(here(\"data\", \"raw\", \"composicion_relleno.csv\"), delim = \";\",",
  "                      show_col_types = FALSE, locale = locale(decimal_mark = \".\"))",
  "stopifnot(all(relleno$nutriente %in% NUTRIENTES),",
  "          all(relleno$enhance_id %in% composicion$enhance_id))",
  "",
  "vacios_antes <- sum(is.na(composicion[NUTRIENTES]))",
  "for (k in seq_len(nrow(relleno))) {",
  "  fila <- which(composicion$enhance_id == relleno$enhance_id[k])",
  "  nut  <- relleno$nutriente[k]",
  "  if (is.na(composicion[[nut]][fila])) composicion[[nut]][fila] <- relleno$valor[k]",
  "}",
  "composicion <- composicion |>",
  "  mutate(across(c(vitamina_b12_mcg, vitamina_d_mcg),",
  "                ~ if_else(is.na(.x) & grupo_incap %in% GRUPOS_VEGETALES, 0, .x))) |>",
  "  select(-grupo_incap)",
  "message(\"Relleno de composicion: \", vacios_antes - sum(is.na(composicion[NUTRIENTES])),",
  "        \" valores completados\")"
)

x[i1] <- "  select(enhance_id = ENHANCE_ID, grupo_incap = FG1_name, all_of(cols_incap)) |>"
x <- c(x[seq_len(i2 - 1)], bloque, x[-seq_len(i2)])

con <- file(ruta, "wb")
writeLines(enc2utf8(x), con, sep = fin, useBytes = TRUE)
close(con)
message("05_ingesta_micronutrientes.R actualizado. Revisar con: git diff scripts/05_ingesta_micronutrientes.R")
