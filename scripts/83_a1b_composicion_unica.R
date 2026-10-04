# 83_a1b_composicion_unica.R -- USO UNICO
#
# Bloque A1b: una sola fuente para la tabla de composicion.
#   - 05_ingesta_micronutrientes.R la escribe en data/clean/.
#   - reports/_comun.R deja de reconstruirla y la lee de ahi.
#   - Marca A1 como hecho en la hoja de ruta.
#
# Cada sustitucion exige que su ancla aparezca exactamente una vez; si alguna
# falla, no se escribe ningun archivo.
#
# Uso: source(here::here("scripts", "83_a1b_composicion_unica.R"))

library(here)

leer <- function(ruta) {
  bytes <- readBin(ruta, "raw", file.info(ruta)$size)
  list(ruta = ruta,
       fin = if (any(bytes == as.raw(13))) "\r\n" else "\n",
       lineas = readLines(ruta, encoding = "UTF-8", warn = FALSE))
}

escribir <- function(a) {
  con <- file(a$ruta, "wb")
  writeLines(enc2utf8(a$lineas), con, sep = a$fin, useBytes = TRUE)
  close(con)
  message("Actualizado: ", a$ruta)
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
  c(lineas[seq_len(i - 1)], nuevo, lineas[-seq_len(j)])
}

s05   <- leer(here("scripts", "05_ingesta_micronutrientes.R"))
comun <- leer(here("reports", "_comun.R"))
hoja  <- leer(here("docs", "hoja-de-ruta.md"))

if (any(grepl("composicion_unificada", c(s05$lineas, comun$lineas), fixed = TRUE))) {
  stop("El bloque A1b ya esta aplicado: no se modifica nada.", call. = FALSE)
}

# 1. El 05 escribe la tabla de composicion -------------------------------------
s05$lineas <- reemplazar(
  s05$lineas,
  inicio = "^composicion <- bind_rows\\(nutrientes_incap, nutrientes_fndds\\)$",
  nuevo = c(
    "composicion <- bind_rows(nutrientes_incap, nutrientes_fndds)",
    "",
    "# Tabla unica de composicion: los reportes la leen de aqui (reports/_comun.R).",
    "composicion |>",
    "  select(-fuente) |>",
    "  filter(!is.na(enhance_id)) |>",
    "  distinct(enhance_id, .keep_all = TRUE) |>",
    "  write_delim(here(\"data\", \"clean\", \"composicion_unificada.csv\"), delim = \";\")"
  )
)

# 2. _comun.R la lee en lugar de reconstruirla ---------------------------------
comun$lineas <- reemplazar(
  comun$lineas,
  inicio = "^# Composicion unificada INCAP \\+ FNDDS\\.$",
  fin    = "^\\}$",
  nuevo = c(
    "# Composicion unificada INCAP + FNDDS, generada por 05_ingesta_micronutrientes.R.",
    "# Tipos declarados: una columna con muchos vacios al inicio no debe leerse",
    "# como logica.",
    "cargar_composicion <- function() {",
    "  f <- file.path(RUTA_CLEAN, \"composicion_unificada.csv\")",
    "  exigir_archivo(f, \"05_ingesta_micronutrientes.R\")",
    "  read_delim(f, delim = \";\", col_types = cols(.default = col_double()),",
    "             locale = locale(decimal_mark = \".\"), na = c(\"\", \"NA\"))",
    "}"
  )
)

# 3. Hoja de ruta ---------------------------------------------------------------
hoja$lineas <- reemplazar(
  hoja$lineas,
  inicio = "^- \\[ \\] A1\\. Zinc, B12, D y E",
  nuevo  = paste0("- [x] A1. Zinc, B12, D y E en `05`; funci\u00f3n de composici\u00f3n \u00fanica. ",
                  "Cobertura en gramos: zinc 96,0%; B12 94,1%; D 89,1%; E 83,0%.")
)
hoja$lineas <- sub(
  "^- \\[ \\] (\\*\\*Refactor pendiente: `cargar_composicion\\(\\)` est\u00e1 duplicada\\.\\*\\*)",
  "- [x] \\1 *Resuelto el 2026-10-03 (bloque A1b).*",
  hoja$lineas
)

escribir(s05); escribir(comun); escribir(hoja)
message("Revisar con: git diff")
