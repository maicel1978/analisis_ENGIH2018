# 72_ordenar_fotos_campo.R -- USO UNICO
#
# Copia las fotos del trabajo de campo del 2026-10-04 desde output/ (carpeta
# que git ignora y que Quarto reescribe) a media/fotos_investigacion_mercado/,
# con nombres normalizados, y escribe el registro de la verificacion en
# data/auditoria/.
#
# No copia las fotos que ya estaban en el repositorio ni las dos que pueden
# mostrar a terceros (tomate y colmado): esas se revisan a mano.
# No borra nada de output/.
#
# Uso: source(here::here("scripts", "72_ordenar_fotos_campo.R"))

library(here)

origen  <- here("output", "media", "fotos_investigacion_mercado")
destino <- here("media", "fotos_investigacion_mercado")

renombrar <- c(
  "agacate01.jpeg"             = "aguacate01.jpg",
  "aji_gustoso01.jpeg"         = "aji_gustoso01.jpg",
  "apio01.jpeg"                = "apio01.jpg",
  "arroz_bisono01.jpeg"        = "arroz_bisono01.jpg",
  "arroz_bisono02.jpeg"        = "arroz_bisono02.jpg",
  "arroz_campos01.jpeg"        = "arroz_campos01.jpg",
  "arroz_campos02.jpeg"        = "arroz_campos02.jpg",
  "arroz_campos03.jpeg"        = "arroz_campos03.jpg",
  "arroz_selecto_lider01.jpeg" = "arroz_selecto_lider01.jpg",
  "arroz_selecto_lider02.jpeg" = "arroz_selecto_lider02.jpg",
  "avena_americana01.jpeg"     = "avena_americana01.jpg",
  "avena_americana02.jpeg"     = "avena_americana02.jpg",
  "avena_americana03.jpeg"     = "avena_americana03.jpg",
  "avena_lider01.jpeg"         = "avena_lider01.jpg",
  "avena_lider02.jpeg"         = "avena_lider02.jpg",
  "avena_quaker01.jpeg"        = "avena_quaker01.jpg",
  "avena_quaker02..jpeg"       = "avena_quaker02.jpg",
  "azucar_lider01.jpeg"        = "azucar_lider01.jpg",
  "azucar_lider02.jpeg"        = "azucar_lider02.jpg",
  "azucar_lider03.jpeg"        = "azucar_lider03.jpg",
  "caldito_pollo96.jpeg"       = "caldo_dona_gallina01.jpg",
  "caldito_pollo97.jpeg"       = "caldo_dona_gallina02.jpg",
  "caldito_pollo98.jpeg"       = "caldo_dona_gallina03.jpg",
  "caldito_pollo99.jpeg"       = "caldo_dona_gallina04.jpg",
  "guineo_maduro01.jpeg"       = "guineo_maduro01.jpg",
  "guineo_verde01.jpeg"        = "guineo_verde02.jpg",    # el 01 es de septiembre
  "harina_maiz_lider01.jpeg"   = "harina_maiz_lider01.jpg",
  "harina_maiz_lider02.jpeg"   = "harina_maiz_lider02.jpg",
  "harina_trigo_lider01.jpeg"  = "harina_trigo_lider01.jpg",
  "harina_trigo_lider02.jpeg"  = "harina_trigo_lider02.jpg",
  "naranaja_agria01.jpeg"      = "naranja_agria01.jpg",
  "platano_maduro01.jpeg"      = "platano_maduro01.jpg",
  "platano_verde01.jpeg"       = "platano_verde02.jpg",   # el 01 es de septiembre
  "sal_lider01.jpeg"           = "sal_lider01.jpg",
  "sal_lider02.jpeg"           = "sal_lider02.jpg",
  "sal_linda01.jpeg"           = "sal_linda01.jpg",
  "sal_linda02.jpeg"           = "sal_linda02.jpg",
  "sal_refisal01.jpeg"         = "sal_refisal01.jpg",
  "sal_refisal02.jpeg"         = "sal_refisal02.jpg"
)
REVISAR_A_MANO <- c("tomate_bugalu01.jpeg", "colmado99.jpeg")

faltan <- setdiff(names(renombrar), list.files(origen))
if (length(faltan) > 0) stop("No estan en output/: ", paste(faltan, collapse = ", "), call. = FALSE)
ya <- intersect(unname(renombrar), list.files(destino))
if (length(ya) > 0) stop("Ya existen en media/: ", paste(ya, collapse = ", "), call. = FALSE)

ok <- file.copy(file.path(origen, names(renombrar)), file.path(destino, renombrar))
if (!all(ok)) stop("No se pudieron copiar: ", paste(names(renombrar)[!ok], collapse = ", "), call. = FALSE)
message(sum(ok), " fotos copiadas a media/fotos_investigacion_mercado/")
message("Sin copiar, para revisar a mano (pueden mostrar a terceros): ",
        paste(REVISAR_A_MANO, collapse = ", "))

# Registro de la verificacion ----------------------------------------------------
G_POR_LIBRA <- 453.592
pesaje <- function(producto, libras, unidad, fotos, cargado, nota = "") {
  data.frame(tipo = "pesaje", producto = producto, marca = "", lectura_lb = libras,
             unidades = 5, unidad_pesada = unidad,
             g_por_unidad = round(libras * G_POR_LIBRA / 5),
             observacion = nota, cargado_al_pipeline = cargado, fotos = fotos)
}
etiqueta <- function(producto, marca, observacion, fotos) {
  data.frame(tipo = "etiqueta", producto = producto, marca = marca, lectura_lb = NA,
             unidades = NA, unidad_pesada = "", g_por_unidad = NA,
             observacion = observacion, cargado_al_pipeline = "", fotos = fotos)
}

registro <- rbind(
  pesaje("Pl\u00e1tano verde",  2.30, "unidad", "platano_verde02.jpg", "si"),
  pesaje("Pl\u00e1tano maduro", 2.20, "unidad", "platano_maduro01.jpg", "si"),
  pesaje("Guineo verde",   1.96, "unidad", "guineo_verde02.jpg", "si"),
  pesaje("Guineo maduro",  1.54, "unidad", "guineo_maduro01.jpg", "si"),
  pesaje("Aguacate",       5.12, "unidad", "aguacate01.jpg", "si"),
  pesaje("Tomate bugal\u00fa",  1.40, "unidad", "pendiente de recorte", "si"),
  pesaje("Naranja agria",  1.20, "unidad", "naranja_agria01.jpg", "si"),
  pesaje("Aj\u00ed gustoso",    0.40, "paquete", "aji_gustoso01.jpg", "no",
         "La encuesta registra aj\u00edes sueltos; falta el n\u00famero de aj\u00edes por paquete."),
  pesaje("Apio",           5.12, "paquete", "apio01.jpg", "no",
         "La encuesta registra tallo, atado y ramita; falta el peso de un tallo."),
  pesaje("Aj\u00ed cubanela",   1.44, "unidad", "aji_cubanela02.jpg", "si",
         "Pesaje del 2026-09-09. Corrige el factor de 288 g, calculado con la lectura en kilogramos."),
  etiqueta("Az\u00facar refino", "L\u00edder",
           "No declara vitamina A; ingrediente \u00fanico: az\u00facar. \u00danica marca disponible en el establecimiento.",
           "azucar_lider01.jpg; azucar_lider02.jpg; azucar_lider03.jpg"),
  etiqueta("Harina de ma\u00edz", "L\u00edder",
           "Declara fortificaci\u00f3n con hierro, vitaminas A, B1, B2, B6 y E, \u00e1cido f\u00f3lico, \u00e1cido pantot\u00e9nico y niacina.",
           "harina_maiz_lider01.jpg; harina_maiz_lider02.jpg"),
  etiqueta("Harina de trigo", "L\u00edder",
           "Enriquecida con hierro, tiamina, riboflavina, niacina y \u00e1cido f\u00f3lico. Sin vitamina A.",
           "harina_trigo_lider01.jpg; harina_trigo_lider02.jpg"),
  etiqueta("Sal refinada", "L\u00edder",
           "Yodada y fluorada; declara yodo 20-50 ppm y fl\u00faor 200-250 ppm.",
           "sal_lider01.jpg; sal_lider02.jpg"),
  etiqueta("Sal", "Linda", "Yodada y fluorada, seg\u00fan observaci\u00f3n en el establecimiento. Etiqueta por transcribir.",
           "sal_linda01.jpg; sal_linda02.jpg"),
  etiqueta("Sal", "Refisal", "Yodada y fluorada, seg\u00fan observaci\u00f3n en el establecimiento. Etiqueta por transcribir.",
           "sal_refisal01.jpg; sal_refisal02.jpg"),
  etiqueta("Arroz", "Bison\u00f3",
           "Fortificado con B1, B3, B6, B12, \u00e1cido f\u00f3lico, zinc y hierro.",
           "arroz_bisono01.jpg; arroz_bisono02.jpg"),
  etiqueta("Arroz", "Campos",
           "Se vende como fortificado; la tabla nutricional declara hierro y zinc. Niveles por transcribir.",
           "arroz_campos01.jpg; arroz_campos02.jpg; arroz_campos03.jpg"),
  etiqueta("Arroz selecto", "L\u00edder", "Etiqueta por transcribir.",
           "arroz_selecto_lider01.jpg; arroz_selecto_lider02.jpg"),
  etiqueta("Avena integral", "Quaker",
           "Declara 15 mg de hierro por porci\u00f3n de 40 g con hojuelas de avena como \u00fanico ingrediente: inconsistencia por aclarar.",
           "avena_quaker01.jpg; avena_quaker02.jpg"),
  etiqueta("Avena instant\u00e1nea", "L\u00edder", "Sin fortificaci\u00f3n declarada.",
           "avena_lider01.jpg; avena_lider02.jpg"),
  etiqueta("Avena en hojuelas", "Avena Americana", "Sin fortificaci\u00f3n declarada. Etiqueta por transcribir.",
           "avena_americana01.jpg; avena_americana02.jpg; avena_americana03.jpg"),
  etiqueta("Caldo de gallina en tabletas", "Do\u00f1a Gallina",
           "Ingrediente \"Sal\", sin indicar si es yodada. Sodio: 520 mg por cuarto de tableta (2,75 g). Fabricante: Quala Dominicana.",
           "caldo_dona_gallina01.jpg; caldo_dona_gallina02.jpg; caldo_dona_gallina03.jpg; caldo_dona_gallina04.jpg")
)
registro$fecha <- ifelse(registro$producto == "Aj\u00ed cubanela", "2026-09-09", "2026-10-04")
registro$nota_metodo <- "Un establecimiento, un d\u00eda. La balanza marca libras; pendiente de comprobar con un peso conocido."

salida <- here("data", "auditoria", "verificacion_punto_venta_2026-10-04.csv")
con <- file(salida, "wb")
write.table(registro, con, sep = ";", row.names = FALSE, na = "", fileEncoding = "UTF-8", qmethod = "double")
close(con)
message("Registro escrito: data/auditoria/verificacion_punto_venta_2026-10-04.csv (", nrow(registro), " filas)")
