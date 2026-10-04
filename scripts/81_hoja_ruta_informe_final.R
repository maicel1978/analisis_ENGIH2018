# 81_hoja_ruta_informe_final.R -- USO UNICO
#
# Registra en docs/hoja-de-ruta.md lo acordado el 2026-10-04 tras leer los
# comentarios de revision del informe:
#   - estructura del informe final (por preguntas);
#   - cambios al plan (escenarios, equivalentes de harina, densidad, yodo);
#   - correccion de la decision sobre sal y yodo.
#
# Si un ancla no aparece exactamente una vez, no se escribe nada.
#
# Uso: source(here::here("scripts", "81_hoja_ruta_informe_final.R"))

library(here)

ruta   <- here("docs", "hoja-de-ruta.md")
bytes  <- readBin(ruta, "raw", file.info(ruta)$size)
fin    <- if (any(bytes == as.raw(13))) "\r\n" else "\n"
x      <- readLines(ruta, encoding = "UTF-8", warn = FALSE)

if (any(grepl("Estructura del informe final", x, fixed = TRUE))) {
  stop("Ya esta aplicado: no se modifica nada.", call. = FALSE)
}

# Posicion de la unica linea que empieza por `ancla`.
pos <- function(ancla) {
  i <- which(startsWith(x, ancla))
  if (length(i) != 1) {
    stop("'", ancla, "' aparece ", length(i), " veces (deberia ser 1).", call. = FALSE)
  }
  i
}

# Todas las posiciones se calculan antes de modificar nada.
i_b4   <- pos("- [ ] B4. Ajustes del equivalente de mujer adulta.")
i_c1   <- pos("- [ ] C1. Escenarios con niveles de norma.")
i_c2   <- pos("- [ ] C2. Riesgo de ingesta inadecuada por nutriente.")
i_c4   <- pos("- [ ] C4. An\u00e1lisis por grupos de alimentos.")
i_fd   <- pos("**Fase D \u2014 cierre (19\u201323 oct)**")
i_d1   <- pos("- [ ] D1. Informe de factibilidad: recompilar")
i_d2   <- pos("- [ ] D2. Fusi\u00f3n a `main`")
i_arr  <- pos("- Escenario de arroz con los niveles de la propuesta nacional")
i_sal  <- pos("- Sal y yodo (revisado el 2026-10-04)")
i_dec  <- pos("**Decisiones adoptadas el 2026-10-03**")
stopifnot(i_d2 == i_d1 + 2, i_dec > i_d2)

x[i_b4] <- paste0(x[i_b4], "\n",
  "- [ ] B5. Trigo en equivalentes de harina: pan, pastas y galletas convertidos\n",
  "      a gramos de harina con factores de contenido de fuente citable.")
x[i_c1] <- paste0(
  "- [ ] C1. Escenarios: sin fortificaci\u00f3n, niveles recomendados por la OMS y\n",
  "      norma nacional. Sin aceite. Yodo desde la sal como escenario poblacional.")
x[i_c2] <- "- [ ] C2. Riesgo de ingesta inadecuada por nutriente; densidad por 1.000 kcal."
x[i_fd] <- "**Fase D \u2014 redacci\u00f3n y cierre (15\u201323 oct)**"
x[i_d1] <- "- [ ] D1. Informe final: reestructurar por preguntas, recompilar, comparar"
x[i_d1 + 1] <- "      contra la versi\u00f3n etiquetada y responder los comentarios de revisi\u00f3n."
x[i_arr] <- paste0(
  "- Escenarios (revisado el 2026-10-04, por comentario de revisi\u00f3n): sin\n",
  "  fortificaci\u00f3n, niveles OMS y norma nacional. La propuesta nacional de\n",
  "  reglamento de arroz se a\u00f1ade como fila adicional. El aceite no se modela.")
x[i_sal] <- paste0(
  "- Sal y yodo (revisado el 2026-10-04): la sal no figura en la Secci\u00f3n 2 y\n",
  "  solo el 13,3% de los hogares la registra en el diario (mediana de 26,5 g\n",
  "  por EMA y d\u00eda entre quienes la registran): la encuesta mide frecuencia de\n",
  "  compra, no consumo. El aporte de yodo se modela como escenario poblacional:\n",
  "  consumo promedio de sal de fuente externa por el rango de la norma\n",
  "  (20\u201350 mg/kg). No se estima distribuci\u00f3n por hogar ni riesgo.")

bloque <- c(
  "**Estructura del informe final (acordada el 2026-10-04).** Un solo documento",
  "principal: el informe de factibilidad evoluciona a informe final con formato",
  "de art\u00edculo. R1 a R5 quedan como cuadernos de c\u00e1lculo y no se pulen.",
  "",
  "1. Introducci\u00f3n: problema, preguntas e hip\u00f3tesis, objetivos.",
  "2. M\u00e9todos: breves; fuentes y cadena de c\u00e1lculo; el detalle va a anexo.",
  "3. Resultados: un apartado por pregunta, con una tabla o figura principal.",
  "4. Discusi\u00f3n: hallazgo por pregunta, contraste con la literatura,",
  "   limitaciones, implicaciones.",
  "5. Conclusiones.",
  "Anexos: calidad de datos y adaptaciones; decisiones adoptadas; respuesta a",
  "los comentarios de revisi\u00f3n (secci\u00f3n original, respuesta, ubicaci\u00f3n nueva);",
  "reproducibilidad.",
  "",
  "Preguntas: la de factibilidad (\u00bfpermite la encuesta el an\u00e1lisis, con qu\u00e9",
  "cobertura?) m\u00e1s las seis preguntas estrat\u00e9gicas de",
  "`docs/vision-y-arquitectura.md`. Hip\u00f3tesis solo donde se formul\u00f3 antes de",
  "ver el dato (efecto distributivo de un veh\u00edculo de consumo transversal).",
  "",
  "**Datos externos por conseguir:** consumo promedio de sal en el pa\u00eds;",
  "yodaci\u00f3n de la sal de los cubos de caldo (etiqueta y fabricante); factores",
  "de contenido de harina en pan, pastas y galletas.",
  ""
)
x <- c(x[seq_len(i_dec - 1)], bloque, x[i_dec:length(x)])
x <- unlist(strsplit(paste(x, collapse = "\n"), "\n", fixed = TRUE))

con <- file(ruta, "wb")
writeLines(enc2utf8(x), con, sep = fin, useBytes = TRUE)
close(con)
message("Hoja de ruta actualizada. Revisar con: git diff docs/hoja-de-ruta.md")
