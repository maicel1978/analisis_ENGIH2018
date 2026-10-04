# 82_a2_vehiculos.R -- USO UNICO
#
# Bloque A2: harina de maiz, avena y sal como vehiculos de fortificacion.
#   - reports/_comun.R: tres filas nuevas en VEHICULOS.
#   - R1, R2, R3 e informe: las frases que fijaban "cuatro vehiculos" dejan de
#     depender del numero de vehiculos.
#   - Hoja de ruta: A2 marcado como hecho.
#
# Los patrones nuevos se anclan al inicio de la descripcion para no capturar
# derivados: "Galletas de avena", "Aceite de maiz", "Maicena", "Sardinas en
# agua y sal", "Salami", "Salsa".
#
# Si un ancla no aparece exactamente una vez, no se escribe ningun archivo.
#
# Uso: source(here::here("scripts", "82_a2_vehiculos.R"))

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

# Sustituye `viejo` por `nuevo` dentro de la unica linea que contiene `viejo`.
cambiar <- function(a, viejo, nuevo) {
  i <- grep(viejo, a$lineas, fixed = TRUE)
  if (length(i) != 1) {
    stop(basename(a$ruta), ": '", viejo, "' aparece ", length(i),
         " veces (deberia ser 1). No se modifico nada.", call. = FALSE)
  }
  a$lineas[i] <- sub(viejo, nuevo, a$lineas[i], fixed = TRUE)
  a
}

comun   <- leer(here("reports", "_comun.R"))
r1      <- leer(here("reports", "R1_calidad_datos.qmd"))
r2      <- leer(here("reports", "R2_modelo_base.qmd"))
r3      <- leer(here("reports", "R3_cobertura_vehiculos.qmd"))
informe <- leer(here("reports", "INFORME_factibilidad.qmd"))
hoja    <- leer(here("docs", "hoja-de-ruta.md"))

if (any(grepl("Harina de ma", comun$lineas, fixed = TRUE))) {
  stop("El bloque A2 ya esta aplicado: no se modifica nada.", call. = FALSE)
}

# 1. Vehiculos nuevos -----------------------------------------------------------
i <- grep("\"Az\u00facar\",             \"azucar|az\\u00facar\"", comun$lineas, fixed = TRUE)
if (length(i) != 1) stop("No se encontro la fila de azucar en VEHICULOS.", call. = FALSE)
comun$lineas <- c(
  comun$lineas[seq_len(i - 1)],
  paste0(comun$lineas[i], ","),
  "  \"Harina de ma\u00edz\",     \"^harinas? de maiz\",",
  "  \"Avena\",              \"^avena\",",
  "  \"Sal\",                \"^sal (molida|en grano|marina)\"",
  comun$lineas[-seq_len(i)]
)

# 2. Frases que fijaban el numero de vehiculos -----------------------------------
r1 <- cambiar(r1, "## Los cuatro veh\u00edculos de fortificaci\u00f3n",
                  "## Veh\u00edculos de fortificaci\u00f3n")
r2 <- cambiar(r2, "de los cuatro veh\u00edculos de fortificaci\u00f3n.",
                  "de los veh\u00edculos de fortificaci\u00f3n (arroz, aceite y az\u00facar).")
r3 <- cambiar(r3, "lo que indica estimaciones precisas para los cuatro \",",
                  "lo que indica estimaciones precisas para todos los \",")
r3 <- cambiar(r3, "consume **tres de los cuatro veh\u00edculos** (\",",
                  "consume **tres o m\u00e1s veh\u00edculos** (\",")
r3 <- cambiar(r3, "\"**Los cuatro veh\u00edculos a la vez:** \"",
                  "\"**Todos los veh\u00edculos a la vez:** \"")
informe <- cambiar(informe, "que afecta a **tres de los cuatro veh\u00edculos de fortificaci\u00f3n**.",
                            "que afecta a **tres veh\u00edculos de fortificaci\u00f3n: arroz, aceite y az\u00facar**.")

# 3. Hoja de ruta ---------------------------------------------------------------
hoja <- cambiar(hoja, "- [ ] A2. Harina de ma\u00edz, avena y sal como veh\u00edculos.",
                      "- [x] A2. Harina de ma\u00edz, avena y sal como veh\u00edculos.")

for (a in list(comun, r1, r2, r3, informe, hoja)) escribir(a)
message("Revisar con: git diff")
