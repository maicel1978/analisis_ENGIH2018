# ==============================================================================
# 88_helper_tablas.R
# Uso unico (2026-09-14). Borrar del repo una vez commiteado el resultado.
#
# Anade a reports/_comun.R una funcion `tabla()` que devuelve gt en salidas HTML
# y flextable en Word, con nota al pie dentro del propio objeto.
#
# Motivo: las notas escritas fuera del bloque de codigo se desacoplan de la
# tabla al cambiar el orden o el formato; dentro del bloque rompen la impresion
# (kable no se auto-imprime si le sigue otra expresion). Incluirlas en el objeto
# resuelve las dos cosas.
#
# La numeracion la sigue poniendo Quarto via `tbl-cap`, no la funcion.
# ==============================================================================

library(here)

ruta <- here("reports", "_comun.R")
txt <- paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

if (grepl("tabla <- function", txt, fixed = TRUE)) {
  stop("`tabla()` ya esta en _comun.R.", call. = FALSE)
}

ancla <- "# --- Helpers ------------------------------------------------------------------"
if (regexpr(ancla, txt, fixed = TRUE) == -1) stop("No encuentro la seccion de helpers", call. = FALSE)

bloque <- '# --- Tablas con formato editorial ---------------------------------------------
# Notas de uso frecuente, para no repetirlas en cada documento.
FUENTE_ENGIH <- paste(
  "Fuente: Encuesta Nacional de Gastos e Ingresos de los Hogares 2018,",
  "Banco Central de la República Dominicana."
)
NOTA_DISENO <- paste(
  "Estimaciones ponderadas con el diseño muestral complejo de la encuesta",
  "(8 estratos, 933 unidades primarias de muestreo, factor de expansión por",
  "hogar); intervalos de confianza por linealización de Taylor."
)
NOTA_EMA <- "EMA: Equivalente de Mujer Adulta. IC: intervalo de confianza."

# Devuelve gt en salidas HTML y flextable en Word. La nota al pie va DENTRO del
# objeto, de modo que la tabla se mantiene autocontenida al copiarla o al
# cambiar de formato.
#
#   datos    data frame ya formateado (columnas con su unidad en el nombre)
#   fuente   linea de procedencia; por defecto la ENGIH
#   notas    vector de notas adicionales (método, definiciones, abreviaturas)
#   ancho    ancho de la tabla en la salida HTML
tabla <- function(datos, fuente = FUENTE_ENGIH, notas = NULL, ancho = "100%") {

  es_word <- knitr::pandoc_to("docx")

  if (es_word && requireNamespace("flextable", quietly = TRUE)) {
    ft <- flextable::flextable(as.data.frame(datos))
    ft <- flextable::theme_booktabs(ft)
    ft <- flextable::autofit(ft)
    pie <- c(fuente, notas)
    for (p in rev(pie)) {
      ft <- flextable::add_footer_lines(ft, values = p)
    }
    ft <- flextable::fontsize(ft, size = 8, part = "footer")
    ft <- flextable::italic(ft, part = "footer")
    return(ft)
  }

  if (!requireNamespace("gt", quietly = TRUE)) return(knitr::kable(datos))

  g <- gt::gt(datos) |>
    gt::tab_options(
      table.width               = ancho,
      table.font.size           = gt::pct(88),
      heading.align             = "left",
      column_labels.font.weight = "bold",
      column_labels.background.color = "#f5f8fa",
      table.border.top.style    = "none",
      table_body.hlines.color   = "#eef2f4",
      data_row.padding          = gt::px(5),
      source_notes.font.size    = gt::pct(72),
      footnotes.font.size       = gt::pct(72)
    ) |>
    gt::opt_table_font(font = gt::google_font("Source Sans Pro"))

  for (p in c(fuente, notas)) {
    g <- gt::tab_source_note(g, source_note = p)
  }
  g
}

'

writeLines(strsplit(sub(ancla, paste0(bloque, ancla), txt, fixed = TRUE), "\n")[[1]],
           ruta, useBytes = TRUE)

cat("\n--------------------------------------------------\n")
cat("Anadido a reports/_comun.R:\n")
cat("  tabla(datos, fuente, notas, ancho)\n")
cat("  FUENTE_ENGIH · NOTA_DISENO · NOTA_EMA\n")
cat("--------------------------------------------------\n")
cat("\nProbar con:\n")
cat('  source(here::here("reports", "_comun.R"))\n')
cat('  tabla(head(iris, 3), notas = "Prueba.")\n')
