# ==============================================================================
# 86_depurar_comentarios_pipeline.R
# Uso unico (2026-09-14). Borrar del repo una vez commiteado el resultado.
#
# Reescribe los comentarios anadidos al pipeline durante la incorporacion del
# diseno muestral y la lectura de FNDDS. Mismo criterio que en _comun.R: el
# comentario dice lo que el codigo no dice.
# ==============================================================================

library(here)

parchear <- function(archivo, viejo, nuevo, etiqueta) {
  ruta <- here(archivo)
  txt <- paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (!grepl(viejo, txt, fixed = TRUE)) {
    cat("  no encontrado:", etiqueta, "\n"); return(invisible(FALSE))
  }
  writeLines(strsplit(sub(viejo, nuevo, txt, fixed = TRUE), "\n")[[1]],
             ruta, useBytes = TRUE)
  cat("  ok  ", etiqueta, "\n")
  invisible(TRUE)
}

cat("\n01_import.R\n")
parchear("scripts/01_import.R",
'    # --- Diseno muestral complejo (incorporado 2026-09-13) ---------------
    # Sin estrato y UPM los errores estandar salen subestimados. Se arrastran
    # hasta el nivel de hogar para poder usar srvyr aguas abajo.',
'    # --- Diseno muestral ------------------------------------------------
    # Estrato y UPM son necesarios para estimar errores estandar correctos.',
"transmute sociodemografico")

parchear("scripts/01_import.R",
'    des_estrato,       # region + zona: de aqui se deriva urbano/rural',
'    des_estrato,       # region y zona; de aqui se deriva urbano/rural',
"comentario des_estrato")

cat("\n04_equivalente_adulto.R\n")
parchear("scripts/04_equivalente_adulto.R",
'    # El diseno muestral es propiedad del HOGAR, no de la persona: se toma el
    # primero de cada hogar. Sumarlo multiplicaria el peso por el numero de
    # miembros, que es un error frecuente y silencioso.',
'    # El diseno es propiedad del hogar: se toma el primer registro. Sumarlo
    # multiplicaria el peso por el numero de miembros.',
"ema_hogar")

parchear("scripts/04_equivalente_adulto.R",
'# Se conserva la marca de seccion (`seccion`). Sin ella, 05 no puede reportar
# por separado Sec 2 (inventario) y Sec 3A (adquisiciones), y esas dos NO son
# intercambiables: verificado 2026-09-12 que al sumarlas se duplican los
# almacenables -- arroz, aceite, azucar y leche aparecen en ambas secciones
# para los mismos hogares. Daniel indico Sec 2 y Santiago Sec 3A; la decision
# es de ellos, asi que el pipeline debe poder producir las tres variantes.',
'# Se conserva la marca de seccion para que 05 pueda reportar Sec 2 (existencias)
# y Sec 3A (adquisiciones) por separado. Al sumarlas se duplican los alimentos
# almacenables -- arroz, aceite, azucar y leche aparecen en ambas.',
"marca de seccion")

cat("\n05_ingesta_micronutrientes.R\n")
parchear("scripts/05_ingesta_micronutrientes.R",
'# Los encabezados de FNDDS traen saltos de linea DENTRO del nombre: el de
# hierro es literalmente "Iron" + salto + "(mg)". Escribirlos literales es
# fragil (falla segun como R interprete el escape, y se rompe si la fuente
# cambia el formato). Se resuelven por patron sobre el nombre normalizado,
# con stop() si el patron no identifica exactamente una columna -- asi un
# cambio en FNDDS falla ruidosamente en vez de devolver la columna equivocada.',
'# Los encabezados de FNDDS contienen saltos de linea internos ("Iron" + salto +
# "(mg)"). Se resuelven por patron sobre el nombre normalizado, con stop() si el
# patron no identifica exactamente una columna.',
"lectura FNDDS")

parchear("scripts/05_ingesta_micronutrientes.R",
'    # De las CUATRO columnas de folato de FNDDS (acido folico, folato de los
    # alimentos, folato total y DFE), solo DFE corresponde a FOLDFE de INCAP:
    # los equivalentes dietéticos ponderan el acido folico sintetico por su
    # mayor biodisponibilidad (factor 1.7). Usar "folato total" mezclaria dos
    # escalas y SUBESTIMARIA el aporte de los alimentos fortificados -- que es
    # justo lo que este analisis busca medir.',
'    # De las cuatro columnas de folato de FNDDS solo DFE corresponde a FOLDFE
    # de INCAP: los equivalentes dieteticos ponderan el acido folico sintetico
    # por su mayor biodisponibilidad (factor 1,7).',
"columna de folato")

parchear("scripts/05_ingesta_micronutrientes.R",
'# Paso 5: ingesta aparente por hogar, en TRES variantes --------------------
# Sec 2 (inventario) y Sec 3A (adquisiciones) miden cosas distintas y NO son
# sumables sin criterio: verificado 2026-09-12 que al sumarlas se duplican los
# almacenables. En los 572 hogares con energia > 6000 kcal/EMA/dia, el arroz
# aparece tres veces en el top (Arroz selecto y Arroz corriente en Sec 3A,
# ARROZ en Sec 2), y lo mismo aceite, azucar y leche -- es decir, TRES DE LOS
# CUATRO VEHICULOS DE FORTIFICACION estan afectados por el solapamiento.
#
# Daniel indico trabajar con Sec 2 y Santiago con Sec 3A. La eleccion es de
# ellos, no se resuelve aqui: este script produce las tres variantes para que
# la decision se tome viendo las consecuencias de cada una.',
'# Paso 5: ingesta aparente por hogar, en tres variantes --------------------
# Sec 2 (existencias) y Sec 3A (adquisiciones) miden cosas distintas. Al
# sumarlas se duplican los alimentos almacenables: de los 572 hogares con
# energia > 6.000 kcal/EMA/dia, 223 se explican por ese solapamiento, que
# afecta a arroz, aceite, azucar y leche.
#
# El tratamiento aplicable es una decision del equipo tecnico. Se producen las
# tres variantes para poder compararlas.',
"paso 5")

cat("\n--------------------------------------------------\n")
cat("Verificar que el pipeline sigue corriendo:\n")
cat('  source(here::here("scripts", "01_import.R"))\n')
cat('  source(here::here("scripts", "04_equivalente_adulto.R"))\n')
cat('  source(here::here("scripts", "05_ingesta_micronutrientes.R"))\n')
cat("\nCifras de control: 36.840 sin enhance_id | 303.408 filas | 8.774 hogares\n")
