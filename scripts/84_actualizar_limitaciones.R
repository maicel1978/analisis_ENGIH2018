# ==============================================================================
# 84_actualizar_limitaciones.R
# Uso unico (2026-09-14). Borrar del repo una vez commiteado el resultado.
#
# Cuatro documentos declaran como limitacion que no se reportan intervalos de
# confianza por no estar incorporado el diseno muestral. Dejo de ser cierto el
# 2026-09-13. En R3 el texto contradice directamente a sus propias tablas, que
# ya los muestran.
#
# Se sustituye por la descripcion del estado real, conservando la distincion
# util: las cifras de cobertura del procesamiento son conteos de registros, no
# estimaciones poblacionales, y no llevan intervalo porque no procede.
# ==============================================================================

library(here)

parchear <- function(archivo, viejo, nuevo) {
  ruta <- here(archivo)
  if (!file.exists(ruta)) { cat("  no existe:", archivo, "\n"); return(invisible(FALSE)) }
  txt <- paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (!grepl(viejo, txt, fixed = TRUE)) {
    cat("  no encontrado en", basename(archivo), "\n"); return(invisible(FALSE))
  }
  writeLines(strsplit(sub(viejo, nuevo, txt, fixed = TRUE), "\n")[[1]],
             ruta, useBytes = TRUE)
  cat("  ok  ", basename(archivo), "\n")
  invisible(TRUE)
}

cat("\nActualizando limitaciones sobre el diseño muestral\n")

parchear("reports/INFORME_factibilidad.qmd",
'**Del diseño muestral.** Las variables de estratificación, conglomeración y
expansión están disponibles en los datos (8 estratos, 933 unidades primarias,
factor de expansión sin valores ausentes), pero no se han incorporado aún al
cálculo. **En consecuencia no se reportan intervalos de confianza**, opción
preferible a reportarlos incorrectamente estrechos.',
'**Del diseño muestral.** Las estimaciones poblacionales incorporan la
estratificación, la conglomeración y el factor de expansión, con intervalos por
linealización de Taylor. Las cifras de cobertura del procesamiento son conteos
de registros y no estimaciones poblacionales: no llevan intervalo porque no
procede.')

parchear("reports/R2_modelo_base.qmd",
'- **Sin intervalos de confianza.** La ENGIH tiene diseño muestral complejo
  (8 estratos, 933 unidades primarias, factor de expansión). Las variables están
  disponibles; hasta incorporarlas mediante `srvyr` **no se reportan intervalos**,
  en lugar de reportarlos incorrectamente estrechos.',
'- **Estimaciones con diseño muestral complejo.** Se incorporan la
  estratificación (8 estratos), la conglomeración (933 unidades primarias) y el
  factor de expansión, con intervalos de confianza por linealización de Taylor.
  La mediana ponderada se reporta como descriptivo, sin intervalo.')

parchear("reports/R3_cobertura_vehiculos.qmd",
'- **Sin intervalos de confianza.** La ENGIH tiene diseño muestral complejo
  (8 estratos, 933 unidades primarias, factor de expansión). Las variables están
  disponibles y su incorporación mediante `srvyr` es el siguiente paso; **hasta
  entonces no se reportan intervalos**, en lugar de reportar intervalos
  incorrectamente estrechos.',
'- **Estimaciones con diseño muestral complejo.** Las proporciones de cobertura
  se estiman incorporando la estratificación (8 estratos), la conglomeración
  (933 unidades primarias) y el factor de expansión, con intervalos de confianza
  por linealización de Taylor.')

parchear("README.md",
'- **Sin intervalos de confianza.** La encuesta tiene diseño muestral complejo
  (8 estratos, 933 unidades primarias, factor de expansión). Las variables están
  disponibles; hasta incorporarlas no se reportan intervalos, en lugar de
  reportarlos incorrectamente estrechos.',
'- **Estimaciones con diseño muestral complejo.** Se incorporan la
  estratificación (8 estratos), la conglomeración (933 unidades primarias) y el
  factor de expansión, con intervalos de confianza por linealización de Taylor.
  Las cifras de cobertura del procesamiento son conteos de registros y no llevan
  intervalo.')

cat("\n--------------------------------------------------\n")
restan <- character(0)
for (f in c("reports/INFORME_factibilidad.qmd", "reports/R1_calidad_datos.qmd",
            "reports/R2_modelo_base.qmd", "reports/R3_cobertura_vehiculos.qmd",
            "reports/R4_escenarios_fortificacion.qmd", "reports/R5_equidad.qmd",
            "README.md", "docs/vision-y-arquitectura.md")) {
  ruta <- here(f)
  if (!file.exists(ruta)) next
  hit <- grep("no se reportan intervalos|Sin intervalos|hasta incorporarlas|Cuestionario A",
              readLines(ruta, warn = FALSE, encoding = "UTF-8"), value = TRUE)
  if (length(hit) > 0) restan <- c(restan, paste0(basename(f), ": ", trimws(hit)))
}
if (length(restan) > 0) {
  cat("QUEDAN afirmaciones obsoletas:\n")
  cat(paste0("  ", restan, collapse = "\n"), "\n")
} else {
  cat("Sin afirmaciones obsoletas sobre el diseño muestral.\n")
}
cat("--------------------------------------------------\n")
cat("\nRe-renderizar los cuatro documentos afectados.\n")
