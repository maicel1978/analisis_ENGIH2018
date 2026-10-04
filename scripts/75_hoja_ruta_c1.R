# 75_hoja_ruta_c1.R -- USO UNICO
#
# Registra en la hoja de ruta los bloques B5 y C1 (escenarios con metodo
# aditivo) y la correccion sobre la linea base de los derivados de trigo.
# Si un ancla no aparece una sola vez, no escribe nada.
#
# Uso: source(here::here("scripts", "75_hoja_ruta_c1.R"))

library(here)

ruta  <- here("docs", "hoja-de-ruta.md")
bytes <- readBin(ruta, "raw", file.info(ruta)$size)
fin   <- if (any(bytes == as.raw(13))) "\r\n" else "\n"
x     <- readLines(ruta, encoding = "UTF-8", warn = FALSE)

if (any(grepl("07_escenarios_fortificacion", x, fixed = TRUE))) {
  stop("Ya esta aplicado: no se modifica nada.", call. = FALSE)
}

# Cada cambio sustituye dos lineas: la del ancla y la siguiente.
cambios <- list(
  list("- [ ] B5. Trigo en equivalentes de harina: pan, pastas y galletas convertidos", c(
    "- [x] B5. Trigo en equivalentes de harina (2026-10-04), dentro de",
    "      `scripts/07_escenarios_fortificacion.R`. Fracciones de harina en",
    "      `data/raw/vehiculos_escenarios.csv`, PROVISIONALES y sin fuente citable.",
    "      Resultado: el trigo alcanza al 91,8% de los hogares, con una media de",
    "      46,9 g de harina por EMA y d\u00eda; el arroz, 85,5% y 218 g.")),
  list("- [ ] C1. Escenarios: sin fortificaci\u00f3n, niveles recomendados por la OMS y", c(
    "- [x] C1. Escenarios con m\u00e9todo aditivo (2026-10-04), en `07`: se parte del",
    "      alimento sin fortificar y se suma el nivel de cada escenario (mg/kg),",
    "      definido en `data/raw/escenarios_fortificacion.csv`. Medianas ponderadas",
    "      de folato (\u00b5g DFE) e hierro (mg) por EMA y d\u00eda: sin fortificaci\u00f3n 158 y",
    "      7,65; norma nacional, harina y pan 229 y 8,92; norma con todos los",
    "      derivados 291 y 10,02; OMS para harina (tramo menor de 75 g) 500 y 10,22;",
    "      norma m\u00e1s arroz seg\u00fan la propuesta nacional 853 y 14,48. Raz\u00f3n de folato",
    "      entre quintiles 5 y 1: 1,20 sin fortificaci\u00f3n y con trigo; 1,03 con arroz.",
    "      \u00c1cido f\u00f3lico a\u00f1adido sobre el l\u00edmite superior: 8,0% de los hogares con",
    "      arroz; menos de 1,6% en los dem\u00e1s. Pendiente: niveles OMS de arroz, B12 y",
    "      vitamina A por confirmar, y riesgo de ingesta inadecuada por escenario.",
    "",
    "      CORRECCI\u00d3N: los escenarios de R4 y R5 no eran v\u00e1lidos como l\u00ednea base.",
    "      La tabla de composici\u00f3n trae pan, pastas y galletas elaborados con harina",
    "      enriquecida, de modo que el escenario \"sin fortificar\" ya inclu\u00eda la",
    "      fortificaci\u00f3n del trigo. La afirmaci\u00f3n de que fortificar la harina casi no",
    "      mueve la ingesta era un artefacto: con el m\u00e9todo aditivo la norma vigente",
    "      eleva el folato mediano entre 45% y 84%. El trigo y el arroz tienen alcance",
    "      similar; lo que los distingue es la cantidad consumida. El resultado de",
    "      equidad s\u00ed se mantiene. R4, R5, la presentaci\u00f3n y el README conservan la",
    "      versi\u00f3n anterior y no deben citarse en este punto."))
)

pos <- vapply(cambios, function(ca) {
  i <- which(x == ca[[1]])
  if (length(i) != 1) stop("'", ca[[1]], "' aparece ", length(i), " veces.", call. = FALSE)
  i
}, integer(1))

for (k in order(pos, decreasing = TRUE)) {
  x <- c(x[seq_len(pos[k] - 1)], cambios[[k]][[2]], x[-seq_len(pos[k] + 1)])
}

con <- file(ruta, "wb")
writeLines(enc2utf8(x), con, sep = fin, useBytes = TRUE)
close(con)
message("Hoja de ruta actualizada. Revisar con: git diff docs/hoja-de-ruta.md")
