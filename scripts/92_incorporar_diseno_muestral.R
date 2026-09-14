# ==============================================================================
# 92_incorporar_diseno_muestral.R
# Uso unico (2026-09-13). Borrar del repo una vez commiteado el resultado.
#
# QUE RESUELVE
# La ENGIH tiene diseno muestral complejo (8 estratos, 933 UPM, factor de
# expansion), pero el pipeline solo arrastraba `factor_expansion`. Sin ESTRATO y
# UPM no se pueden estimar errores estandar correctos: los intervalos de
# confianza salen sistematicamente subestimados.
#
# ETAPA 1 de 2. Este script SOLO modifica el pipeline para que las variables
# lleguen al nivel de hogar. NO cambia ningun calculo todavia, asi que todas las
# cifras deben quedar IDENTICAS despues de recorrerlo. Esa es la verificacion.
#
# ETAPA 2 (posterior): usar esas variables con srvyr en los reportes. Esa si
# cambiara cifras -- las medianas ponderadas difieren de las simples.
#
# Variables que se incorporan, desde el modulo sociodemografico:
#   estrato       ESTRATO        8 niveles
#   upm           UPM            933 unidades primarias de muestreo
#   quintil       QUINTIL        quintil de gasto, ya calculado por la encuesta
#   des_estrato   DES_ESTRATO    region + zona (de aqui se deriva urbano/rural)
#   grupo_region  GRUPO_REGION   4 regiones
# ==============================================================================

library(here)

parchear <- function(archivo, viejo, nuevo, etiqueta) {
  ruta <- here(archivo)
  if (!file.exists(ruta)) stop("No existe: ", archivo, call. = FALSE)
  txt <- readLines(ruta, warn = FALSE, encoding = "UTF-8")
  texto <- paste(txt, collapse = "\n")

  if (grepl(nuevo, texto, fixed = TRUE)) {
    cat("  (ya aplicado)", etiqueta, "\n"); return(invisible(FALSE))
  }
  n <- length(gregexpr(viejo, texto, fixed = TRUE)[[1]])
  if (regexpr(viejo, texto, fixed = TRUE) == -1) {
    stop("Ancla no encontrada en ", archivo, " (", etiqueta, ")", call. = FALSE)
  }
  if (n != 1) {
    stop("Ancla no unica en ", archivo, " (", etiqueta, "): ", n, " coincidencias",
         call. = FALSE)
  }
  writeLines(strsplit(sub(viejo, nuevo, texto, fixed = TRUE), "\n")[[1]],
             ruta, useBytes = TRUE)
  cat("  ok  ", etiqueta, "\n")
  invisible(TRUE)
}

cat("\n[1] 01_import.R -- conservar las variables de diseno\n")
parchear(
  "scripts/01_import.R",
  '  transmute(
    id_hogar_unico = paste(vivienda, hogar, sep = "_"),
    miembro,
    sexo       = a402,
    edad       = a403,
    parentesco = a404,
    factor_expansion
  )',
  '  transmute(
    id_hogar_unico = paste(vivienda, hogar, sep = "_"),
    miembro,
    sexo       = a402,
    edad       = a403,
    parentesco = a404,
    # --- Diseno muestral complejo (incorporado 2026-09-13) ---------------
    # Sin estrato y UPM los errores estandar salen subestimados. Se arrastran
    # hasta el nivel de hogar para poder usar srvyr aguas abajo.
    estrato          = estrato,
    upm,
    quintil,
    des_estrato,       # region + zona: de aqui se deriva urbano/rural
    grupo_region,
    factor_expansion
  )',
  "transmute sociodemografico")

cat("\n[2] 04_equivalente_adulto.R -- llevarlas al nivel de hogar\n")
parchear(
  "scripts/04_equivalente_adulto.R",
  '    EMA_hogar = sum(EMA_individual, na.rm = TRUE),
    factor_expansion = first(factor_expansion),
    .groups = "drop"',
  '    EMA_hogar = sum(EMA_individual, na.rm = TRUE),
    # El diseno muestral es propiedad del HOGAR, no de la persona: se toma el
    # primero de cada hogar. Sumarlo multiplicaria el peso por el numero de
    # miembros, que es un error frecuente y silencioso.
    factor_expansion = first(factor_expansion),
    estrato          = first(estrato),
    upm              = first(upm),
    quintil          = first(quintil),
    des_estrato      = first(des_estrato),
    grupo_region     = first(grupo_region),
    zona             = if_else(grepl("Rural", first(des_estrato)), "Rural", "Urbano"),
    .groups = "drop"',
  "ema_hogar")

cat("\n[3] 04_equivalente_adulto.R -- verificacion del diseno\n")
parchear(
  "scripts/04_equivalente_adulto.R",
  'message(
  "Hogares con EMA calculado: "',
  'message(
  "Diseno muestral -- estratos: ", n_distinct(ema_hogar$estrato),
  " | UPM: ", n_distinct(ema_hogar$upm),
  " | quintiles: ", n_distinct(ema_hogar$quintil),
  " | hogares sin factor de expansion: ", sum(is.na(ema_hogar$factor_expansion))
)
message(
  "Hogares con EMA calculado: "',
  "mensaje de verificacion")

cat("\n--------------------------------------------------\n")
cat("ETAPA 1 aplicada. Ahora hay que recorrer el pipeline:\n\n")
cat('  source(here::here("scripts", "01_import.R"))\n')
cat('  source(here::here("scripts", "03_transform.R"))\n')
cat('  source(here::here("scripts", "04_equivalente_adulto.R"))\n')
cat('  source(here::here("scripts", "05_ingesta_micronutrientes.R"))\n\n')
cat("CIFRAS QUE DEBEN QUEDAR IDENTICAS (si cambian, algo se rompio):\n")
cat("  01 -- Sec 3A: 36.840 sin enhance_id\n")
cat("  04 -- 303.408 filas con gramos por EMA | 8.892 hogares con EMA\n")
cat("  05 -- 8.774 hogares con ingesta\n\n")
cat("CIFRAS NUEVAS que debe imprimir el 04:\n")
cat("  Diseno muestral -- estratos: 8 | UPM: 933 | quintiles: 5\n")
cat("  hogares sin factor de expansion: 0\n")
cat("--------------------------------------------------\n")
