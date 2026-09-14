# ==============================================================================
# 90_helpers_formato.R
# Uso unico (2026-09-14). Borrar del repo una vez commiteado el resultado.
#
# Mueve a reports/_comun.R las funciones de formato numerico que hoy viven
# duplicadas dentro de R3 y R5.
#
#   fmt(x, dec)     miles con punto, decimales con coma (convencion espanola)
#   ic(lo, hi, dec) intervalo formateado "1.234,5 - 2.345,6"
#
# POR QUE IMPORTA: `kable(format.args = ...)` no alcanza a los intervalos, que
# se construyen con paste0 antes de llegar a la tabla. Sin estas funciones, una
# misma tabla mezcla "1.831,6" en una columna y "2084.3 - 2259.6" en la de al
# lado. Centralizarlas evita que cada reporte resuelva lo mismo a su manera.
#
# NO SOBRESCRIBE _comun.R: inserta el bloque y deja el resto intacto.
# ==============================================================================

library(here)

ruta <- here("reports", "_comun.R")
if (!file.exists(ruta)) stop("No encuentro reports/_comun.R", call. = FALSE)

txt <- paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

if (grepl("^fmt <- function", txt) || grepl("\nfmt <- function", txt)) {
  stop("`fmt()` ya esta en _comun.R. Nada que hacer.", call. = FALSE)
}

ancla <- "# Porcentaje formateado, para no repetir round() en cada reporte."
if (regexpr(ancla, txt, fixed = TRUE) == -1) {
  stop("No encuentro el ancla en _comun.R", call. = FALSE)
}

bloque <- '# Formato numerico en convencion espanola: miles con punto, decimales con coma.
#
# Necesario porque `kable(format.args = ...)` NO alcanza a los valores que se
# construyen con paste0 antes de llegar a la tabla -- tipicamente los intervalos
# de confianza. Sin esto, una misma tabla mezcla "1.831,6" con "2084.3".
fmt <- function(x, dec = 1) {
  formatC(round(x, dec), format = "f", digits = dec,
          big.mark = ".", decimal.mark = ",")
}

# Intervalo formateado, con guion largo como separador.
ic <- function(lo, hi, dec = 1) paste0(fmt(lo, dec), " \u2013 ", fmt(hi, dec))

'

nuevo <- sub(ancla, paste0(bloque, ancla), txt, fixed = TRUE)
writeLines(strsplit(nuevo, "\n")[[1]], ruta, useBytes = TRUE)

cat("\n--------------------------------------------------\n")
cat("Anadidas a reports/_comun.R:\n")
cat("  fmt(x, dec)      formato espanol\n")
cat("  ic(lo, hi, dec)  intervalo formateado\n")
cat("--------------------------------------------------\n")
cat("\nAhora se pueden eliminar las definiciones duplicadas dentro de\n")
cat("R3_cobertura_vehiculos.qmd y R5_equidad.qmd (opcional: funcionan igual,\n")
cat("porque la definicion local tiene prioridad y es identica).\n")
cat("\nVerificacion:\n")
cat('  source(here::here("reports", "_comun.R")); fmt(1234.567, 2)\n')
cat('  debe devolver "1.234,57"\n')
