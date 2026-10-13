# 00_descargar_datos.R
#
# Descarga los archivos de la encuesta a data/raw/, que NO esta versionado.
# El repositorio no guarda microdatos: guarda de donde salen y como comprobar
# que son los mismos.
#
# Parametros en data/raw/fuentes_datos.csv, una fila por archivo:
#   archivo      nombre con el que se guarda en data/raw/
#   url          direccion de descarga, tal como la publica la fuente
#   md5          resumen del archivo con el que se verifico el analisis
#   descripcion  que contiene
#   consultado   fecha en que se tomo la direccion
#
# Que hace, por archivo:
#   - si falta, lo descarga;
#   - si esta, no lo vuelve a descargar;
#   - compara el resumen con el registrado y SE DETIENE si no coincide;
#   - si la columna md5 esta vacia, lo calcula y lo imprime para registrarlo.
#
# Por que el resumen importa. Las cifras de control del analisis dependen del
# archivo exacto. Si la fuente republica una version corregida con la misma
# direccion, sin esta comprobacion la cadena correria y daria otras cifras sin
# que nadie lo advirtiera. Con ella, se detiene y lo dice.
#
# La direccion de descarga NO esta en el codigo: se toma de la pagina oficial y
# se escribe en el csv, junto con la fecha de consulta. Algunas fuentes anaden
# un parametro de version a la direccion; se copia tal cual aparece.

library(readr)
library(here)

FUENTES <- here("data", "raw", "fuentes_datos.csv")
DESTINO <- here("data", "raw")

fuentes <- read_delim(FUENTES, delim = ";", show_col_types = FALSE)

falta_url <- fuentes$archivo[is.na(fuentes$url) | trimws(fuentes$url) == ""]
if (length(falta_url) > 0) {
  stop("Sin direccion de descarga: ", paste(falta_url, collapse = ", "),
       "\nTomarla de la pagina oficial de la encuesta y escribirla en ",
       "data/raw/fuentes_datos.csv, con la fecha de consulta.", call. = FALSE)
}

dir.create(DESTINO, showWarnings = FALSE, recursive = TRUE)

for (i in seq_len(nrow(fuentes))) {
  f <- fuentes[i, ]
  ruta <- file.path(DESTINO, f$archivo)

  if (!file.exists(ruta)) {
    message("Descargando ", f$archivo, " ...")
    # mode = "wb" es obligatorio: sin el, Windows corrompe el xlsx.
    utils::download.file(f$url, ruta, mode = "wb", quiet = FALSE)
  } else {
    message(f$archivo, " ya esta en data/raw/; no se vuelve a descargar.")
  }

  resumen <- unname(tools::md5sum(ruta))

  if (is.na(f$md5) || trimws(f$md5) == "") {
    message("  resumen md5: ", resumen,
            "  <- anotarlo en fuentes_datos.csv para fijar esta version")
  } else if (!identical(resumen, trimws(f$md5))) {
    stop("El archivo ", f$archivo, " NO es el que se uso en el analisis.\n",
         "  registrado: ", f$md5, "\n",
         "  descargado: ", resumen, "\n",
         "La fuente pudo republicar una version corregida. Antes de seguir, ",
         "comparar las cifras de control de docs/hoja-de-ruta.md.", call. = FALSE)
  } else {
    message("  resumen verificado.")
  }
}

message("\nArchivos en data/raw/. Siguiente paso: scripts/01_import.R")
