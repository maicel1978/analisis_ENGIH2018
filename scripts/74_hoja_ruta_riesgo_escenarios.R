# 74_hoja_ruta_riesgo_escenarios.R -- USO UNICO
#
# Registra en la hoja de ruta el riesgo de ingesta inadecuada por escenario.
# Si el ancla no aparece una sola vez, no escribe nada.
#
# Uso: source(here::here("scripts", "74_hoja_ruta_riesgo_escenarios.R"))

library(here)

ruta  <- here("docs", "hoja-de-ruta.md")
bytes <- readBin(ruta, "raw", file.info(ruta)$size)
fin   <- if (any(bytes == as.raw(13))) "\r\n" else "\n"
x     <- readLines(ruta, encoding = "UTF-8", warn = FALSE)

if (any(grepl("ESCENARIO_BASE", x, fixed = TRUE))) {
  stop("Ya esta aplicado: no se modifica nada.", call. = FALSE)
}

i <- which(startsWith(x, "- [ ] C2. Riesgo de ingesta inadecuada y densidad"))
j <- which(startsWith(x, "- [ ] C3. Desagregaci\u00f3n"))
if (length(i) != 1 || length(j) != 1 || j <= i) {
  stop("No se encontraron los bloques C2 y C3 en el orden esperado.", call. = FALSE)
}

nuevo <- c(
  "- [ ] C2. Riesgo de ingesta inadecuada por escenario (2026-10-04), en",
  "      `scripts/06_riesgo_inadecuacion.R`, que lee los escenarios de `07`. L\u00ednea",
  "      base de 2018: `ESCENARIO_BASE`, norma aplicada a harina y pan (1a).",
  "      Valores de referencia PROVISIONALES (IOM): no citables hasta sustituirlos",
  "      por los de la metodolog\u00eda MIMI. Hogares bajo el requerimiento, ponderado:",
  "",
  "      | Escenario | Folato | Hierro 10% | Hierro 18% | Zinc | B12 | Vit. A |",
  "      |---|---|---|---|---|---|---|",
  "      | Sin fortificaci\u00f3n | 78,3 | 80,1 | 53,8 | 45,3 | 46,3 | 84,5 |",
  "      | Norma, harina y pan | 66,8 | 75,4 | 46,0 | 45,3 | 46,3 | 84,5 |",
  "      | Norma, todos los derivados | 55,2 | 70,8 | 40,1 | 45,3 | 46,3 | 84,5 |",
  "      | Norma y az\u00facar | 55,2 | 70,8 | 40,1 | 45,3 | 46,3 | 42,9 |",
  "      | OMS harina, menos de 75 g | 28,2 | 69,9 | 39,1 | 21,8 | 20,3 | 57,0 |",
  "      | Norma y arroz (propuesta) | 14,2 | 51,4 | 23,7 | 21,4 | 18,3 | 84,5 |",
  "",
  "      \u00c1cido f\u00f3lico a\u00f1adido sobre el l\u00edmite superior: 8,0% con arroz; 1,5% con",
  "      OMS; menos de 0,2% con la norma. Vitaminas D y E (95,8% y 83,6%) no",
  "      cambian entre escenarios y est\u00e1n infladas por la cobertura de la tabla de",
  "      composici\u00f3n. El filtro de energ\u00eda plausible mueve las cifras menos de 3,5",
  "      puntos. La biodisponibilidad del hierro pesa m\u00e1s que cualquier escenario.",
  "      Supuestos que condicionan el resultado: fracciones de harina",
  "      provisionales, sin p\u00e9rdidas por cocci\u00f3n, y hierro y folato de los",
  "      derivados fijados desde la harina sin enriquecer."
)

x <- c(x[seq_len(i - 1)], nuevo, x[j:length(x)])

con <- file(ruta, "wb")
writeLines(enc2utf8(x), con, sep = fin, useBytes = TRUE)
close(con)
message("Hoja de ruta actualizada. Revisar con: git diff docs/hoja-de-ruta.md")
