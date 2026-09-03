# Script: 01_import.R (Lectura de datos ENGIH 2018)
# Proyecto: ENGIH 2018 - Consumo de alimentos y nutrición
# Fecha: 2026-09-03
#
# Objetivos:
#
#   1. Importar Encuesta de la ENGIH 2018
#      (Sección 2 y Sección 3A)
#
#   2. Identificar y ensamblar, por registro, las piezas necesarias
#      para el cálculo de consumo (pero SIN calcularlo todavía):
#
#      Q  = Cantidad observada
#      FC = Factor de conversión a gramos
#      PC = Factor de porción comestible (columna EDIBLE de la fuente
#           de composición, ya resuelta en food_factors.xlsx)
#      PM = Período de medición (constante por sección)
#
#   3. Generar datos limpios de trabajo
#
# Salidas de esta etapa
#
#   data/clean/data_sec2.csv
#   data/clean/data_sec3a.csv
#
# NOTA: Esta etapa NO calcula nutrientes ni consumo diario (Q*FC*PC/PM).
#       Esa multiplicación, el control de calidad de outliers (Paso 7 de
#       la guía MIMI/WFP), y la disponibilidad neta para alimentos
#       almacenables compartidos entre Sec 2 y Sec 3A quedan para
#       03_transform.R.
#
# NOTA METODOLÓGICA (ver notas_estrategicas_personales.md):
#   Sec 3A (>700 adquisiciones) es la fuente PRINCIPAL de consumo aparente
#   siguiendo Imhoff-Kunsch (2012). Sec 2 (30 ítems de despensa) no se usa
#   como fuente independiente de consumo -- sirve para calcular
#   disponibilidad neta (inventario_inicial + adquisiciones - inventario_final)
#   en alimentos almacenables (arroz, aceite, azúcar, harina, habichuelas,
#   leche). Ese cruce entre secciones se hace en 03_transform.R, una vez que
#   cada sección esté limpia por separado -- este script las deja listas
#   pero independientes.

# Configuración general ------------------------------------------------
rm(list = ls())   # limpia el entorno
options(stringsAsFactors = FALSE)
# Bibliotecas
library(conflicted)
library(readxl)
library(readr)
library(here)
library(dplyr)
library(janitor)
conflicts_prefer(dplyr::filter)

# Rutas a los ficheros de origen -----------------------------------------
ruta_ENGIH2018    <- here("data", "raw", "Registros_Cuestionario_B.xlsx")
ruta_unidades     <- here("data", "raw", "data_raw_unidades.xlsx")            # FC
ruta_puente       <- here("data", "raw", "crosswalk_tablas_composicion.xlsx") # enhance_id + validado
ruta_tabla_PC     <- here("data", "raw", "food_factors.xlsx")                 # PC (edible)
ruta_tablas_INCAP <- here("data", "raw", "food_composition_INCAP.xlsx")       # nutrientes -> se usan en 05, NO aca
ruta_tablas_FNDDS <- here("data", "raw", "food_composition_FNDDS.xlsx")       # nutrientes -> se usan en 05, NO aca

# Nombres de hoja, compartidos por los 4 ficheros de referencia
hoja_sec2  <- "Cuest. B Sec 2"
hoja_sec3a <- "Cuest. B Sec 3A"

# Periodo de muestreo por diseño (PM)
PM    <- 7  # Alimentos en existencia el día 1 y 8 de la entrevista (inventario)


# Paso 1: Lectura de ENGIH 2018 -------------------------------------------
# 1.1 Sección 2: INVENTARIO INICIAL Y FINAL EN LA DESPENSA Y REFRIGERADOR
sec2_data_raw <- read_excel(ruta_ENGIH2018, sheet = hoja_sec2) |>
  clean_names()
#  $ vivienda                       <dbl>
#  $ hogar                          <dbl>  -- OJO: se repite entre viviendas
#  $ variedad                       <dbl>
#  $ descripcion                    <chr>
#  $ id_unidad_medida_presentacion  <dbl>
#  $ cantidad_unidades_presentacion <dbl>
#  $ contenido_empaque_presentacion <dbl>
#  $ id_unidad_medida               <dbl>
#  $ cantidad_inicial               <dbl>
#  $ cantidad_final                 <dbl>
#  $ consumo_exclusivo_hogar        <dbl>  == Q (pregunta 9)
#  $ factor_anual                   <dbl>

# 1.2 Sección 3A: DETALLE DE LAS ADQUISICIONES DIARIAS
sec3a_data_raw <- read_excel(
  ruta_ENGIH2018,
  sheet = hoja_sec3a,
  col_types = c(
    "text",   # vivienda
    "text",   # hogar
    "guess",  # dia
    "guess",  # orden
    "text",   # id_variedad
    "text",   # descripcion
    "guess",  # cantidad_adquirida (Q)
    "guess",  # id_unidad_medida_presentacion
    "guess",  # cantidad_unidades_presentacion
    "guess",  # contenido_empaque_presentacion
    "text",   # id_unidad_medida
    "guess",  # tamano
    "guess",  # quien_pago1
    "skip",   # columna sin nombre en el Excel fuente (entre quien_pago1 y quien_pago2)
    "skip",   # quien_pago2
    "guess",  # quien_pago2_esp
    "guess",  # como_pago1
    "guess",  # como_pago1_esp
    "guess",  # como_pago2
    "guess",  # como_pago2_esp
    "guess",  # monto_total
    "guess",  # monto_pagado_hogar
    "guess",  # moneda
    "text",   # id_tipo_establecimiento
    "text",   # destino_propio_hogar
    "guess",  # destino_otro_hogar
    "guess",  # destino_iglesia_ong
    "guess",  # destino_negocio
    "guess",  # destino_otro
    "guess",  # porcentaje_hogar
    "guess",  # factor_expansion
    "guess",  # monto_total_mensual
    "guess"   # monto_pagado_hogar_mensual
  ),
  col_names = TRUE
) |>
  clean_names()

# Paso 2: Factores de conversión (FC) -------------------------------------
# Descubierto al probar contra Registros_Cuestionario_B.xlsx real: NO es un
# join simple. Hay tres piezas:
#
#   a) diccionario_conversion: unidades FISICAMENTE exactas (Libra, Onza,
#      Gramos, Litro, Galón, Kilogramos, Quintal, Botellón, cc...), con FC
#      fijo independiente del alimento. Esta es la fuente PRIORITARIA.
#   b) Cuest. B Sec 2 / Sec 3A (este mismo fichero): unidades
#      "Alimento-específico" (Funda, Lata, Pote, Cubito, Saco, Sobre...),
#      donde el peso depende de QUÉ alimento contienen. Solo se usa como
#      respaldo cuando (a) no aplica.
#   c) En el crudo, `ID_UNIDAD_MEDIDA_PRESENTACION` viene vacío en ~59-64%
#      de las filas -- no es un dato faltante, es que el hogar ya reportó
#      en la unidad base (`ID_UNIDAD_MEDIDA`) y no hay capa de "presentación"
#      que convertir. Hay que usar esa columna como respaldo.
#
# OJO -- 15 filas de la hoja Sec 2 (Galón, Litro, Botellón, Libra, Quintal
# por alimento) están 1000x infladas respecto a diccionario_conversion
# (ej. Galón: 3785.41 vs 3,785,410 para ACEITE). Al priorizar la tabla
# universal esas filas nunca se usan, pero convendría corregirlas o
# borrarlas de la fuente para que no muerdan más adelante.
#
# OJO -- la union por alimento en Sec 3A es por texto (`descripcion`), no
# por ID: cualquier diferencia de tildes/mayúsculas rompe el match sin
# avisar. Además, ~168 de las 718 filas de esa hoja tienen texto con
# problemas de codificación (ej. "SazÃ³n" en vez de "Sazón") -- revisalo
# cuando empieces a rellenar esos factores.

# na = "NA" es necesario: al menos la hoja Sec 2 tiene 39 celdas con el
# texto literal "NA" (no vacío real) en id_unidad_medida_presentacion, lo
# que hace que readxl adivine esa columna entera como texto en vez de
# numérica y rompa los left_join() de más abajo por incompatibilidad de
# tipos. Se aplica a las tres lecturas por consistencia, aunque solo Sec 2
# lo necesitaba.
dic_conversion <- read_excel(ruta_unidades, sheet = "diccionario_conversion", na = "NA") |>
  clean_names() |>
  filter(!is.na(fc)) |>
  select(id_unidad_medida_presentacion, fc_universal = fc)

sec2_fc_especifico <- read_excel(ruta_unidades, sheet = hoja_sec2, na = "NA") |>
  clean_names() |>
  filter(!is.na(fc)) |>
  select(variedad, id_unidad_medida_presentacion, fc_especifico = fc)

sec3a_fc_especifico <- read_excel(ruta_unidades, sheet = hoja_sec3a, na = "NA") |>
  clean_names() |>
  filter(!is.na(fc)) |>
  select(descripcion, id_unidad_medida_presentacion, fc_especifico = fc)

# Función compartida: unidad a convertir = presentación si existe, si no la base.
# as.numeric() en ambos lados porque en Sec 3A `id_unidad_medida` se lee como
# "text" (character) mientras que `id_unidad_medida_presentacion` se infiere
# numérico -- coalesce() exige que los dos lados sean del mismo tipo.
resolver_unidad <- function(df) {
  df |> mutate(
    unidad_a_convertir = coalesce(
      as.numeric(id_unidad_medida_presentacion),
      as.numeric(id_unidad_medida)
    )
  )
}

# Paso 3: Puente a tablas de composición (enhance_id) + validación --------
# OJO -- en crosswalk_tablas_composicion.xlsx, la pestaña de Sec 2 usa la
# columna `variedad`, mientras que la de Sec 3A usa `id_variedad` (ya lo
# habías anotado vos mismo al final del script anterior). Se armoniza acá
# con rename() para poder tratar ambas secciones de forma consistente
# de aquí en adelante. Convendría corregir el nombre de columna en el
# Excel de origen (Sec 2) para no depender de este rename.

sec2_puente <- read_excel(ruta_puente, sheet = hoja_sec2) |>
  clean_names() |>
  rename(id_variedad = variedad) |>
  select(id_variedad, descripcion_engih, enhance_id, fuente, tipo_equivalencia, validado) |>
  mutate(enhance_id = as.numeric(enhance_id))
# OJO -- en el Excel, 27 de 29 celdas de enhance_id (Sec 2) están guardadas
# como TEXTO (ej. '70214131' con comillas) y solo 2 como número real, lo que
# hace que readxl adivine toda la columna como character. as.numeric() lo
# fuerza de vuelta a double para que el join con food_factors.xlsx (numérico)
# no falle por incompatibilidad de tipos. Mismo patrón, un cellda suelta, en
# la pestaña Sec 3A -- se corrige igual abajo por si acaso.

sec3a_puente <- read_excel(ruta_puente, sheet = hoja_sec3a) |>
  clean_names() |>
  select(id_variedad, descripcion_engih, enhance_id, fuente, tipo_equivalencia, validado) |>
  mutate(
    id_variedad = as.character(id_variedad),  # en el crudo id_variedad es "text" a proposito (codigo, no cantidad)
    enhance_id  = as.numeric(enhance_id)
  )

# Paso 4: Porción comestible (PC) -----------------------------------------
# food_factors.xlsx ya trae el EDIBLE resuelto por enhance_id (INCAP directo,
# o 1.00 justificado para FNDDS ). No hace
# falta releer las tablas de composición completas acá: eso se reserva
# para 05_ingesta_micronutrientes.R, cuando además de EDIBLE se necesiten
# los 64 nutrientes de cada tabla.

sec2_pc <- read_excel(ruta_tabla_PC, sheet = hoja_sec2) |>
  clean_names() |>
  select(enhance_id, edible) |>
  mutate(enhance_id = as.numeric(enhance_id))

sec3a_pc <- read_excel(ruta_tabla_PC, sheet = hoja_sec3a) |>
  clean_names() |>
  select(id_variedad, edible) |>
  mutate(id_variedad = as.character(id_variedad))
# OJO -- CONFIRMADO CONTRA DATOS REALES: no se puede unir por enhance_id
# aca. El enhance_id 70211088 (Guandu, grano verde) aparece en DOS
# id_variedad distintos (374 "en cascara" y 376 "desgranados") con edible
# DISTINTO (0.48 vs 1.00, ver bitacora QC) -- unir por enhance_id le hace
# many-to-many fan-out exactamente a esas 1349 filas del crudo (374+376),
# duplicandolas. id_variedad es unico en esta tabla, asi que se une por ahi.

# Paso 5: Ensamblar Q + FC + enhance_id + PC, por sección -----------------

## 5.1 Sección 2 -----------------------------------------------------------
sec2_data <- sec2_data_raw |>
  transmute(
    id_vivienda    = vivienda,
    id_hogar       = hogar,
    id_hogar_unico = paste(vivienda, hogar, sep = "_"),  # ojo: hogar se repite entre viviendas
    id_variedad    = variedad,
    descripcion,
    id_unidad_medida_presentacion,
    id_unidad_medida,
    Q               = consumo_exclusivo_hogar,  # ya resuelto por la encuesta (pregunta 9)
    cantidad_inicial,
    cantidad_final,
    factor_anual  # peso muestral -- necesario para cualquier agregado representativo (ver 03_transform.R)
  ) |>
  resolver_unidad() |>
  left_join(dic_conversion, by = c("unidad_a_convertir" = "id_unidad_medida_presentacion")) |>
  left_join(
    sec2_fc_especifico,
    by = c("id_variedad" = "variedad", "unidad_a_convertir" = "id_unidad_medida_presentacion")
  ) |>
  mutate(fc = coalesce(fc_universal, fc_especifico)) |>
  left_join(
    sec2_puente |> filter(validado == TRUE),
    by = "id_variedad"
  ) |>
  left_join(sec2_pc, by = "enhance_id") |>
  mutate(PM = PM  )

message(
  "Sec 2 -- ", nrow(sec2_data), " filas",
  " | FC via tabla universal: ", sum(!is.na(sec2_data$fc_universal)),
  " | FC via tabla especifica: ", sum(is.na(sec2_data$fc_universal) & !is.na(sec2_data$fc_especifico)),
  " | SIN FC (pendiente completar 'Alimento-especifico'): ", sum(is.na(sec2_data$fc)),
  " | sin enhance_id validado: ", sum(is.na(sec2_data$enhance_id)),
  " | sin PC/edible: ", sum(is.na(sec2_data$edible))
)

## 5.2 Sección 3A ------------------------------------------------------------
sec3a_data <- sec3a_data_raw |>
  transmute(
    id_vivienda    = vivienda,
    id_hogar       = hogar,
    id_hogar_unico = paste(vivienda, hogar, sep = "_"),
    dia,
    id_variedad,
    descripcion,
    id_unidad_medida_presentacion,
    id_unidad_medida,
    Q = cantidad_adquirida,
    factor_expansion  # peso muestral -- necesario para cualquier agregado representativo (ver 03_transform.R)
  ) |>
  resolver_unidad() |>
  left_join(dic_conversion, by = c("unidad_a_convertir" = "id_unidad_medida_presentacion")) |>
  left_join(
    sec3a_fc_especifico,
    by = c("descripcion" = "descripcion", "unidad_a_convertir" = "id_unidad_medida_presentacion")
  ) |>
  mutate(fc = coalesce(fc_universal, fc_especifico)) |>
  left_join(
    sec3a_puente |> filter(validado == TRUE),
    by = "id_variedad"
  ) |>
  left_join(sec3a_pc, by = "id_variedad") |>
  mutate(PM = PM )

# Días distintos con registro por hogar (confirmado: mediana 7, min 1, max 8).
# lo dejo calculado y listo para 03_transform.R.
dias_por_hogar <- sec3a_data |>
  group_by(id_hogar_unico) |>
  summarise(dias_observados_hogar = n_distinct(dia), .groups = "drop")

sec3a_data <- sec3a_data |>
  left_join(dias_por_hogar, by = "id_hogar_unico")

message(
  "Sec 3A -- ", nrow(sec3a_data), " filas",
  " | FC via tabla universal: ", sum(!is.na(sec3a_data$fc_universal)),
  " | FC via tabla especifica (texto): ", sum(is.na(sec3a_data$fc_universal) & !is.na(sec3a_data$fc_especifico)),
  " | SIN FC (pendiente completar 'Alimento-especifico'): ", sum(is.na(sec3a_data$fc)),
  " | sin enhance_id validado: ", sum(is.na(sec3a_data$enhance_id)),
  " | sin PC/edible: ", sum(is.na(sec3a_data$edible))
)

# Paso 6: Guardar datos limpios (aún SIN calcular consumo) ------------------
dir.create(here("data", "clean"), showWarnings = FALSE, recursive = TRUE)

write_delim(
  sec2_data,
  here("data", "clean", "data_sec2.csv"),
  delim = ";"
)

write_delim(
  sec3a_data,
  here("data", "clean", "data_sec3a.csv"),
  delim = ";"
)

# Resumen y siguientes pasos -------------------------------------------------
# Este script deja, por cada registro de Sec 2 y Sec 3A, las columnas:
#   Q, fc, enhance_id, edible (PC), PM (y dias_observados_hogar en Sec 3A)
# listas para aplicar en 03_transform.R:
#   Consumo diario (gramos comestibles) = Q * fc * edible / PM
#
# PENDIENTE PARA 03_transform.R (no acá):
#   - Aplicar la fórmula y generar Consumo_diario_g -- usando
#     dias_observados_hogar en vez de la constante PM =1 (ver abajo)
#   - Control de calidad de outliers (Paso 7 de la guía MIMI/WFP)
#   - Disponibilidad neta para alimentos almacenables compartidos entre
#     Sec 2 y Sec 3A (inventario_inicial + adquisiciones - inventario_final)
#
# CONFIRMADO CONTRA Registros_Cuestionario_B.xlsx REAL (ya probado, no es
# especulación):
#   1. PM  = 1 está mal. Por hogar hay una mediana de 7 días distintos
#      con registros en Sec 3A (min 1, max 8) -- no es un recordatorio de un
#      solo día. Con PM=1 fijo, el consumo diario aparente saldría inflado
#      ~6-7x. Usá `dias_observados_hogar` (ya calculado arriba) como
#      divisor en 03_transform.R.
#   2. El join de FC no era un simple left_join por unidad -- hacía falta la
#      lógica de 3 niveles ya implementada en el Paso 2 (universal exacta >
#      específica por alimento, con `id_unidad_medida` como respaldo cuando
#      no hay `id_unidad_medida_presentacion`). Con esa lógica: Sec 2
#      resuelve FC en 46.7% de las filas via tabla universal, 0% via
#      específica (porque las únicas filas específicas ya rellenadas están
#      mal escaladas, ver más abajo) y queda 53.3% pendiente. Sec 3A resuelve
#      31.3% via universal y queda 68.7% pendiente -- ambos números son
#      trabajo de investigación de factores por alimento que ya sabías que
#      faltaba, no un error del script.
#   3. Bug de escala real en data_raw_unidades.xlsx: las 15 filas de la hoja
#      Sec 2 que tienen FC específico relleno (Galón, Litro, Botellón,
#      Libra, Quintal por alimento) están 1000x infladas respecto a
#      diccionario_conversion (ej. Galón: 3785.41 vs 3,785,410 para ACEITE).
#      Como la tabla universal tiene prioridad, hoy no te afecta, pero
#      convendría borrarlas o corregirlas en la fuente.
#   4. ~168 de las 718 filas de la hoja Sec 3A tienen texto con problemas de
#      codificación (ej. "SazÃ³n" en vez de "Sazón") -- te va a estorbar
#      cuando empieces a rellenar esos factores, porque el texto no va a
#      coincidir con `DESCRIPCION` del crudo aunque el FC ya esté puesto.
#   5. 16 códigos de VARIEDAD que aparecen en el crudo de Sec 2 (ej. 31, 32,
#      33, 45, 56, 63, 89...) no están en tu crosswalk de 30 alimentos --
#      afecta solo 62 de 47,837 filas (0.13%), así que es menor, pero quedan
#      sin enhance_id hasta que decidas si vale la pena cubrirlos.
