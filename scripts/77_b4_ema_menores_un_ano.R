# 77_b4_ema_menores_un_ano.R -- USO UNICO
#
# Bloque B4: requerimiento energetico de menores de un ano.
#
# Sustituye el valor provisional unico (600 kcal) por el promedio de los doce
# valores mensuales de FAO/WHO/UNU 2004 (seccion 3), por sexo: 649 kcal en
# ninos y 600 en ninas. La encuesta registra la edad en anos cumplidos, de modo
# que no se puede asignar el valor de cada mes.
#
#   - 04_equivalente_adulto.R: constante por sexo y comentarios al dia.
#   - INFORME_factibilidad.qmd: la limitacion deja de decir "provisional".
#   - Hoja de ruta: B4 hecho.
#
# Si un ancla no aparece exactamente una vez, no se escribe ningun archivo.
#
# Uso: source(here::here("scripts", "77_b4_ema_menores_un_ano.R"))

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

# Sustituye por `nuevo` las `n` lineas que empiezan en la unica linea igual a
# `inicio` (sin contar espacios al inicio o al final).
reemplazar <- function(a, inicio, nuevo, n = 1) {
  i <- which(trimws(a$lineas) == inicio)
  if (length(i) != 1) {
    stop(basename(a$ruta), ": '", inicio, "' aparece ", length(i),
         " veces (deberia ser 1). No se modifico nada.", call. = FALSE)
  }
  a$lineas <- c(a$lineas[seq_len(i - 1)], nuevo, a$lineas[-seq_len(i + n - 1)])
  a
}

s04     <- leer(here("scripts", "04_equivalente_adulto.R"))
informe <- leer(here("reports", "INFORME_factibilidad.qmd"))
hoja    <- leer(here("docs", "hoja-de-ruta.md"))

if (!any(grepl("KCAL_MENOR_1_ANO_PROVISIONAL", s04$lineas, fixed = TRUE))) {
  stop("El bloque B4 ya esta aplicado: no se modifica nada.", call. = FALSE)
}

# 1. 04 ---------------------------------------------------------------------------
s04 <- reemplazar(s04, n = 5,
  inicio = "#   3. Infantes menores de 1 ano: la Tabla 4.2/4.3 de FAO/WHO/UNU 2004",
  nuevo = c(
  "#   3. Menores de 1 ano: las Tablas 4.2 y 4.3 empiezan en 1-2 anos. Para",
  "#      edad 0 se usa el promedio de los doce valores mensuales de la",
  "#      seccion 3 del mismo informe, por sexo. La encuesta registra la edad",
  "#      en anos cumplidos, de modo que no se distingue el mes. No se descuenta",
  "#      la lactancia materna, que el cuestionario no registra."))

s04 <- reemplazar(s04, n = 4,
  inicio = "# Placeholder para menores de 1 a\u00f1o -- PENDIENTE DE REVISAR (ver",
  nuevo = c(
  "# Menores de 1 ano: promedio de los doce valores mensuales de FAO/WHO/UNU",
  "# 2004, seccion 3 (kcal/dia). Ninos, de 518 en el primer mes a 775 en el",
  "# duodecimo; ninas, de 464 a 712.",
  "KCAL_MENOR_1_ANO <- c(Masculino = 649, Femenino = 600)"))

s04 <- reemplazar(s04,
  "if (edad < 1) return(KCAL_MENOR_1_ANO_PROVISIONAL)",
  "  if (edad < 1) return(KCAL_MENOR_1_ANO[[sexo_texto]])")

s04 <- reemplazar(s04, n = 3,
  inicio = "# 1. Revisar KCAL_MENOR_1_ANO_PROVISIONAL contra FAO/WHO/UNU 2004",
  nuevo = c(
  "# 1. [HECHO 2026-10-04] Requerimiento de menores de 1 ano tomado de",
  "#    FAO/WHO/UNU 2004, seccion 3."))

# 2. Informe ----------------------------------------------------------------------
informe <- reemplazar(informe, n = 2,
  inicio = "para menores de un a\u00f1o emplea un valor provisional pendiente de contrastar con",
  nuevo = c(
  "para menores de un a\u00f1o es el promedio anual por sexo de la referencia",
  "FAO/OMS/UNU, sin descuento por lactancia materna."))

# 3. Hoja de ruta -----------------------------------------------------------------
hoja <- reemplazar(hoja, "- [ ] B4. Ajustes del equivalente de mujer adulta.", c(
  "- [x] B4. Equivalente de mujer adulta (2026-10-04). Menores de un a\u00f1o: 649 kcal",
  "      (ni\u00f1os) y 600 (ni\u00f1as), promedio anual de FAO/WHO/UNU 2004, en lugar del",
  "      valor provisional de 600. Afecta a 505 menores en 501 hogares (5,6%);",
  "      el cambio es de 0,02 EMA por ni\u00f1o var\u00f3n. Embarazo y lactancia no son",
  "      ajustables: el cuestionario no los registra. Cota de la lactancia: hasta",
  "      505 kcal (0,22 EMA) en, como m\u00e1ximo, ese 5,6% de hogares. El valor de",
  "      ni\u00f1as queda por contrastar mes a mes con la tabla de la fuente."))

for (a in list(s04, informe, hoja)) escribir(a)
message("Revisar con: git diff")
