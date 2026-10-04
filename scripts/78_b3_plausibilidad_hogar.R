# 78_b3_plausibilidad_hogar.R -- USO UNICO
#
# Bloque B3: plausibilidad de la energia a nivel de hogar.
#
#   - 05_ingesta_micronutrientes.R: columna `energia_plausible` por hogar
#     (500 a 6.000 kcal por EMA y dia). Se marca; no se excluye por defecto.
#   - 05 y 03: comentarios y mensajes que seguian dando por pendiente el
#     tratamiento de las dos secciones.
#   - Hoja de ruta: B3 hecho, con la evidencia de la decision.
#
# No cambia ninguna cifra existente.
# Si un ancla no aparece exactamente una vez, no se escribe ningun archivo.
#
# Uso: source(here::here("scripts", "78_b3_plausibilidad_hogar.R"))

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

# Sustituye por `nuevo` las `n` lineas que empiezan en la unica linea igual a
# `inicio` (sin contar espacios al inicio o al final).
reemplazar <- function(a, inicio, nuevo, n = 1) {
  i <- which(trimws(a$lineas) == inicio)
  if (length(i) != 1) {
    stop(basename(a$ruta), ": '", inicio, "' aparece ", length(i),
         " veces (deberia ser 1). No se modifico nada.", call. = FALSE)
  }
  a$lineas <- c(a$lineas[seq_len(i - 1)], nuevo, a$lineas[-seq_len(i + n - 1)])
  a
}

s03  <- leer(here("scripts", "03_transform.R"))
s05  <- leer(here("scripts", "05_ingesta_micronutrientes.R"))
hoja <- leer(here("docs", "hoja-de-ruta.md"))

if (any(grepl("energia_plausible", s05$lineas, fixed = TRUE))) {
  stop("El bloque B3 ya esta aplicado: no se modifica nada.", call. = FALSE)
}

# 1. 05: marca de plausibilidad -------------------------------------------------
s05 <- reemplazar(s05, n = 2,
  inicio = "agregar_por_hogar(consumo_nutrientes,                                \"Sec 2 + Sec 3A, sin regla de agotamiento\")",
  nuevo = c(
  "  agregar_por_hogar(consumo_nutrientes,                                \"Sec 2 + Sec 3A, sin regla de agotamiento\")",
  ")",
  "",
  "# Plausibilidad de la energia por hogar. Se marca y no se excluye: los hogares",
  "# sobre el limite superior se concentran en los quintiles altos (2,7% en el",
  "# quintil 1 y 12,1% en el 5), de modo que excluirlos sesgaria las comparaciones",
  "# entre grupos. El filtro se usa solo como analisis de sensibilidad.",
  "LIMITES_ENERGIA <- c(inferior = 500, superior = 6000)  # kcal por EMA y dia",
  "",
  "ingesta_hogar <- ingesta_hogar |>",
  "  mutate(energia_plausible = energia_kcal >= LIMITES_ENERGIA[[\"inferior\"]] &",
  "           energia_kcal <= LIMITES_ENERGIA[[\"superior\"]])"
))

s05 <- reemplazar(s05,
  "# Paso 5: ingesta aparente por hogar, en tres variantes --------------------",
  "# Paso 5: ingesta aparente por hogar, en cuatro variantes ------------------")
s05 <- reemplazar(s05, n = 2,
  inicio = "# El tratamiento aplicable es una decision del equipo tecnico. Se producen las",
  nuevo = c(
  "# La estimacion principal es la suma con la regla de agotamiento (04). Las",
  "# demas variantes se conservan para comparacion y sensibilidad."))
s05 <- reemplazar(s05,
  "message(\"\\nComparacion de variantes (el tratamiento aplicable es decision del equipo tecnico):\")",
  c("message(\"\\nComparacion de variantes (principal: Sec 2 + Sec 3A, con regla de agotamiento):\")"))
s05 <- reemplazar(s05, "print(comparacion_variantes)", c(
  "print(comparacion_variantes)",
  "",
  "message(\"\\nHogares segun plausibilidad de la energia (\", LIMITES_ENERGIA[[\"inferior\"]],",
  "        \" a \", LIMITES_ENERGIA[[\"superior\"]], \" kcal por EMA y dia):\")",
  "print(ingesta_hogar |> count(variante, energia_plausible))"
))

# 2. 03: encabezado desactualizado ---------------------------------------------
s03 <- reemplazar(s03, n = 3,
  inicio = "#   - Disponibilidad neta Sec 2 + Sec 3A para alimentos almacenables",
  nuevo = c(
  "#   - Tratamiento del solapamiento entre Sec 2 y Sec 3A en alimentos",
  "#     almacenables. Se resuelve en 04_equivalente_adulto.R con la regla de",
  "#     agotamiento."))

# 3. Hoja de ruta ---------------------------------------------------------------
hoja <- reemplazar(hoja,
  "- [ ] B3. At\u00edpicos a nivel de hogar (despu\u00e9s de B2).", c(
  "- [x] B3. Plausibilidad de la energ\u00eda por hogar (2026-10-04): columna",
  "      `energia_plausible` (500 a 6.000 kcal por EMA y d\u00eda). Se marca y no se",
  "      excluye. Quedan fuera del rango 806 hogares (9,2%): 297 por debajo y 509",
  "      por encima. Los criterios basados en la propia distribuci\u00f3n dan l\u00edmites",
  "      implausibles (3 MAD en logaritmo: 351 a 12.792 kcal). La exclusi\u00f3n no es",
  "      neutra entre grupos: fuera del rango queda el 6,0% del quintil 1 y el",
  "      16,5% del quintil 5, por el extremo superior (2,7% frente a 12,1%); el",
  "      inferior es parejo (3 a 4%). Excluir sesgar\u00eda la comparaci\u00f3n por quintil.",
  "      El riesgo de ingesta inadecuada se reportar\u00e1 con y sin el filtro."))

for (a in list(s03, s05, hoja)) escribir(a)
message("Revisar con: git diff")
