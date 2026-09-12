# ==============================================================================
# 97_normalizar_tipos_crosswalk.R
# Uso unico (2026-09-12). Borrar del repo una vez commiteado el resultado.
#
# PROBLEMA QUE RESUELVE
# 99_aplicar_correcciones_crosswalk.R leyo el Excel con col_types="text" y lo
# reescribio con writexl. Eso convirtio a texto columnas que antes eran numero
# o booleano, y dejo la columna `validado` con tres valores distintos para el
# mismo concepto: "TRUE" (265 filas), "VERDADERO" (154, las que agrego ese
# script) y "1" (1 fila).
#
# CONSECUENCIAS, AMBAS REALES
#   1. RUIDOSA -- 01_import.R falla al unir sec2_data (id numerico) con
#      sec2_puente (id ahora texto).
#   2. SILENCIOSA Y PEOR -- 01_import.R filtra con `validado == TRUE`. Las 154
#      filas que dicen "VERDADERO" no cumplen esa condicion, asi que se
#      descartaban sin aviso: el pipeline corria "bien" y reportaba la
#      cobertura anterior. Este es el tipo de fallo que no aparece como error.
#
# QUE HACE
# Restaura los tipos originales por columna y unifica `validado` a booleano.
# No cambia ningun mapeo ni ningun codigo: solo tipos y representacion.
# ==============================================================================

library(readxl)
library(dplyr)
library(here)

if (!requireNamespace("writexl", quietly = TRUE)) install.packages("writexl")

f <- here("data", "raw", "crosswalk_tablas_composicion.xlsx")

hojas <- excel_sheets(f)
datos <- lapply(hojas, function(h) read_excel(f, sheet = h, col_types = "text"))
names(datos) <- hojas

# Convierte a logico cualquiera de las representaciones que quedaron mezcladas.
# Se listan explicitamente en vez de usar as.logical() a secas porque
# as.logical("VERDADERO") devuelve NA silenciosamente.
a_logico <- function(x) {
  v <- toupper(trimws(as.character(x)))
  case_when(
    v %in% c("TRUE", "VERDADERO", "V", "1", "SI", "SÍ") ~ TRUE,
    v %in% c("FALSE", "FALSO", "F", "0", "NO")          ~ FALSE,
    TRUE                                                ~ NA
  )
}

a_numero <- function(x) suppressWarnings(as.numeric(as.character(x)))

# --- Sec 2: `variedad` vuelve a numerico (01_import.R une contra un id double)
if ("Cuest. B Sec 2" %in% hojas) {
  datos[["Cuest. B Sec 2"]] <- datos[["Cuest. B Sec 2"]] |>
    mutate(
      variedad       = a_numero(variedad),
      freq_registros = a_numero(freq_registros),
      enhance_id     = a_numero(enhance_id),
      validado       = a_logico(validado)
    )
}

# --- Sec 3A: `id_variedad` se queda TEXTO a proposito (es un codigo, no una
# cantidad; convencion ya documentada en 01_import.R linea 311)
if ("Cuest. B Sec 3A" %in% hojas) {
  datos[["Cuest. B Sec 3A"]] <- datos[["Cuest. B Sec 3A"]] |>
    mutate(
      id_variedad    = as.character(id_variedad),
      freq_registros = a_numero(freq_registros),
      enhance_id     = a_numero(enhance_id),
      validado       = a_logico(validado)
    )
}

# --- Diccionario Sec 2: tambien tiene `validado`
if ("diccionario_variedades_sec2" %in% hojas) {
  datos[["diccionario_variedades_sec2"]] <- datos[["diccionario_variedades_sec2"]] |>
    mutate(
      variedad         = a_numero(variedad),
      frecuencia_datos = a_numero(frecuencia_datos),
      validado         = a_logico(validado)
    )
}

# --- Guardas ------------------------------------------------------------------
s3 <- datos[["Cuest. B Sec 3A"]]
s2 <- datos[["Cuest. B Sec 2"]]

stopifnot(
  "Se perdieron filas en Sec 3A"        = nrow(s3) == 769,
  "Quedaron `validado` sin interpretar" = !any(is.na(s3$validado)) && !any(is.na(s2$validado)),
  "Cambio la cantidad de mapeos"        = sum(!is.na(s3$enhance_id)) == 407
)

writexl::write_xlsx(datos, path = f)

# --- Verificacion -------------------------------------------------------------
cat("\n--------------------------------------------------\n")
cat("Sec 3A -- filas:", nrow(s3), "\n")
cat("Sec 3A -- con enhance_id:", sum(!is.na(s3$enhance_id)), "\n")
cat("Sec 3A -- validado = TRUE:", sum(s3$validado), "\n")
cat("Sec 3A -- mapeados Y validados (los que entran):",
    sum(!is.na(s3$enhance_id) & s3$validado), "\n")
cat("Sec 2  -- validado = TRUE:", sum(s2$validado), "\n")
cat("--------------------------------------------------\n")
cat("\nSiguiente paso: correr 01_import.R\n")
