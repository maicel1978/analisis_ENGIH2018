# ==============================================================================
# 87_depurar_comentarios.R
# Uso unico (2026-09-14). Borrar del repo una vez commiteado el resultado.
#
# Reescribe los comentarios de reports/_comun.R. Criterio: un comentario dice lo
# que el codigo no dice. Se eliminan las justificaciones de diseno, las
# advertencias en mayusculas y las frases de cierre.
# ==============================================================================

library(here)

ruta <- here("reports", "_comun.R")
txt <- paste(readLines(ruta, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

R <- list(

  c('# ==============================================================================
# _comun.R  --  Base compartida por TODOS los reportes (R1..R5)
#
# Por qué existe: si cada .qmd carga y define lo suyo, al mejorar un dato hay
# que tocar cinco archivos y se desincronizan. Acá se cambia una vez.
#
# No calcula resultados. Solo: rutas, carga, definiciones editables y helpers.
# ==============================================================================',
    '# ==============================================================================
# _comun.R -- definiciones compartidas por los informes R1 a R5.
#
# Rutas, carga de datos, parametros del analisis y funciones auxiliares.
# No calcula resultados.
# =============================================================================='),

  c('# --- Parámetros editables -----------------------------------------------------
# Esto es lo que se toca cuando cambia una definición. Nada más.

# Vehículos de fortificación (actuales y potenciales en RD).
# El patrón se aplica sobre `descripcion` de la ENGIH, sin distinguir
# mayúsculas ni acentos. Editar acá si se decide incluir/excluir algo:
# el cambio se propaga a todos los reportes.',
    '# --- Parametros del analisis --------------------------------------------------

# Vehiculos de fortificacion. El patron se aplica sobre `descripcion`,
# normalizada sin acentos ni mayusculas.'),

  c('# Definición AMPLIADA del vehículo trigo: harina + derivados de consumo directo.
#
# Por qué: la norma dominicana obliga a fortificar la harina EN EL MOLINO. Esa
# harina llega al hogar dentro del pan, no como harina. Medir la cobertura solo
# por "harina de trigo" mide el consumo de un insumo intermedio (8% de los
# hogares), no la exposición de la población al nutriente añadido. Es un
# problema de definición de indicador, no una cuestión nutricional.
#
# CUIDADO con el patrón: sin exclusiones captura falsos positivos graves --
# "Pasta de tomate" (12,150 registros), "Ajo en pasta", "Harinas de maíz",
# "Maicena", "Buen pan o castaña" (fruta de pan, no trigo) y los derivados de
# maíz. Verificado 2026-09-12: con exclusiones quedan 67 alimentos y 26,935
# registros; sin ellas la cifra se infla ~47%.',
    '# Definicion ampliada del vehiculo trigo: harina y derivados de consumo directo.
# La fortificacion se aplica en el molino, de modo que la harina llega al hogar
# mayoritariamente procesada.
#
# Las exclusiones evitan falsos positivos: "Pasta de tomate" (12.150 registros),
# "Ajo en pasta", derivados de maiz y "Buen pan o castana" (fruta de pan).
# Sin ellas la cifra se infla un 47%.'),

  c('# Escenarios de fortificación.
#
# IMPORTANTE: cuál de estos corresponde al marco normativo dominicano vigente
# es una pregunta para la contraparte técnica, NO un supuesto del análisis.
# Se modelan los tres y el resultado se presenta como RANGO, nunca como cifra
# única. Los códigos son ENHANCE_ID de INCAP, verificados 2026-09-12.
#
# Nota: INCAP NO tiene aceite fortificado con vitamina A (los 19 aceites del
# catálogo tienen VITA_RAE = 0), así que ese vehículo no es modelable con esta
# fuente. Se declara como limitación, no se inventa un valor.',
    '# Escenarios de fortificacion. Codigos ENHANCE_ID de INCAP.
#
# El marco normativo vigente esta pendiente de confirmacion, de modo que los
# resultados se presentan como rango entre los tres escenarios.
#
# El aceite no se modela: los 19 aceites de INCAP tienen VITA_RAE = 0 y no
# existe par fortificado / sin fortificar.'),

  c('# --- Carga --------------------------------------------------------------------
# Los CSV de data/clean NO están en git (son regenerables). Si faltan, hay que
# correr el pipeline. Fallar acá con mensaje claro es mejor que un reporte
# a medias.',
    '# --- Carga --------------------------------------------------------------------
# data/clean no esta versionado: se regenera con el pipeline.'),

  c('# delim=";" explícito y decimal "." : read_csv2() asume coma decimal y corrompe
# las columnas numéricas (bug real, 2026-09-08).',
    '# read_csv2() asume coma decimal y corrompe las columnas numericas.'),

  c('# Consumo por EMA (salida de 04_equivalente_adulto.R). Trae `seccion` desde
# 2026-09-12; si falta, hay que volver a correr el 04.',
    '# Consumo por EMA, salida de 04_equivalente_adulto.R.'),

  c('# Peso muestral por hogar. Se toma el primero de cada hogar: el factor es una
# propiedad del hogar, no de la fila, asi que sumarlo por filas lo multiplicaria
# por el numero de alimentos registrados.',
    '# Peso muestral por hogar. Se toma el primer registro: el factor es propiedad
# del hogar, y sumarlo por filas lo multiplicaria por el numero de alimentos.'),

  c('# Tabla de composición unificada INCAP + FNDDS, con los 4 nutrientes iniciales.
# Misma lógica que 05_ingesta_micronutrientes.R (pendiente: que el 05 escriba
# esta tabla a data/clean y que ambos la lean de ahí, en vez de duplicarla).',
    '# Composicion unificada INCAP + FNDDS.
# Duplica la logica de 05_ingesta_micronutrientes.R -- pendiente de unificar.'),

  c('  # Los encabezados de FNDDS traen saltos de línea internos: se resuelven por
  # patrón, con error si no identifican exactamente una columna.',
    '  # Los encabezados de FNDDS contienen saltos de linea internos.'),

  c('# --- Diseno muestral complejo -------------------------------------------------
# La ENGIH es una muestra estratificada por conglomerados: 8 estratos, 933
# unidades primarias de muestreo (UPM) y factor de expansion por hogar.
#
# Ignorar la estructura NO sesga las estimaciones puntuales de forma
# sistematica, pero SI subestima los errores estandar: los intervalos salen
# demasiado estrechos y cualquier contraste se vuelve optimista.
#
# Requiere que 04_equivalente_adulto.R haya conservado estrato, upm y
# factor_expansion en data_ema_hogar.csv (desde 2026-09-13).',
    '# --- Diseno muestral ----------------------------------------------------------
# Muestra estratificada por conglomerados: 8 estratos, 933 UPM, factor de
# expansion por hogar. Ignorar la estructura subestima los errores estandar.
#
# Requiere estrato, upm y factor_expansion en data_ema_hogar.csv.'),

  c('# Construye el objeto de diseno a partir de un data frame a nivel de HOGAR.
# `datos` debe traer id_hogar_unico; las variables de diseno se unen desde
# data_ema_hogar.csv, que es donde viven.',
    '# `datos` debe estar a nivel de hogar y traer id_hogar_unico. Las variables de
# diseno se unen desde data_ema_hogar.csv.'),

  c('# Media ponderada con intervalo (Taylor) + mediana ponderada como descriptivo.
# `por` admite variables de agrupacion: quintil, zona, grupo_region.',
    '# Media con intervalo por linealizacion de Taylor y mediana ponderada.
# `por`: quintil, zona o grupo_region.'),

  c('# --- Tablas con formato editorial ---------------------------------------------
# Notas de uso frecuente, para no repetirlas en cada documento.',
    '# --- Tablas -------------------------------------------------------------------'),

  c('# Devuelve gt en salidas HTML y flextable en Word. La nota al pie va DENTRO del
# objeto, de modo que la tabla se mantiene autocontenida al copiarla o al
# cambiar de formato.
#',
    '# Devuelve gt en HTML y flextable en Word, con la nota al pie dentro del objeto.
#'),

  c('# Formato numerico en convencion espanola: miles con punto, decimales con coma.
#
# Necesario porque `kable(format.args = ...)` NO alcanza a los valores que se
# construyen con paste0 antes de llegar a la tabla -- tipicamente los intervalos
# de confianza. Sin esto, una misma tabla mezcla "1.831,6" con "2084.3".',
    '# Formato numerico espanol. `kable(format.args = ...)` no alcanza a los valores
# construidos con paste0, como los intervalos de confianza.'),

  c('# Porcentaje formateado, para no repetir round() en cada reporte.
# VECTORIZADO a proposito: se usa dentro de mutate() sobre columnas enteras,
# donde un if() ordinario falla ("the condition has length > 1").',
    '# Porcentaje formateado. Vectorizado: se usa dentro de mutate() sobre columnas.'),

  c('# Una fila "entra al cálculo" solo si tiene las tres piezas de la fórmula
# Q x FC x PC / PM y no fue marcada como atípica.',
    '# Una fila entra al calculo si tiene Q, FC y PC, y no es atipica.'),

  c('# Marca a qué vehículo pertenece cada fila (NA si a ninguno).
# ampliado = TRUE sustituye "Harina de trigo" por "Trigo y derivados".',
    '# Asigna vehiculo a cada fila, NA si no corresponde a ninguno.
# ampliado = TRUE sustituye "Harina de trigo" por "Trigo y derivados".'),

  c('# Nutrientes iniciales del análisis (hoja de ruta: empezar con 4, no con 65)',
    '# Nutrientes incluidos en esta etapa del analisis.')
)

n <- 0
for (par in R) {
  if (grepl(par[1], txt, fixed = TRUE)) {
    txt <- sub(par[1], par[2], txt, fixed = TRUE); n <- n + 1
  } else {
    cat("  no encontrado:", substr(gsub("\n", " ", par[1]), 1, 58), "\n")
  }
}

writeLines(strsplit(txt, "\n")[[1]], ruta, useBytes = TRUE)

cat("\n--------------------------------------------------\n")
cat("reports/_comun.R:", n, "de", length(R), "bloques reescritos\n")
cat("--------------------------------------------------\n")
cat("\nVerificar que sigue funcionando:\n")
cat('  source(here::here("reports", "_comun.R"))\n')
cat('  exists("diseno_muestral") && exists("tabla") && exists("fmt")\n')
