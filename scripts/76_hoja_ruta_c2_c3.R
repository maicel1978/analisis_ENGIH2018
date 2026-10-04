# 76_hoja_ruta_c2_c3.R -- USO UNICO
#
# Registra en la hoja de ruta el estado de A5, C2 y C3 y el cambio del
# criterio de precision. Si un ancla no aparece una sola vez, no escribe nada.
#
# Uso: source(here::here("scripts", "76_hoja_ruta_c2_c3.R"))

library(here)

ruta  <- here("docs", "hoja-de-ruta.md")
bytes <- readBin(ruta, "raw", file.info(ruta)$size)
fin   <- if (any(bytes == as.raw(13))) "\r\n" else "\n"
x     <- readLines(ruta, encoding = "UTF-8", warn = FALSE)

if (any(grepl("06_riesgo_inadecuacion", x, fixed = TRUE))) {
  stop("Ya esta aplicado: no se modifica nada.", call. = FALSE)
}

cambios <- list(
  list("- [ ] A5. Tabla de par\u00e1metros normativos por veh\u00edculo.",
       "- [x] A5. Tabla de par\u00e1metros normativos por veh\u00edculo (`data/raw/parametros_normativos.csv`)."),
  list("- [ ] C2. Riesgo de ingesta inadecuada por nutriente; densidad por 1.000 kcal.",
       c("- [ ] C2. Riesgo de ingesta inadecuada y densidad por 1.000 kcal: c\u00e1lculo",
         "      hecho en `scripts/06_riesgo_inadecuacion.R` (punto de corte; probabilidad",
         "      para hierro; proporci\u00f3n sobre el l\u00edmite superior). Los valores de",
         "      referencia de `data/raw/valores_referencia.csv` y",
         "      `hierro_requerimiento.csv` son PROVISIONALES (IOM): se sustituyen por los",
         "      de la metodolog\u00eda MIMI. Resultados no citables hasta entonces ni hasta",
         "      cerrar C1: el folato muestra 23% bajo el requerimiento y 38% sobre el",
         "      l\u00edmite superior a la vez, artefacto del mapeo del arroz. La",
         "      biodisponibilidad del hierro (10% o 18%) cambia el resultado de 54% a 27%.")),
  list("- [ ] C3. Desagregaci\u00f3n por provincia, quintil y zona; mapas.",
       c("- [ ] C3. Desagregaci\u00f3n: hecha en `06` para regi\u00f3n, zona, quintil y provincia.",
         "      Regi\u00f3n, zona y quintil sin celdas de precisi\u00f3n baja (semiamplitud m\u00e1xima",
         "      3,6 puntos). Provincia: 47 de 256 celdas con precisi\u00f3n baja. Faltan los",
         "      mapas y la desagregaci\u00f3n del consumo de veh\u00edculos.")),
  list("- Provincia: se suprime la celda con coeficiente de variaci\u00f3n mayor de 30%.",
       c("- Precisi\u00f3n (revisado el 2026-10-04): en proporciones, la celda se marca si",
         "  tiene menos de 50 hogares o la semiamplitud del intervalo supera 10 puntos;",
         "  el coeficiente de variaci\u00f3n penaliza prevalencias bajas bien estimadas y se",
         "  reserva para medias (umbral 30%). La provincia no es dominio de estimaci\u00f3n."))
)

pos <- vapply(cambios, function(ca) {
  i <- which(x == ca[[1]])
  if (length(i) != 1) stop("'", ca[[1]], "' aparece ", length(i), " veces.", call. = FALSE)
  i
}, integer(1))

for (k in order(pos, decreasing = TRUE)) {
  x <- c(x[seq_len(pos[k] - 1)], cambios[[k]][[2]], x[-seq_len(pos[k])])
}

con <- file(ruta, "wb")
writeLines(enc2utf8(x), con, sep = fin, useBytes = TRUE)
close(con)
message("Hoja de ruta actualizada. Revisar con: git diff docs/hoja-de-ruta.md")
