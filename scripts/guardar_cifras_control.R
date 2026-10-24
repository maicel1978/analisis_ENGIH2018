# guardar_cifras_control.R
#
# Copia las salidas AGREGADAS de la cadena (proporciones, intervalos, medianas,
# diferencias entre escenarios) a data/auditoria/cifras_control/, que sí se
# versiona. Sirven como prueba de aceptación de cualquier reimplementación de
# la cadena: una versión nueva es correcta si reproduce estas cifras.
#
# No copia ningún archivo con un registro por hogar o por persona.
# Requiere haber corrido 01 a 08 y anexo_harina_maiz.R.

library(here)

AGREGADOS <- c(
  "riesgo_inadecuacion.csv",          # 07: proporción bajo el requerimiento, IC, por dominio
  "diferencias_escenarios.csv",       # 07: diferencias pareadas entre escenarios, IC
  "escenarios_resumen.csv",           # 06: medianas por escenario, razón Q5/Q1, sobre UL
  "escenarios_consumo_vehiculos.csv", # 06: cobertura y consumo por vehículo, IC
  "grupos_micronutrientes.csv",       # 08: aporte por grupo de alimentos
  "anexo_harina_maiz.csv"             # anexo: cobertura y consumo de harina de maíz
)

destino <- here("data", "auditoria", "cifras_control")
dir.create(destino, recursive = TRUE, showWarnings = FALSE)

origen <- here("data", "clean", AGREGADOS)
faltan <- AGREGADOS[!file.exists(origen)]
if (length(faltan) > 0) stop("Faltan salidas: ", paste(faltan, collapse = ", "), call. = FALSE)

# Comprobación de que son agregados: ninguno tiene identificador de hogar
for (f in origen) {
  cab <- names(read.csv2(f, nrows = 1, check.names = FALSE))
  if (any(grepl("id_hogar|vivienda|miembro", cab, ignore.case = TRUE))) {
    stop(basename(f), " contiene identificadores de hogar: no se copia.", call. = FALSE)
  }
}

file.copy(origen, destino, overwrite = TRUE)
writeLines(c(paste("Generado:", Sys.time()), R.version.string,
             paste("Commit:", system("git rev-parse --short HEAD", intern = TRUE))),
           file.path(destino, "LEEME.txt"))
message(length(origen), " archivos agregados copiados a ", destino)
