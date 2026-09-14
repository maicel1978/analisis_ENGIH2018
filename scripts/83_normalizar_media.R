# ==============================================================================
# 83_normalizar_media.R
# Uso unico (2026-09-14). Borrar del repo una vez commiteado el resultado.
#
# Cuatro archivos de media/ tienen doble extension, resultado de guardarlos
# desde el telefono. Se renombran con git mv y se actualizan las rutas que los
# referencian en la presentacion.
#
#   aji_cubanela02.jpg.jpg      -> aji_cubanela02.jpg
#   aji_cubanela03.jpg.jpg      -> aji_cubanela03.jpg
#   aji_cubanela04.jpg.jpg      -> aji_cubanela04.jpg
#   platano_verde00.jpg02.jpeg  -> platano_verde01.jpg
# ==============================================================================

library(here)

dir_media <- here("media", "fotos_investigacion_mercado")

renombrar <- c(
  "aji_cubanela02.jpg.jpg"     = "aji_cubanela02.jpg",
  "aji_cubanela03.jpg.jpg"     = "aji_cubanela03.jpg",
  "aji_cubanela04.jpg.jpg"     = "aji_cubanela04.jpg",
  "platano_verde00.jpg02.jpeg" = "platano_verde01.jpg"
)

cat("\nRenombrando archivos\n")
setwd(here())
for (i in seq_along(renombrar)) {
  viejo <- file.path("media/fotos_investigacion_mercado", names(renombrar)[i])
  nuevo <- file.path("media/fotos_investigacion_mercado", renombrar[[i]])
  if (!file.exists(viejo)) { cat("  (no existe)", names(renombrar)[i], "\n"); next }
  r <- suppressWarnings(system2("git", c("mv", shQuote(viejo), shQuote(nuevo)),
                                stdout = TRUE, stderr = TRUE))
  ok <- is.null(attr(r, "status"))
  if (!ok) ok <- file.rename(viejo, nuevo)
  cat(if (ok) "  ok   " else "  FALLO", names(renombrar)[i], "->", renombrar[[i]], "\n")
}

cat("\nActualizando referencias\n")
for (f in list.files(here("reports"), pattern = "\\.qmd$", full.names = TRUE)) {
  txt <- readLines(f, warn = FALSE, encoding = "UTF-8")
  orig <- txt
  for (i in seq_along(renombrar)) {
    txt <- gsub(names(renombrar)[i], renombrar[[i]], txt, fixed = TRUE)
  }
  if (!identical(orig, txt)) {
    writeLines(txt, f, useBytes = TRUE)
    cat("  ok  ", basename(f), "\n")
  }
}

cat("\n--------------------------------------------------\n")
restan <- list.files(dir_media, pattern = "\\.(jpg|jpeg)\\.(jpg|jpeg)$|\\.jpg[0-9]")
if (length(restan) > 0) {
  cat("QUEDAN archivos con nombre irregular:\n")
  cat(paste0("  ", restan, collapse = "\n"), "\n")
} else {
  cat("Nombres de archivo normalizados.\n")
}
cat("--------------------------------------------------\n")
cat("\nRe-renderizar la presentacion y comprobar que las fotos aparecen.\n")
