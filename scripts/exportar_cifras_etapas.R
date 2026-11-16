# exportar_cifras_etapas.R
#
# Cifras de control POR ETAPA de la cadena original, para la prueba de
# aceptacion del paquete hcesfort (tarea A1 de su hoja de ruta; diseno en
# hcesfort/docs/design-adapter-engih.md, seccion 3).
#
# Las seis salidas de guardar_cifras_control.R son el final de la cadena. Si el
# paquete no las reproduce, no dicen en que etapa se separa; y dos errores que
# se compensan pasan. Este script exporta conteos, sumas y medianas de cada
# etapa (01, 03, 04, 05, 06), las comprobaciones que quedaron abiertas en E2 y
# E4, y lo que el adaptador necesita saber de variables que la cadena lee y
# descarta (procedencia, destino, participacion del hogar).
#
# Solo agregados: ninguna salida tiene una fila por hogar o por persona, y las
# tablas por alimento solo llevan conteos y sumas. Se comprueba al final.
#
# Requiere haber corrido 01, 03, 04, 05, 06, 07 y anexo_harina_maiz.R con los
# microdatos en data/raw/. No modifica nada de la cadena ni de data/clean/.
# Depende solo de R base y de readxl.
#
# Uso, desde la raiz del repositorio:
#   Rscript scripts/exportar_cifras_etapas.R
# Salida: data/auditoria/cifras_control/etapas/ (se versiona)

RAIZ    <- Sys.getenv("ENGIH_RAIZ", unset = getwd())
CLEAN   <- file.path(RAIZ, "data", "clean")
RAW     <- file.path(RAIZ, "data", "raw")
DESTINO <- file.path(RAIZ, "data", "auditoria", "cifras_control", "etapas")
MICRODATOS <- c("Registros_Cuestionario_B.xlsx", "Sociodemograficas_e_ingresos.xlsx")
NUTRIENTES <- c("energia_kcal", "hierro_mg", "folato_mcg_dfe", "vitamina_a_mcg_rae",
                "zinc_mg", "vitamina_b12_mcg", "vitamina_d_mcg", "vitamina_e_mg")
UNIDAD_DOCENA  <- 52
UNIDADES_VOLUMEN <- c(5, 7, 21, 32, 57)   # ml, litro, botellon, cc, galon
ID_GUANDU <- 70211088                     # un id de composicion, dos porciones comestibles

leer <- function(nombre) {
  ruta <- file.path(CLEAN, nombre)
  if (!file.exists(ruta)) stop("Falta ", ruta, ". Correr la cadena antes.", call. = FALSE)
  utils::read.table(ruta, sep = ";", dec = ".", header = TRUE, quote = "\"",
                    comment.char = "", na.strings = c("NA", ""),
                    stringsAsFactors = FALSE, check.names = FALSE,
                    fileEncoding = "UTF-8")
}
norm_txt <- function(x) trimws(iconv(tolower(as.character(x)), to = "ASCII//TRANSLIT"))
largo <- function(etapa, ...) {
  v <- c(...)
  data.frame(etapa = etapa, medida = names(v), valor = as.numeric(v), row.names = NULL)
}
cuantiles <- function(x, prefijo) {
  q <- stats::quantile(x, c(0, 0.05, 0.25, 0.5, 0.75, 0.95, 1), na.rm = TRUE, names = FALSE)
  stats::setNames(c(q, mean(x, na.rm = TRUE)),
                  paste0(prefijo, c("_min", "_p05", "_p25", "_mediana", "_p75", "_p95", "_max", "_media")))
}
mediana_ponderada <- function(x, w) {
  ok <- !is.na(x) & !is.na(w)
  x <- x[ok]; w <- w[ok]
  o <- order(x)
  x[o][which(cumsum(w[o]) >= sum(w) / 2)[1]]
}
salidas <- list()
guardar <- function(nombre, tabla) salidas[[nombre]] <<- tabla

# --- Entradas -----------------------------------------------------------------
sec2  <- leer("data_sec2_consumo.csv")
sec3a <- leer("data_sec3a_consumo.csv")
socio <- leer("data_ema_individual.csv")
ema   <- leer("data_ema_hogar.csv")
gramos  <- leer("data_gramos_por_ema.csv")
ingesta <- leer("data_ingesta_micronutrientes_hogar.csv")
comp    <- leer("composicion_unificada.csv")
esc     <- leer("escenarios_ingesta_hogar.csv")
sec2$seccion <- "Sec 2"; sec3a$seccion <- "Sec 3A"
sec2$divisor <- sec2$PM;  sec3a$divisor <- sec3a$PM_real

# --- Etapa 00: archivos de entrada y sesion -----------------------------------
archivos <- c(file.path(RAW, MICRODATOS),
              setdiff(list.files(RAW, full.names = TRUE), file.path(RAW, MICRODATOS)))
archivos <- archivos[file.exists(archivos) & !dir.exists(archivos)]
guardar("e00_entradas", data.frame(
  archivo = basename(archivos), microdato = basename(archivos) %in% MICRODATOS,
  bytes = file.size(archivos), md5 = unname(tools::md5sum(archivos))))

# --- Etapa 01: registros, causas de perdida, unidades -------------------------
por_seccion <- function(d) {
  sin_unidad <- is.na(d$unidad_a_convertir)
  largo(d$seccion[1],
    registros = nrow(d), hogares = length(unique(d$id_hogar_unico)),
    sin_Q = sum(is.na(d$Q)), Q_cero = sum(d$Q == 0, na.rm = TRUE),
    sin_unidad = sum(sin_unidad), sin_unidad_con_fc = sum(sin_unidad & !is.na(d$fc)),
    fc_universal = sum(!is.na(d$fc_universal)),
    fc_especifico = sum(is.na(d$fc_universal) & !is.na(d$fc_especifico)),
    sin_fc = sum(is.na(d$fc)), sin_enhance = sum(is.na(d$enhance_id)),
    sin_edible = sum(is.na(d$edible)),
    con_gramos = sum(!is.na(d$Consumo_diario_g)),
    gramos_cero = sum(d$Consumo_diario_g == 0, na.rm = TRUE),
    atipicos = sum(d$es_outlier %in% TRUE),
    suma_g_dia_comestible = sum(d$Consumo_diario_g, na.rm = TRUE),
    suma_g_dia_comprado = sum(d$Q * d$fc / d$divisor, na.rm = TRUE),
    suma_g_dia_atipicos = sum(d$Consumo_diario_g[d$es_outlier %in% TRUE]))
}
guardar("e01_registros", rbind(por_seccion(sec2), por_seccion(sec3a)))

causas <- function(d) {
  x <- data.frame(seccion = d$seccion, sin_Q = is.na(d$Q), sin_fc = is.na(d$fc),
                  sin_enhance = is.na(d$enhance_id), sin_edible = is.na(d$edible))
  out <- stats::aggregate(list(registros = rep(1L, nrow(x))), x, sum)
  out[order(-out$registros), ]
}
guardar("e01_causas_cruce", rbind(causas(sec2), causas(sec3a)))

descripciones <- function(d) {
  pares <- unique(d[c("id_variedad", "descripcion")])
  largo(d$seccion[1], codigos = length(unique(pares$id_variedad)),
        descripciones = length(unique(pares$descripcion)), pares = nrow(pares),
        codigos_con_varias_descripciones = sum(table(pares$id_variedad) > 1),
        descripciones_con_varios_codigos = sum(table(pares$descripcion) > 1))
}
guardar("e01_descripciones", rbind(descripciones(sec2), descripciones(sec3a)))

docenas <- rbind(sec2[c("seccion", "descripcion", "unidad_a_convertir", "Q", "Consumo_diario_g")],
                 sec3a[c("seccion", "descripcion", "unidad_a_convertir", "Q", "Consumo_diario_g")])
docenas <- docenas[docenas$unidad_a_convertir %in% UNIDAD_DOCENA, ]
guardar("e_e2_docenas", if (nrow(docenas) == 0) {
  data.frame(seccion = NA, descripcion = NA, registros = 0, suma_Q = 0, con_gramos = 0)[0, ]
} else {
  do.call(rbind, lapply(split(docenas, list(docenas$seccion, docenas$descripcion), drop = TRUE),
    function(z) data.frame(seccion = z$seccion[1], descripcion = z$descripcion[1],
                           registros = nrow(z), suma_Q = sum(z$Q, na.rm = TRUE),
                           con_gramos = sum(!is.na(z$Consumo_diario_g)))))
})

volumen <- function(d) {
  v <- d[d$unidad_a_convertir %in% UNIDADES_VOLUMEN, ]
  aceite <- grepl("^aceite", norm_txt(v$descripcion))
  largo(d$seccion[1],
        volumen_registros = nrow(v), volumen_g_dia = sum(v$Consumo_diario_g, na.rm = TRUE),
        aceite_registros = sum(aceite), aceite_g_dia = sum(v$Consumo_diario_g[aceite], na.rm = TRUE))
}
guardar("e_e18_volumen", rbind(volumen(sec2), volumen(sec3a)))

# --- Etapa 03: dias con registro y atipicos -----------------------------------
dias_hogar <- unique(sec3a[c("id_hogar_unico", "dias_observados_hogar")])
dias <- as.data.frame(table(dias = dias_hogar$dias_observados_hogar, useNA = "ifany"),
                      responseName = "hogares")
guardar("e03_dias", dias)
guardar("e03_dia_faltante", largo("Sec 3A", registros_sin_dia = sum(is.na(sec3a$dia)),
  hogares_con_dia_faltante = length(unique(sec3a$id_hogar_unico[is.na(sec3a$dia)]))))

atipicos <- function(d) {
  con_g <- !is.na(d$Consumo_diario_g)
  n_filas   <- ave(rep(1, nrow(d)), d$enhance_id, FUN = sum)
  n_valores <- ave(as.numeric(con_g), d$enhance_id, FUN = sum)
  n_filas[is.na(d$enhance_id)] <- NA; n_valores[is.na(d$enhance_id)] <- NA
  marcado <- d$es_outlier %in% TRUE
  largo(d$seccion[1],
    grupos = length(unique(stats::na.omit(d$enhance_id))),
    grupos_evaluados = length(unique(d$enhance_id[!is.na(n_filas) & n_filas >= 20])),
    grupos_20_filas_menos_de_20_valores =
      length(unique(d$enhance_id[!is.na(n_filas) & n_filas >= 20 & n_valores < 20])),
    atipicos = sum(marcado),
    atipicos_en_grupos_con_menos_de_20_valores = sum(marcado & n_valores < 20, na.rm = TRUE),
    atipicos_altos = sum(marcado & d$Consumo_diario_g > stats::median(d$Consumo_diario_g, na.rm = TRUE)),
    atipicos_guandu = sum(marcado & d$enhance_id %in% ID_GUANDU),
    registros_guandu = sum(d$enhance_id %in% ID_GUANDU))
}
guardar("e03_atipicos", rbind(atipicos(sec2), atipicos(sec3a)))

# --- Etapa 04: equivalentes, diseno, regla de agotamiento ---------------------
hog_consumo <- unique(c(sec2$id_hogar_unico, sec3a$id_hogar_unico))
constante <- function(v) {
  sum(tapply(socio[[v]], socio$id_hogar_unico, function(z) length(unique(z)) > 1))
}
upm_estrato <- unique(ema[c("estrato", "upm")])
guardar("e04_afe", rbind(
  largo("personas", personas = nrow(socio), sin_edad = sum(is.na(socio$edad)),
        sin_sexo = sum(!socio$sexo %in% c(1, 2)), sin_ema = sum(is.na(socio$EMA_individual)),
        edad_0_hombres = sum(socio$edad < 1 & socio$sexo %in% 1, na.rm = TRUE),
        edad_0_mujeres = sum(socio$edad < 1 & socio$sexo %in% 2, na.rm = TRUE),
        edad_150_o_mas = sum(socio$edad >= 150, na.rm = TRUE)),
  largo("hogares", hogares = nrow(ema), con_miembro_sin_ema = sum(ema$n_sin_ema > 0),
        ema_cero = sum(ema$EMA_hogar == 0), hogares_con_edad_0 =
          length(unique(socio$id_hogar_unico[socio$edad < 1 & !is.na(socio$edad)])),
        suma_ema = sum(ema$EMA_hogar), suma_miembros = sum(ema$n_miembros),
        suma_pesos = sum(ema$factor_expansion),
        con_registros_y_sin_modulo = sum(!hog_consumo %in% ema$id_hogar_unico),
        sin_registros = sum(!ema$id_hogar_unico %in% hog_consumo),
        cuantiles(ema$EMA_hogar, "ema")),
  largo("diseno", estratos = length(unique(ema$estrato)), upm = nrow(upm_estrato),
        upm_en_varios_estratos = sum(table(upm_estrato$upm) > 1),
        hogares_estrato_no_constante = constante("estrato"),
        hogares_upm_no_constante = constante("upm"),
        hogares_peso_no_constante = constante("factor_expansion"),
        hogares_quintil_no_constante = constante("quintil"))))

guardar("e04_gramos_por_ema", do.call(rbind, lapply(split(gramos, gramos$seccion), function(z)
  largo(z$seccion[1], registros = nrow(z), hogares = length(unique(z$id_hogar_unico)),
        almacenados = sum(z$almacenado), hogares_con_almacenado =
          length(unique(z$id_hogar_unico[z$almacenado])),
        suma_g_ema_dia = sum(z$Gramos_por_EMA_dia),
        suma_g_ema_dia_almacenado = sum(z$Gramos_por_EMA_dia[z$almacenado])))))
guardar("e04_agotamiento", largo("Sec 2", registros_sin_cantidad_final = sum(is.na(sec2$cantidad_final)),
  registros_cantidad_final_positiva = sum(sec2$cantidad_final > 0, na.rm = TRUE),
  hogares_sin_ningun_registro_usado = sum(!ema$id_hogar_unico %in% gramos$id_hogar_unico[!gramos$almacenado])))

# --- Etapa 05: ingesta por variante, cobertura por nutriente ------------------
ingesta <- merge(ingesta, ema[c("id_hogar_unico", "EMA_hogar", "factor_expansion")],
                 by = "id_hogar_unico", all.x = TRUE)
guardar("e05_ingesta", do.call(rbind, lapply(split(ingesta, ingesta$variante), function(z)
  do.call(rbind, lapply(NUTRIENTES, function(n) data.frame(
    variante = z$variante[1], nutriente = n, hogares = nrow(z),
    mediana = stats::median(z[[n]]), media = mean(z[[n]]),
    mediana_ponderada = mediana_ponderada(z[[n]], z$factor_expansion),
    media_ponderada = stats::weighted.mean(z[[n]], z$factor_expansion),
    total_hogar_dia = sum(z[[n]] * z$EMA_hogar),
    energia_plausible = sum(z$energia_plausible), sobre_6000 = sum(z$energia_kcal > 6000),
    bajo_500 = sum(z$energia_kcal < 500), row.names = NULL))))))

usados <- merge(gramos[!gramos$almacenado, ], comp, by = "enhance_id", all.x = TRUE)
guardar("e05_cobertura", do.call(rbind, lapply(NUTRIENTES, function(n) data.frame(
  nutriente = n, registros = nrow(usados), registros_sin_valor = sum(is.na(usados[[n]])),
  alimentos_sin_valor = length(unique(usados$enhance_id[is.na(usados[[n]])])),
  pct_gramos_con_valor = 100 * sum(usados$Gramos_por_EMA_dia[!is.na(usados[[n]])]) /
    sum(usados$Gramos_por_EMA_dia)))))

# --- Etapa 06: vehiculos y escenarios -----------------------------------------
vehiculos <- utils::read.table(file.path(RAW, "vehiculos_escenarios.csv"), sep = ";", header = TRUE,
                               na.strings = c("NA", ""), stringsAsFactors = FALSE, fileEncoding = "UTF-8")
vehiculos <- rbind(vehiculos[c("vehiculo", "patron", "excluir")],
                   data.frame(vehiculo = "Harina de maiz (anexo)", patron = "^harinas? de maiz", excluir = "dulce"))
asignar_vehiculo <- function(descripcion) {
  d <- norm_txt(descripcion); v <- rep(NA_character_, length(d))
  for (i in seq_len(nrow(vehiculos))) {
    hit <- grepl(vehiculos$patron[i], d) & is.na(v)
    if (!is.na(vehiculos$excluir[i])) hit <- hit & !grepl(vehiculos$excluir[i], d)
    v[hit] <- vehiculos$vehiculo[i]
  }
  v
}
crudo <- rbind(sec2[c("seccion", "id_hogar_unico", "descripcion", "Q", "fc", "enhance_id", "Consumo_diario_g")],
               sec3a[c("seccion", "id_hogar_unico", "descripcion", "Q", "fc", "enhance_id", "Consumo_diario_g")])
crudo$vehiculo <- asignar_vehiculo(crudo$descripcion)
gramos$vehiculo <- asignar_vehiculo(gramos$descripcion)
guardar("e06_vehiculos", do.call(rbind, lapply(vehiculos$vehiculo, function(v) {
  a <- crudo[crudo$vehiculo %in% v, ]; u <- gramos[gramos$vehiculo %in% v & !gramos$almacenado, ]
  con_g <- tapply(u$Gramos_por_EMA_dia, u$id_hogar_unico, sum)
  data.frame(vehiculo = v, registros = nrow(a), hogares_con_registro = length(unique(a$id_hogar_unico)),
    registros_sin_composicion = sum(is.na(a$enhance_id)), registros_sin_fc = sum(is.na(a$fc)),
    registros_Q_cero = sum(a$Q == 0, na.rm = TRUE), registros_usados = nrow(u),
    hogares_con_gramos = sum(con_g > 0), suma_g_ema_dia = sum(u$Gramos_por_EMA_dia),
    hogares_con_registro_y_sin_gramos =
      sum(!unique(a$id_hogar_unico) %in% names(con_g)[con_g > 0]), row.names = NULL)
})))
guardar("e06_escenarios", stats::aggregate(
  cbind(hogares = 1, base = esc$base, anadido = esc$anadido, ingesta = esc$ingesta) ~
    escenario + nutriente, data = esc, FUN = sum))

# --- Etapa 07: hogares, UPM y estratos de cada conjunto estimado --------------
principal <- ingesta[ingesta$variante == "Sec 2 + Sec 3A", ]
conjunto <- function(nombre, ids) {
  z <- unique(ema[ema$id_hogar_unico %in% ids, c("estrato", "upm")])
  data.frame(conjunto = nombre, hogares = sum(ema$id_hogar_unico %in% ids),
             upm = nrow(z), estratos = length(unique(z$estrato)),
             estratos_con_una_upm = sum(table(z$estrato) == 1))
}
guardar("e07_diseno", rbind(conjunto("marco", ema$id_hogar_unico),
  conjunto("con ingesta", principal$id_hogar_unico),
  conjunto("energia plausible", principal$id_hogar_unico[principal$energia_plausible])))

# --- E4: energia segun los dias con registro ----------------------------------
ancho <- function(variante, nombre) {
  z <- ingesta[ingesta$variante == variante, c("id_hogar_unico", "energia_kcal")]
  names(z)[2] <- nombre; z
}
e4 <- Reduce(function(a, b) merge(a, b, by = "id_hogar_unico", all.x = TRUE),
             list(dias_hogar, ancho("Sec 2 + Sec 3A", "total"), ancho("Sec 3A", "sec3a"),
                  ancho("Sec 2", "sec2"), ema[c("id_hogar_unico", "factor_expansion")]))
guardar("e_e4_energia_por_dias", do.call(rbind, lapply(split(e4, e4$dias_observados_hogar), function(z)
  data.frame(dias = z$dias_observados_hogar[1], hogares = nrow(z),
    hogares_con_ingesta = sum(!is.na(z$total)),
    mediana_total = stats::median(z$total, na.rm = TRUE),
    mediana_sec3a = stats::median(z$sec3a, na.rm = TRUE),
    mediana_sec2 = stats::median(z$sec2, na.rm = TRUE),
    mediana_ponderada_sec3a = mediana_ponderada(z$sec3a, z$factor_expansion),
    p95_sec3a = unname(stats::quantile(z$sec3a, 0.95, na.rm = TRUE)),
    sobre_6000_total = sum(z$total > 6000, na.rm = TRUE),
    sobre_6000_sec3a = sum(z$sec3a > 6000, na.rm = TRUE), row.names = NULL))))

# --- Variables que la cadena lee y descarta (Seccion 3A del Excel) ------------
# Se relee la hoja completa como texto. 01_import.R conserva el orden de las
# filas (solo hace left_join con claves comprobadas), de modo que la fila i del
# Excel es la fila i de data_sec3a_consumo.csv; se comprueba antes de cruzar.
ruta_b <- file.path(RAW, MICRODATOS[1])
if (!file.exists(ruta_b)) stop("Falta ", ruta_b, call. = FALSE)
b <- as.data.frame(readxl::read_excel(ruta_b, sheet = "Cuest. B Sec 3A", col_types = "text",
                                      .name_repair = "minimal"))
names(b) <- gsub("^_|_$", "", gsub("[^a-z0-9]+", "_", tolower(iconv(names(b), to = "ASCII//TRANSLIT"))))
num <- function(col) suppressWarnings(as.numeric(b[[col]]))
stopifnot(nrow(b) == nrow(sec3a),
          identical(paste(b$vivienda, b$hogar, sep = "_"), as.character(sec3a$id_hogar_unico)),
          all(as.character(b$id_variedad) == as.character(sec3a$id_variedad)))
x <- data.frame(vehiculo = asignar_vehiculo(sec3a$descripcion), g = sec3a$Consumo_diario_g,
                quien_pago1 = num("quien_pago1"), establecimiento = b$id_tipo_establecimiento,
                porcentaje_hogar = num("porcentaje_hogar"), destino_negocio = num("destino_negocio"),
                destino_otro_hogar = num("destino_otro_hogar"),
                destino_iglesia_ong = num("destino_iglesia_ong"),
                contenido = num("contenido_empaque_presentacion"),
                fc_especifico = is.na(sec3a$fc_universal) & !is.na(sec3a$fc_especifico))
x$vehiculo[is.na(x$vehiculo)] <- "(ninguno)"
tabla <- function(por) {
  f <- stats::as.formula(paste("cbind(registros, con_gramos, g_dia) ~", paste(por, collapse = " + ")))
  d <- data.frame(x[por], registros = 1, con_gramos = as.numeric(!is.na(x$g)),
                  g_dia = ifelse(is.na(x$g), 0, x$g))
  d[por] <- lapply(d[por], function(v) ifelse(is.na(v), "(falta)", as.character(v)))
  stats::aggregate(f, data = d, FUN = sum)
}
guardar("e_procedencia", tabla(c("vehiculo", "quien_pago1")))
guardar("e_establecimiento", tabla(c("vehiculo", "establecimiento")))
pct <- x$porcentaje_hogar
guardar("e_participacion", largo("Sec 3A",
  sin_porcentaje = sum(is.na(pct)), porcentaje_100 = sum(pct == 100, na.rm = TRUE),
  porcentaje_menor_100 = sum(pct < 100, na.rm = TRUE), porcentaje_cero = sum(pct == 0, na.rm = TRUE),
  porcentaje_fuera_de_rango = sum(pct < 0 | pct > 100, na.rm = TRUE),
  g_dia_total = sum(x$g, na.rm = TRUE),
  g_dia_si_se_aplicara = sum(x$g * ifelse(is.na(pct), 1, pct / 100), na.rm = TRUE),
  destino_negocio = sum(x$destino_negocio == 1, na.rm = TRUE),
  g_dia_destino_negocio = sum(x$g[x$destino_negocio %in% 1], na.rm = TRUE),
  destino_otro_hogar = sum(x$destino_otro_hogar == 1, na.rm = TRUE),
  destino_iglesia_ong = sum(x$destino_iglesia_ong == 1, na.rm = TRUE),
  fc_especifico_con_contenido_declarado = sum(x$fc_especifico & !is.na(x$contenido)),
  fc_especifico_sin_contenido_declarado = sum(x$fc_especifico & is.na(x$contenido))))

# --- Guardar ------------------------------------------------------------------
dir.create(DESTINO, recursive = TRUE, showWarnings = FALSE)
for (nombre in names(salidas)) {
  if (any(grepl("id_hogar|vivienda|miembro", names(salidas[[nombre]]), ignore.case = TRUE))) {
    stop(nombre, " contiene identificadores de hogar: no se guarda nada.", call. = FALSE)
  }
}
for (nombre in names(salidas)) {
  utils::write.table(salidas[[nombre]], file.path(DESTINO, paste0(nombre, ".csv")), sep = ";",
                     dec = ".", row.names = FALSE, quote = TRUE, fileEncoding = "UTF-8")
}
commit <- tryCatch(suppressWarnings(system2("git", c("-C", shQuote(RAIZ), "rev-parse", "--short", "HEAD"),
                                             stdout = TRUE, stderr = FALSE)),
                   error = function(e) character())
if (length(commit) != 1) commit <- "sin repositorio git"
writeLines(c(paste("Generado:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
             paste("Commit:", commit), "", utils::capture.output(utils::sessionInfo())),
           file.path(DESTINO, "LEEME.txt"))
message(length(salidas), " tablas agregadas en ", DESTINO)
