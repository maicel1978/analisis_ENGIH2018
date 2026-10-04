# 80_a3_provincia.R -- USO UNICO
#
# Bloque A3: la provincia llega hasta el nivel de hogar y al diseno muestral.
#   - 01_import.R: conserva id_provincia y des_provincia.
#   - 04_equivalente_adulto.R: las lleva al hogar e informa cuantas hay.
#   - reports/_comun.R: diseno_muestral() las incluye.
#   - Hoja de ruta: A3 marcado como hecho.
#
# No cambia ninguna cifra: solo arrastra dos variables.
# Si un ancla no aparece exactamente una vez, no se escribe ningun archivo.
#
# Uso: source(here::here("scripts", "80_a3_provincia.R"))

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

# Sustituye por `nuevo` (una o varias lineas) la unica linea igual a `viejo`,
# sin contar espacios al inicio o al final.
cambiar_linea <- function(a, viejo, nuevo) {
  i <- which(trimws(a$lineas) == viejo)
  if (length(i) != 1) {
    stop(basename(a$ruta), ": '", viejo, "' aparece ", length(i),
         " veces (deberia ser 1). No se modifico nada.", call. = FALSE)
  }
  a$lineas <- c(a$lineas[seq_len(i - 1)], nuevo, a$lineas[-seq_len(i)])
  a
}

s01   <- leer(here("scripts", "01_import.R"))
s04   <- leer(here("scripts", "04_equivalente_adulto.R"))
comun <- leer(here("reports", "_comun.R"))
hoja  <- leer(here("docs", "hoja-de-ruta.md"))

if (any(grepl("id_provincia", c(s01$lineas, s04$lineas, comun$lineas), fixed = TRUE))) {
  stop("El bloque A3 ya esta aplicado: no se modifica nada.", call. = FALSE)
}

s01 <- cambiar_linea(s01, "grupo_region,", c(
  "    grupo_region,",
  "    # La provincia no es dominio de estimacion de la encuesta (lo son region",
  "    # y zona); se conserva para analisis exploratorio con control de precision.",
  "    id_provincia,",
  "    des_provincia,"
))

s04 <- cambiar_linea(s04, "grupo_region     = first(grupo_region),", c(
  "    grupo_region     = first(grupo_region),",
  "    id_provincia     = first(id_provincia),",
  "    des_provincia    = first(des_provincia),"
))
s04 <- cambiar_linea(s04, "\" | quintiles: \", n_distinct(ema_hogar$quintil),", c(
  "  \" | quintiles: \", n_distinct(ema_hogar$quintil),",
  "  \" | provincias: \", n_distinct(ema_hogar$id_provincia),"
))

comun <- cambiar_linea(comun, "quintil, zona, grupo_region)",
  "           quintil, zona, grupo_region, id_provincia, des_provincia)")

hoja <- cambiar_linea(hoja,
  "- [ ] A3. Provincia en `01` y `04`; coeficiente de variaci\u00f3n por dominio.",
  c("- [x] A3. Provincia arrastrada en `01`, `04` y el dise\u00f1o muestral (32",
    "      provincias). No es dominio de estimaci\u00f3n de la encuesta: de 35 a 1.341",
    "      hogares y de 4 a 160 UPM por provincia. La precisi\u00f3n se eval\u00faa",
    "      en C3."))

for (a in list(s01, s04, comun, hoja)) escribir(a)
message("Revisar con: git diff")
