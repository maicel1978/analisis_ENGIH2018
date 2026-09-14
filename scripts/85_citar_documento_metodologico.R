# ==============================================================================
# 85_citar_documento_metodologico.R
# Uso unico (2026-09-14). Borrar del repo una vez commiteado el resultado.
#
# En documentacion tecnica una fuente se cita por su titulo, no por quien la
# entrego. Sustituye las referencias personales en los comentarios del pipeline
# por la referencia al documento metodologico.
#
#   referencias/modelo-base-equivalente-mujer-adulta.pdf
#   referencias/modelo-base-calculo-consumo.pdf
# ==============================================================================

library(here)

archivos <- c("scripts/04_equivalente_adulto.R",
              "scripts/05_ingesta_micronutrientes.R")

R <- list(
  c('# Formula (documento de Daniel, "Modelo de Base - Equivalente de Mujer',
    '# Formula (documento metodologico "Modelo de Base - Equivalente de Mujer'),
  c('# IMPORTANTE: el documento de Daniel CITA las tablas de requerimiento',
    '# El documento metodologico cita las tablas de requerimiento'),
  c('# con el valor de referencia del documento de Daniel. La formula esta',
    '# con el valor del documento metodologico. La formula esta'),
  c('#      de Daniel, porque no hay como identificar a esas mujeres en los',
    '#      del documento metodologico, porque no hay como identificar a esas mujeres en los'),
  c('#      Daniel), no el peso real de cada persona, porque la ENGIH no',
    '#      metodologico), no el peso real de cada persona, porque la ENGIH no'),
  c('# Peso fijo por hipotesis del documento de Daniel: 65kg hombres, 55kg',
    '# Peso fijo por hipotesis del documento metodologico: 65kg hombres, 55kg'),
  c('# Daniel dice 2291 kcal exacto; usamos el valor calculado 2290.8 para',
    '# El documento de referencia indica 2291 kcal; se usa el valor calculado 2290,8 para'),
  c('# de Daniel -- para eso falta multiplicar por la composicion nutricional',
    '# del documento metodologico -- para eso falta multiplicar por la composicion nutricional'),
  c('# para los mismos hogares. Daniel indico Sec 2 y Santiago Sec 3A; la decision
# es de ellos, asi que el pipeline debe poder producir las tres variantes.',
    '# para los mismos hogares. El tratamiento aplicable es una decision del equipo
# tecnico, de modo que el pipeline produce las tres variantes.'),
  c('#    formula completa del documento de Daniel.',
    '#    formula completa del documento metodologico.'),
  c('Comparacion de variantes (la decision Sec2 / Sec3A / ambas es de los supervisores):',
    'Comparacion de variantes (el tratamiento aplicable es decision del equipo tecnico):'),
  c('# Daniel indico trabajar con Sec 2 y Santiago con Sec 3A. La eleccion es de
# ellos, no se resuelve aqui: este script produce las tres variantes para que
# la decision se tome viendo las consecuencias de cada una.',
    '# El tratamiento aplicable es una decision del equipo tecnico. Se producen las
# tres variantes para poder compararlas.')
)

total <- 0
for (f in archivos) {
  ruta <- here(f)
  if (!file.exists(ruta)) next
  txt <- paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  n <- 0
  for (par in R) {
    if (grepl(par[1], txt, fixed = TRUE)) {
      txt <- gsub(par[1], par[2], txt, fixed = TRUE); n <- n + 1
    }
  }
  if (n > 0) {
    writeLines(strsplit(txt, "\n")[[1]], ruta, useBytes = TRUE)
    cat("  ", basename(f), ":", n, "sustituciones\n")
    total <- total + n
  }
}

cat("\n--------------------------------------------------\n")
cat("Total:", total, "sustituciones\n")

restan <- character(0)
for (f in c(archivos, "reports/_comun.R")) {
  ruta <- here(f)
  if (!file.exists(ruta)) next
  txt <- readLines(ruta, warn = FALSE, encoding = "UTF-8")
  hit <- grep("Daniel|Santiago|Jonathan", txt, value = TRUE)
  if (length(hit) > 0) restan <- c(restan, paste0(basename(f), ": ", hit))
}
if (length(restan) > 0) {
  cat("\nQUEDAN referencias sin sustituir:\n")
  cat(paste0("  ", restan, collapse = "\n"), "\n")
} else {
  cat("Sin referencias personales en el pipeline.\n")
}
cat("--------------------------------------------------\n")
