# 79_b2_regla_agotamiento.R -- USO UNICO
#
# Bloque B2: regla de agotamiento como estimacion principal.
#
# Si al dia 8 el hogar conserva existencia inicial de un alimento almacenable
# (Seccion 2), las adquisiciones de ese alimento durante la semana (Seccion 3A)
# se consideran almacenadas y no entran al consumo.
#
#   - 04_equivalente_adulto.R: marca esas filas con `almacenado` (no las borra).
#   - 05_ingesta_micronutrientes.R: la variante "Sec 2 + Sec 3A" aplica la
#     regla; la suma simple se conserva como variante de sensibilidad.
#   - reports/_comun.R: cargar_gramos_por_ema() excluye las filas almacenadas.
#   - Hoja de ruta: B2 hecho, con la correccion sobre la disponibilidad neta.
#
# Si un ancla no aparece exactamente una vez, no se escribe ningun archivo.
#
# Uso: source(here::here("scripts", "79_b2_regla_agotamiento.R"))

library(here)

leer <- function(ruta) {
  bytes <- readBin(ruta, "raw", file.info(ruta)$size)
  list(ruta = ruta,
       fin = if (any(bytes == as.raw(13))) "\r\n" else "\n",
       lineas = readLines(ruta, encoding = "UTF-8", warn = FALSE))
}

escribir <- function(a) {
  con <- file(a$ruta, "wb")
  writeLines(enc2utf8(a$lineas), con, sep = a$fin, useBytes = TRUE)
  close(con)
  message("Actualizado: ", a$ruta)
}

# Sustituye las lineas [inicio, fin] por `nuevo`. `inicio` debe ser igual a
# una sola linea (sin contar espacios); `fin`, si se da, es la primera linea
# exactamente igual a `fin` desde `inicio`.
reemplazar <- function(a, inicio, nuevo, fin = NULL) {
  i <- which(trimws(a$lineas) == inicio)
  if (length(i) != 1) {
    stop(basename(a$ruta), ": '", inicio, "' aparece ", length(i),
         " veces (deberia ser 1). No se modifico nada.", call. = FALSE)
  }
  j <- i
  if (!is.null(fin)) {
    j <- i - 1 + which(a$lineas[i:length(a$lineas)] == fin)[1]
    if (is.na(j)) stop("No se encontro el cierre '", fin, "'.", call. = FALSE)
  }
  a$lineas <- c(a$lineas[seq_len(i - 1)], nuevo, a$lineas[-seq_len(j)])
  a
}

s04   <- leer(here("scripts", "04_equivalente_adulto.R"))
s05   <- leer(here("scripts", "05_ingesta_micronutrientes.R"))
comun <- leer(here("reports", "_comun.R"))
hoja  <- leer(here("docs", "hoja-de-ruta.md"))

if (any(grepl("almacenado", c(s04$lineas, s05$lineas, comun$lineas), fixed = TRUE))) {
  stop("El bloque B2 ya esta aplicado: no se modifica nada.", call. = FALSE)
}

# 1. 04: marcar adquisiciones almacenadas --------------------------------------
s04 <- reemplazar(s04, "mutate(Gramos_por_EMA_dia = Consumo_diario_g / EMA_hogar)", c(
  "  mutate(Gramos_por_EMA_dia = Consumo_diario_g / EMA_hogar)",
  "",
  "# Regla de agotamiento ---------------------------------------------------",
  "# La pregunta 9 de la Seccion 2 mide lo consumido del inventario inicial, y",
  "# el inventario final no incluye lo comprado en la semana. La suma de ambas",
  "# secciones cuenta por tanto como consumo las compras que quedaron guardadas.",
  "#",
  "# Regla: si al dia 8 el hogar conserva existencia inicial de un alimento",
  "# almacenable, lo adquirido de ese alimento en la semana se marca como",
  "# almacenado. Las filas se conservan; quien las usa decide si las incluye.",
  "#",
  "# Solo alimentos no perecederos presentes en ambas secciones. Los patrones se",
  "# aplican sobre la descripcion en minusculas y sin acentos.",
  "CLAVES_ALMACENABLES <- tribble(",
  "  ~clave,                  ~patron_sec2,              ~patron_sec3a,",
  "  \"Arroz\",                 \"^arroz\",                  \"^arroz\",",
  "  \"Aceite\",                \"^aceite\",                 \"^aceite\",",
  "  \"Azucar\",                \"^azucar\",                 \"^azucar (morena|blanca)\",",
  "  \"Habichuelas secas\",     \"^habichuelas sueltas\",    \"^habichuelas .*secas\",",
  "  \"Habichuelas enlatadas\", \"^habichuelas enlatadas\",  \"^habichuelas? .*(enlatadas|en lata)\",",
  "  \"Leche liquida\",         \"^leche liquida\",          \"^leche .*liquida|^leche fresca\",",
  "  \"Leche en polvo\",        \"^leche en polvo\",         \"^leche en polvo\",",
  "  \"Harina de maiz\",        \"^harina de maiz\",         \"^harinas? de maiz\",",
  "  \"Avena\",                 \"^avena\",                  \"^avena\",",
  "  \"Pastas\",                \"spaguetti\",               \"^spaghetti|^fideos|^coditos|^macarrones|^espirales\",",
  "  \"Galletas saladas\",      \"^galletas saladas\",       \"^galletas (saladas|de soda)\",",
  "  \"Galletas dulces\",       \"^galletas dulces\",        \"^galletas dulces\",",
  "  \"Salami\",                \"^salami\",                 \"^salami\",",
  "  \"Chocolate\",             \"^chocolate\",              \"^chocolate en|^cocoa\",",
  "  \"Sardinas\",              \"^sardinas\",               \"^sardinas en\",",
  "  \"Atun\",                  \"^atun\",                   \"^atun en\"",
  ")",
  "",
  "asignar_clave <- function(descripcion, patrones) {",
  "  d <- trimws(iconv(tolower(as.character(descripcion)), to = \"ASCII//TRANSLIT\"))",
  "  clave <- rep(NA_character_, length(d))",
  "  for (i in seq_len(nrow(CLAVES_ALMACENABLES))) {",
  "    clave[is.na(clave) & grepl(patrones[i], d)] <- CLAVES_ALMACENABLES$clave[i]",
  "  }",
  "  clave",
  "}",
  "",
  "if (!\"cantidad_final\" %in% names(consumo_sec2)) {",
  "  stop(\"`data_sec2_consumo.csv` no tiene `cantidad_final`. Volver a correr 01 y 03.\",",
  "       call. = FALSE)",
  "}",
  "",
  "existencia_restante <- consumo_sec2 |>",
  "  mutate(clave = asignar_clave(descripcion, CLAVES_ALMACENABLES$patron_sec2)) |>",
  "  filter(!is.na(clave)) |>",
  "  group_by(id_hogar_unico, clave) |>",
  "  summarise(existencia_final = sum(cantidad_final), .groups = \"drop\") |>",
  "  filter(existencia_final > 0) |>",
  "  transmute(id_hogar_unico, clave, almacenado = TRUE)",
  "",
  "gramos_por_ema <- gramos_por_ema |>",
  "  mutate(clave = if_else(",
  "    seccion == \"Sec 3A\",",
  "    asignar_clave(descripcion, CLAVES_ALMACENABLES$patron_sec3a),",
  "    NA_character_",
  "  )) |>",
  "  left_join(existencia_restante, by = c(\"id_hogar_unico\", \"clave\")) |>",
  "  mutate(almacenado = coalesce(almacenado, FALSE)) |>",
  "  select(-clave)",
  "",
  "message(",
  "  \"Regla de agotamiento -- adquisiciones marcadas como almacenadas: \",",
  "  sum(gramos_por_ema$almacenado), \" filas en \",",
  "  n_distinct(gramos_por_ema$id_hogar_unico[gramos_por_ema$almacenado]), \" hogares\"",
  ")"
))

# 2. 05: la variante principal aplica la regla ---------------------------------
s05 <- reemplazar(s05,
  "agregar_por_hogar(consumo_nutrientes,                                \"Sec 2 + Sec 3A\")", c(
  "  # Estimacion principal: suma de secciones con la regla de agotamiento.",
  "  agregar_por_hogar(consumo_nutrientes |> filter(!almacenado),         \"Sec 2 + Sec 3A\"),",
  "  # Sensibilidad: suma simple, sin la regla.",
  "  agregar_por_hogar(consumo_nutrientes,                                \"Sec 2 + Sec 3A, sin regla de agotamiento\")"
))
s05 <- reemplazar(s05, "if (!\"seccion\" %in% names(consumo_nutrientes)) {", c(
  "if (!\"almacenado\" %in% names(consumo_nutrientes)) {",
  "  stop(\"Falta la columna `almacenado`. Volver a correr 04_equivalente_adulto.R.\",",
  "       call. = FALSE)",
  "}",
  "if (!\"seccion\" %in% names(consumo_nutrientes)) {"
))

# 3. _comun.R: los reportes leen la estimacion principal -----------------------
comun <- reemplazar(comun, "cargar_gramos_por_ema <- function() {", fin = "}", nuevo = c(
  "# Por defecto excluye las adquisiciones marcadas como almacenadas por la regla",
  "# de agotamiento; `incluir_almacenado = TRUE` devuelve la suma simple.",
  "cargar_gramos_por_ema <- function(incluir_almacenado = FALSE) {",
  "  f <- file.path(RUTA_CLEAN, \"data_gramos_por_ema.csv\")",
  "  exigir_archivo(f, \"04_equivalente_adulto.R\")",
  "  d <- leer_limpio(f)",
  "  faltan <- setdiff(c(\"seccion\", \"almacenado\"), names(d))",
  "  if (length(faltan) > 0) {",
  "    stop(\"`data_gramos_por_ema.csv` no tiene: \", paste(faltan, collapse = \", \"),",
  "         \". Volver a correr scripts/04_equivalente_adulto.R.\", call. = FALSE)",
  "  }",
  "  if (!incluir_almacenado) d <- d |> filter(!almacenado)",
  "  d",
  "}"
))

# 4. Hoja de ruta ---------------------------------------------------------------
hoja <- reemplazar(hoja,
  "- [ ] B2. Disponibilidad neta en almacenables, como cuarta variante.", c(
  "- [x] B2. Regla de agotamiento adoptada como estimaci\u00f3n principal (2026-10-04).",
  "      La disponibilidad neta prevista no aplica: la pregunta 9 de la Secci\u00f3n 2",
  "      es inventario inicial menos final en el 98,3% de las filas y el",
  "      inventario final no incluye las compras de la semana, de modo que",
  "      `inicial + adquisiciones - final` es la suma que ya se calculaba.",
  "      Regla: si al d\u00eda 8 queda existencia inicial de un alimento almacenable,",
  "      lo adquirido esa semana se marca como almacenado y no se cuenta.",
  "      Efecto (sin ponderar): energ\u00eda mediana 2.153 a 2.118 kcal; media 2.755 a",
  "      2.667; hogares sobre 6.000 kcal 572 a 509; bajo 500 kcal 296 a 297.",
  "      Gramos excluidos: aceite 13,4%; pastas 9,7%; az\u00facar 9,0%; arroz 6,5%.",
  "      La suma simple se conserva como variante de sensibilidad."
))

for (a in list(s04, s05, comun, hoja)) escribir(a)
message("Revisar con: git diff")
