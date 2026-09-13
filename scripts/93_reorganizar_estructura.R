# ==============================================================================
# 93_reorganizar_estructura.R
# Uso unico (2026-09-13). Borrar del repo una vez commiteado el resultado.
#
# Reorganiza el repositorio segun una convencion explicita:
#
#   - Nombres en minusculas, sin acentos ni espacios. Guiones en documentos,
#     guiones bajos en codigo. Prefijo numerico SOLO donde el orden importa.
#   - Una carpeta = una categoria. Se separa lo que hoy esta mezclado:
#       docs/         -> documentacion del proyecto (se mantiene y evoluciona)
#       referencias/  -> material externo consultado (no cambia)
#       data/auditoria/    -> registro de decisiones (se conserva siempre)
#       data/diagnosticos/ -> exploracion regenerable (puede rehacerse)
#
# Usa git mv cuando es posible, para que el historial siga cada archivo.
# ==============================================================================

library(here)

raiz <- here()
setwd(raiz)

git_mv <- function(desde, hacia) {
  if (!file.exists(desde)) { cat("  (no existe)", desde, "\n"); return(invisible(FALSE)) }
  dir.create(dirname(hacia), showWarnings = FALSE, recursive = TRUE)
  r <- suppressWarnings(system2("git", c("mv", shQuote(desde), shQuote(hacia)),
                                stdout = TRUE, stderr = TRUE))
  ok <- is.null(attr(r, "status"))
  if (!ok) ok <- file.rename(desde, hacia)   # fallback si no estaba versionado
  cat(if (ok) "  ok   " else "  FALLO", basename(desde), "->", hacia, "\n")
  invisible(ok)
}

git_rm <- function(ruta) {
  if (!file.exists(ruta)) { cat("  (no existe)", ruta, "\n"); return(invisible(FALSE)) }
  r <- suppressWarnings(system2("git", c("rm", "-q", shQuote(ruta)),
                                stdout = TRUE, stderr = TRUE))
  ok <- is.null(attr(r, "status"))
  if (!ok) ok <- file.remove(ruta)
  cat(if (ok) "  ok   eliminado:" else "  FALLO", basename(ruta), "\n")
  invisible(ok)
}

# --- 1. referencias/ : material externo ---------------------------------------
cat("\n[1] Separando material de referencia externo\n")
dir.create("referencias", showWarnings = FALSE)

refs <- c(
  "docs/ENGIH_2018.pdf"                                    = "referencias/engih-2018-metodologia.pdf",
  "docs/Formulario ENGIH A. Caracteristicas del hogar y la vivienda.pdf"
                                                           = "referencias/formulario-a-caracteristicas-hogar.pdf",
  "docs/Formulario ENGIH B. Gastos diarios del hogar.pdf"  = "referencias/formulario-b-gastos-diarios.pdf",
  "docs/20251212 Modelo de Base - Calculos consumo.pdf"    = "referencias/modelo-base-calculo-consumo.pdf",
  "docs/20260903 Modelo de Base - Equivalente de Mujer Adulta (EMA).pdf"
                                                           = "referencias/modelo-base-equivalente-mujer-adulta.pdf",
  "docs/Annals of the New York Academy of Sciences - 2021 - Tang - Modeling food fortification contributions to micronutrient.pdf"
                                                           = "referencias/tang-2021-modeling-food-fortification.pdf",
  "docs/Analisis ENGIH con articulo de Tang.docx"          = "referencias/notas-marco-analitico-tang.docx"
)
for (i in seq_along(refs)) git_mv(names(refs)[i], refs[[i]])

# El PDF de canasta basica tiene acentos en el nombre: se busca por patron
pdfs <- list.files("docs", pattern = "\\.pdf$", full.names = TRUE)
canasta <- pdfs[grepl("canasta", pdfs, ignore.case = TRUE)]
if (length(canasta) == 1) git_mv(canasta, "referencias/canasta-basica-lineas-pobreza.pdf")

# --- 2. docs/ : documentacion del proyecto ------------------------------------
cat("\n[2] Moviendo la documentacion del proyecto a docs/\n")
git_mv("VISION_Y_ARQUITECTURA_PROYECTO.md", "docs/vision-y-arquitectura.md")
git_mv("HOJA_DE_RUTA_PROYECTO.md",          "docs/hoja-de-ruta.md")

# --- 3. data/ : auditoria vs diagnosticos -------------------------------------
cat("\n[3] Separando registros de auditoria de diagnosticos regenerables\n")
dir.create("data/auditoria",    showWarnings = FALSE, recursive = TRUE)
dir.create("data/diagnosticos", showWarnings = FALSE, recursive = TRUE)

# Auditoria: documentan decisiones. Se conservan siempre. Los produjeron
# scripts de uso unico ya eliminados, asi que nada los regenera: renombrarlos
# es seguro.
git_mv("data/eda/log_merge_crosswalk_2026-09-11.csv", "data/auditoria/log-crosswalk-mapeos.csv")
git_mv("data/eda/log_PC_lote154_2026-09-12.csv",      "data/auditoria/log-porcion-comestible.csv")
git_mv("data/eda/log_corrida_2026-09-10.txt",         "data/auditoria/log-corrida-pipeline.txt")
git_mv("data/eda/sessionInfo_02_eda.txt",             "data/auditoria/session-info.txt")

# Archivos superados: se eliminan ANTES de mover el resto, porque el bucle de
# abajo arrastraria todo lo que quede en data/eda/.
cat("\n[3b] Eliminando archivos ya incorporados (el historial de git los conserva)\n")
git_rm("data/eda/crosswalk_tablas_composicion_backup.xlsx")
git_rm("data/eda/revision_154_sugerencias.csv")
git_rm("reports/06_report.qmd")

# Diagnosticos: salidas exploratorias, regenerables al correr el pipeline.
# NO se renombran. 02_eda.R los reescribe con estos nombres exactos; renombrarlos
# a mano provocaria que la proxima corrida repueble la carpeta con la convencion
# vieja y queden dos mezcladas. Un nombre generado por codigo debe coincidir con
# lo que el codigo escribe.
for (f in list.files("data/eda", full.names = TRUE)) {
  git_mv(f, file.path("data/diagnosticos", basename(f)))
}

# --- 4. Nombre del proyecto ---------------------------------------------------
cat("\n[4] Normalizando el nombre del proyecto de RStudio\n")
git_mv("01_analisis_ENGIH2018.Rproj", "analisis_ENGIH2018.Rproj")

# --- 5. Rutas en el codigo ----------------------------------------------------
cat("\n[5] Actualizando rutas en los scripts\n")
parchear <- function(archivo, viejo, nuevo) {
  if (!file.exists(archivo)) return(invisible(FALSE))
  txt <- readLines(archivo, warn = FALSE, encoding = "UTF-8")
  if (!any(grepl(viejo, txt, fixed = TRUE))) { cat("  (sin cambios)", basename(archivo), "\n"); return(invisible(FALSE)) }
  writeLines(gsub(viejo, nuevo, txt, fixed = TRUE), archivo, useBytes = TRUE)
  cat("  ok   ", basename(archivo), ":", viejo, "->", nuevo, "\n")
  invisible(TRUE)
}
parchear("scripts/02_eda.R", 'here("data", "eda")', 'here("data", "diagnosticos")')
parchear("scripts/02_eda.R", "data/eda/",           "data/diagnosticos/")
parchear("scripts/05_ingesta_micronutrientes.R",
         'here("data", "eda", "alimentos_sin_composicion.csv")',
         'here("data", "diagnosticos", "alimentos_sin_composicion.csv")')

# --- 6. .gitignore ------------------------------------------------------------
# CRITICO: tres entradas apuntan a data/eda/. Si no se actualizan, esos archivos
# regenerables empiezan a versionarse al mover la carpeta.
cat("\n[6] Actualizando .gitignore\n")
gi <- readLines(".gitignore", warn = FALSE)

antes <- gi
gi <- gsub("data/eda/", "data/diagnosticos/", gi, fixed = TRUE)
gi <- gsub("01_analisis_ENGIH2018.Rproj", "analisis_ENGIH2018.Rproj", gi, fixed = TRUE)
if (!identical(antes, gi)) cat("  ok    rutas actualizadas\n")

if (!any(grepl("data/diagnosticos/\\*.html", gi))) {
  gi <- c(gi, "", "# Reporte HTML de dlookr (regenerable con 02_eda.R)",
          "data/diagnosticos/*.html")
  cat("  ok    anadida regla para el HTML de dlookr\n")
}
writeLines(gi, ".gitignore")

# --- Verificacion -------------------------------------------------------------
resto <- if (dir.exists("data/eda")) list.files("data/eda") else character(0)
if (length(resto) == 0 && dir.exists("data/eda")) unlink("data/eda", recursive = TRUE)

cat("\n--------------------------------------------------\n")
for (dd in c("docs", "referencias", "data/auditoria", "data/diagnosticos",
             "scripts", "reports")) {
  cat(sprintf("%-20s %s\n", paste0(dd, "/"),
              paste(list.files(dd), collapse = ", ")))
}
if (length(resto) > 0)
  cat("\nATENCION -- quedaron archivos en data/eda/: ", paste(resto, collapse = ", "), "\n")
cat("--------------------------------------------------\n")
cat("\nSiguiente paso: actualizar el README (las rutas cambiaron) y\n")
cat("correr 02_eda.R para confirmar que escribe en data/diagnosticos/.\n")
