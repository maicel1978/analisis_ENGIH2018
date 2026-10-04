# 73_b1_factores_campo.R -- USO UNICO
#
# Bloque B1: factores de conversion por unidad medidos en punto de venta el
# 2026-10-04 (5 unidades por pesaje), y correccion del factor de aji cubanela.
#
# La balanza usada marca libras. El factor de aji cubanela cargado en
# septiembre (288 g) trataba como kilogramos una lectura de 1,440 lb; el valor
# correcto es 131 g.
#
# Edita celdas de data/raw/data_raw_unidades.xlsx con openxlsx, sin reescribir
# las hojas: la hoja de la Seccion 2 tiene celdas de texto en columnas
# numericas y reescribirla cambiaria sus tipos. Antes de sustituir el archivo
# comprueba que ninguna otra celda cambio.
#
# Uso: source(here::here("scripts", "73_b1_factores_campo.R"))

if (!requireNamespace("openxlsx", quietly = TRUE)) {
  stop("Falta el paquete openxlsx. Instalar con install.packages(\"openxlsx\").", call. = FALSE)
}
library(dplyr)
library(readxl)
library(here)

ruta   <- here("data", "raw", "data_raw_unidades.xlsx")
HOJA_3A <- "Cuest. B Sec 3A"
HOJA_2  <- "Cuest. B Sec 2"
leer_texto <- function(archivo, hoja) read_excel(archivo, sheet = hoja, col_types = "text")

G_POR_LIBRA <- 453.592
VALIDACION  <- "ALTA_CONFIANZA_campo_propio"

# Lectura de la balanza, en libras, para 5 unidades (2026-10-04; el aji
# cubanela, 2026-09-09).
pesajes <- tribble(
  ~descripcion,                  ~libras,
  "Pl\u00e1tano verde",                2.3,
  "Pl\u00e1tano maduro",               2.2,
  "Guineo verde (guine\u00edto)",      1.96,
  "Guineo maduro (banano)",      1.54,
  "Aguacate",                    5.12,
  "Tomate Barcel\u00f3 o Bugal\u00fa",      1.40,
  "Naranja agria",               1.2,
  "Aj\u00ed grande (cubanela)",        1.44
) |>
  mutate(FC = round(libras * G_POR_LIBRA / 5),
         nota = paste0(FC, " g por unidad. Pesaje propio en punto de venta: 5 unidades = ",
                       format(libras, nsmall = 2), " lb. La balanza marca libras; ",
                       "pendiente de comprobar con un peso conocido."))

# La Seccion 2 usa otros nombres y une por codigo de variedad.
pesajes_sec2 <- tribble(
  ~variedad, ~origen,
  24,        "Pl\u00e1tano verde",
  25,        "Guineo verde (guine\u00edto)"
) |>
  left_join(pesajes |> select(origen = descripcion, FC, nota), by = "origen")

wb <- openxlsx::loadWorkbook(ruta)
escribir <- function(hoja, fila, columna, valor) {
  openxlsx::writeData(wb, hoja, x = valor, startRow = fila, startCol = columna, colNames = FALSE)
}

# Seccion 3A: unidad 1 = "Unidad" -------------------------------------------
s3   <- leer_texto(ruta, HOJA_3A)
col3 <- setNames(seq_along(s3), names(s3))
siguiente <- nrow(s3) + 2                      # fila de Excel; la 1 es el encabezado
tocadas_3a <- 0; agregadas_3a <- 0

for (k in seq_len(nrow(pesajes))) {
  d <- pesajes$descripcion[k]
  base <- which(s3$descripcion == d)
  if (length(base) == 0) stop("No existe en Sec 3A: ", d, call. = FALSE)
  i <- which(s3$descripcion == d & s3$id_unidad_medida_presentacion %in% c("1", "1.0"))
  con_fc <- i[!is.na(s3$FC[i])]
  if (length(con_fc) > 1) stop("Mas de una fila con FC para: ", d, call. = FALSE)
  nota <- pesajes$nota[k]
  if (length(con_fc) == 1) {
    fila <- con_fc + 1
    nota <- paste0(nota, " Sustituye al valor anterior de ", s3$FC[con_fc],
                   " g, calculado con la lectura en kilogramos.")
    tocadas_3a <- tocadas_3a + 1
  } else if (length(i) >= 1) {
    fila <- i[1] + 1
    tocadas_3a <- tocadas_3a + 1
  } else {
    fila <- siguiente; siguiente <- siguiente + 1; agregadas_3a <- agregadas_3a + 1
    escribir(HOJA_3A, fila, col3[["id_variedad"]], as.numeric(s3$id_variedad[base[1]]))
    escribir(HOJA_3A, fila, col3[["descripcion"]], d)
    escribir(HOJA_3A, fila, col3[["id_unidad_medida_presentacion"]], 1)
    escribir(HOJA_3A, fila, col3[["unidad_no_estandar"]], "Unidad")
  }
  escribir(HOJA_3A, fila, col3[["FC"]], pesajes$FC[k])
  escribir(HOJA_3A, fila, col3[["validacion"]], VALIDACION)
  escribir(HOJA_3A, fila, col3[["nota"]], nota)
}

# Seccion 2 --------------------------------------------------------------------
s2   <- leer_texto(ruta, HOJA_2)
col2 <- setNames(seq_along(s2), names(s2))
for (k in seq_len(nrow(pesajes_sec2))) {
  v <- pesajes_sec2$variedad[k]
  base <- which(as.numeric(s2$variedad) == v)
  if (length(base) == 0) stop("No existe en Sec 2 la variedad ", v, call. = FALSE)
  if (any(s2$id_unidad_medida_presentacion[base] %in% c("1", "1.0"))) {
    stop("Ya existe una fila de unidad para la variedad ", v, call. = FALSE)
  }
  fila <- nrow(s2) + 1 + k
  escribir(HOJA_2, fila, col2[["variedad"]], v)
  escribir(HOJA_2, fila, col2[["descripcion"]], s2$descripcion[base[1]])
  escribir(HOJA_2, fila, col2[["id_unidad_medida_presentacion"]], 1)
  escribir(HOJA_2, fila, col2[["unidad_no_estandar"]], "Unidad")
  escribir(HOJA_2, fila, col2[["FC"]], pesajes_sec2$FC[k])
  escribir(HOJA_2, fila, col2[["validacion"]], VALIDACION)
  escribir(HOJA_2, fila, col2[["nota"]], pesajes_sec2$nota[k])
}

# Comprobaciones sobre una copia antes de sustituir el archivo -----------------
temporal <- tempfile(fileext = ".xlsx")
openxlsx::saveWorkbook(wb, temporal, overwrite = TRUE)

comparar <- function(hoja, modificadas, agregadas) {
  antes <- leer_texto(ruta, hoja); despues <- leer_texto(temporal, hoja)
  if (!identical(names(antes), names(despues))) stop("Cambiaron las columnas de '", hoja, "'.", call. = FALSE)
  a <- as.matrix(antes); b <- as.matrix(despues[seq_len(nrow(antes)), ])
  # Numeros iguales escritos de forma distinta ("85" y "85.0") no cuentan.
  distinto <- (is.na(a) != is.na(b)) | (!is.na(a) & !is.na(b) & a != b &
              !(suppressWarnings(as.numeric(a) == as.numeric(b)) %in% TRUE))
  n_mod <- sum(rowSums(distinto) > 0); n_agr <- nrow(despues) - nrow(antes)
  cat(sprintf("%-18s filas: %d -> %d | modificadas: %d | agregadas: %d\n",
              hoja, nrow(antes), nrow(despues), n_mod, n_agr))
  if (n_mod != modificadas || n_agr != agregadas) {
    stop("En '", hoja, "' se esperaban ", modificadas, " filas modificadas y ", agregadas,
         " agregadas. No se sustituye el archivo.", call. = FALSE)
  }
  despues
}
for (h in setdiff(excel_sheets(ruta), c(HOJA_3A, HOJA_2))) comparar(h, 0, 0)
n3 <- comparar(HOJA_3A, tocadas_3a, agregadas_3a)
n2 <- comparar(HOJA_2, 0, nrow(pesajes_sec2))

dup3 <- n3 |> filter(!is.na(FC)) |> count(descripcion, id_unidad_medida_presentacion) |> filter(n > 1)
dup2 <- n2 |> filter(!is.na(FC), FC != "NA") |> count(variedad, id_unidad_medida_presentacion) |> filter(n > 1)
if (nrow(dup3) + nrow(dup2) > 0) stop("Quedarian claves duplicadas con FC. No se sustituye.", call. = FALSE)

file.copy(temporal, ruta, overwrite = TRUE)
message("data_raw_unidades.xlsx actualizado. Factores cargados:")
print(as.data.frame(pesajes |> select(descripcion, libras, FC)))
