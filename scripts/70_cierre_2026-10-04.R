# 70_cierre_2026-10-04.R -- USO UNICO
#
# Cierre de la jornada del 2026-10-04:
#   - Hoja de ruta: B1 y relleno de composicion hechos; cifras vigentes.
#   - Parametros normativos: evidencia de etiquetas del punto de venta.
#   - .gitignore: salidas regenerables de los diagnosticos.
#
# Si un ancla no aparece una sola vez, no escribe nada.
#
# Uso: source(here::here("scripts", "70_cierre_2026-10-04.R"))

library(here)

leer <- function(...) {
  ruta <- here(...)
  bytes <- readBin(ruta, "raw", file.info(ruta)$size)
  list(ruta = ruta, fin = if (any(bytes == as.raw(13))) "\r\n" else "\n",
       x = readLines(ruta, encoding = "UTF-8", warn = FALSE))
}
escribir <- function(a) {
  con <- file(a$ruta, "wb"); writeLines(enc2utf8(a$x), con, sep = a$fin, useBytes = TRUE); close(con)
  message("Actualizado: ", a$ruta)
}
unica <- function(a, inicio) {
  i <- which(startsWith(a$x, inicio))
  if (length(i) != 1) stop(basename(a$ruta), ": '", inicio, "' aparece ", length(i), " veces.", call. = FALSE)
  i
}

hoja <- leer("docs", "hoja-de-ruta.md")
par  <- leer("data", "raw", "parametros_normativos.csv")
ign  <- leer(".gitignore")

if (any(grepl("Cifras vigentes al cierre del 2026-10-04", hoja$x, fixed = TRUE))) {
  stop("Ya esta aplicado: no se modifica nada.", call. = FALSE)
}

# 1. Hoja de ruta ---------------------------------------------------------------
i_b1 <- unica(hoja, "- [ ] B1. Factores de conversi\u00f3n: pl\u00e1tano, guineo y resto de la cola.")
i_fa <- unica(hoja, "**Fase A \u2014 aditiva")

b1 <- c(
  "- [x] B1. Factores por unidad de siete alimentos, medidos en punto de venta",
  "      (2026-10-04): pl\u00e1tano verde 209 g, pl\u00e1tano maduro 200, guineo verde 178,",
  "      guineo maduro 140, aguacate 464, tomate 127 y naranja agria 109. La",
  "      balanza marca libras: el factor de aj\u00ed cubanela de septiembre (288 g)",
  "      trataba la lectura como kilogramos y se corrigi\u00f3 a 131 g. Pendiente:",
  "      comprobar la unidad de la balanza con un peso conocido; aj\u00ed gustoso y",
  "      apio sin cargar (la encuesta registra otra unidad). Registro y fotos:",
  "      `data/auditoria/verificacion_punto_venta_2026-10-04.csv`.",
  "- [x] Relleno de vac\u00edos de composici\u00f3n (2026-10-04), en `05`: valores puntuales",
  "      con fuente (`data/raw/composicion_relleno.csv`) y B12 y vitamina D en",
  "      cero para alimentos vegetales sin procesar. 278 valores completados.",
  "      Quedan unos 75 c\u00f3digos de INCAP con alg\u00fan nutriente vac\u00edo, sin tratar."
)

vigentes <- c(
  "**Cifras vigentes al cierre del 2026-10-04.** Sustituyen a las que figuran en",
  "las entradas B2, B3, C1 y C2 de este bloque, que son anteriores a B1 y al",
  "relleno de composici\u00f3n. Valores de referencia PROVISIONALES: no citables.",
  "",
  "- Entran al c\u00e1lculo 328.173 registros de 8.778 hogares: 97,1% de la Secci\u00f3n 2",
  "  y 82,4% de la Secci\u00f3n 3A (antes 90,7% y 76,0%).",
  "- Energ\u00eda mediana 2.300 kcal por EMA y d\u00eda, sin ponderar (media 2.862); 847",
  "  hogares fuera del rango de 500 a 6.000 kcal.",
  "- Cobertura de composici\u00f3n, en gramos: hierro 96,9%; zinc y B12 96,6%; folato",
  "  93,4%; vitamina A 92,8%; vitamina D 91,0%; vitamina E 85,3%.",
  "- Veh\u00edculos: arroz 85,5% de los hogares y 218 g por EMA y d\u00eda; trigo en",
  "  equivalentes de harina 91,8% y 46,9 g; az\u00facar 76,9% y 55,7 g.",
  "",
  "| Escenario | Folato mediano | Hierro mediano | Folato Q5/Q1 | Fol. bajo req. | Hierro 10% | Zinc | B12 | Vit. A |",
  "|---|---|---|---|---|---|---|---|---|",
  "| Sin fortificaci\u00f3n | 196 | 8,68 | 1,23 | 73,1 | 76,1 | 42,9 | 46,3 | 74,7 |",
  "| Norma, harina y pan (l\u00ednea base) | 267 | 9,96 | 1,24 | 60,2 | 71,1 | 42,9 | 46,3 | 74,7 |",
  "| Norma, todos los derivados | 328 | 11,02 | 1,21 | 48,3 | 66,4 | 42,9 | 46,3 | 74,7 |",
  "| Norma y az\u00facar | 328 | 11,02 | 1,21 | 48,3 | 66,4 | 42,9 | 46,3 | 35,1 |",
  "| OMS harina, menos de 75 g | 535 | 11,24 | 1,25 | 24,9 | 65,5 | 20,5 | 20,3 | 44,5 |",
  "| Norma y arroz (propuesta) | 884 | 15,49 | 1,03 | 12,6 | 47,5 | 20,6 | 18,3 | 74,7 |",
  "",
  "Columnas 5 a 9: hogares bajo el requerimiento (%). \u00c1cido f\u00f3lico a\u00f1adido sobre el",
  "l\u00edmite superior: 8,0% con arroz; 1,5% con OMS; menos de 0,2% con la norma.",
  "Provincia: 56 de 256 celdas con precisi\u00f3n baja; regi\u00f3n, zona y quintil, ninguna.",
  "",
  "**Verificaci\u00f3n en punto de venta (2026-10-04).** Un establecimiento, un d\u00eda.",
  "El az\u00facar no declara vitamina A (norma no aplicada). El arroz Bison\u00f3 se vende",
  "fortificado con los siete nutrientes y niveles de la propuesta nacional. La",
  "harina de trigo declara hierro, tiamina, riboflavina, niacina y \u00e1cido f\u00f3lico,",
  "sin vitamina A. La sal declara yodo 20-50 ppm y fl\u00faor 200-250 ppm. El cubo de",
  "caldo declara \"sal\" sin indicar si es yodada.",
  "",
  "**Pendiente al cierre:** revisi\u00f3n de la agrupaci\u00f3n de alimentos (A4a, C4);",
  "mapas; valores de referencia definitivos; fuente de las fracciones de harina;",
  "niveles OMS de arroz; consumo promedio de sal; fotos de tomate y colmado;",
  "reescritura del informe y del README antes de fusionar a `main`.",
  ""
)

i_ctrl <- unica(hoja, "(36.840 / 303.408 / 8.774); si la corrida")
hoja$x[i_ctrl] <- sub("(36.840 / 303.408 / 8.774)", "(36.840 / 328.173 / 8.778)", hoja$x[i_ctrl], fixed = TRUE)

hoja$x <- c(hoja$x[seq_len(i_b1 - 1)], b1, hoja$x[-seq_len(i_b1)])
hoja$x <- c(hoja$x[seq_len(i_fa - 1)], vigentes, hoja$x[i_fa:length(hoja$x)])

# 2. Parametros normativos -------------------------------------------------------
cambiar <- function(a, inicio, viejo, nuevo) {
  i <- unica(a, inicio)
  if (!grepl(viejo, a$x[i], fixed = TRUE)) stop("No se encontro '", viejo, "' en la fila ", inicio, call. = FALSE)
  a$x[i] <- sub(viejo, nuevo, a$x[i], fixed = TRUE)
  a
}
ETIQUETA <- " Etiqueta observada en punto de venta el 2026-10-04."
for (n in c("hierro", "zinc", "tiamina", "niacina", "piridoxina", "acido_folico", "vitamina_b12")) {
  par <- cambiar(par, paste0("Arroz;", n, ";"), "tomado_de_presentacion",
                 "concordante_con_etiqueta_de_arroz_fortificado")
}
par <- cambiar(par, "Harina de trigo;vitamina_a;", "discrepancia;", "descartada;")
i <- unica(par, "Harina de trigo;vitamina_a;")
par$x[i] <- paste0(par$x[i], " La etiqueta de harina de trigo no declara vitamina A.")
i <- unica(par, "Az\u00facar;vitamina_a;")
par$x[i] <- paste0(par$x[i], " El az\u00facar en venta no declara vitamina A.", ETIQUETA)
i <- unica(par, "Harina de ma\u00edz;hierro;")
par$x[i] <- paste0(par$x[i], " La etiqueta declara 1 mg por 30 g (unos 33 mg/kg), coherente con el fumarato.", ETIQUETA)

# 3. .gitignore ------------------------------------------------------------------
ign$x <- c(ign$x, "",
           "# Salidas de scripts/diagnostico_*.R (regenerables)",
           "data/diagnosticos/solapamiento_*.csv",
           "data/diagnosticos/hogares_extremos_*.csv")

for (a in list(hoja, par, ign)) escribir(a)
message("Revisar con: git diff")
