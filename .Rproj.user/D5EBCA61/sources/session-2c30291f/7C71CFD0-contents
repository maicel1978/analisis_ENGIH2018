# =========================================================================
# Script: 01_import.R (Lectura de datos ENGIH 2018)
# Proyecto: ENGIH 2018 - Consumo de alimentos
# Fecha: 2026-08-18
# Objetivos:
#   1. Importar datos originales Secciones 2 y 3A
#   2. Identificar la sección y el módulo de consumo alimentario
#   3. Identificar variables críticas (Q, FC, PC, PM)
#   - Q = Cantidad registrada en la encuesta
#   - FC = Factor de conversión de unidades no estándar a gramos
#   - PC = Porción comestible
#   - PM = Periodo de medición
#   4. Generar dataset crudo (raw) y dataset seleccionado (clean) para
#      luego hacer transformaciones y modelación (Consumo diario)
# Salidas:
#   - data/raw/data_raw_sec2.csv    (Sección 2 sin transformar)
#   - data/raw/data_raw_sec3a.csv   (Sección 3A sin transformar)
#   - data/clean/data_sec2.csv      (Sección 2, variables seleccionadas)
#   - data/clean/data_sec3a.csv     (Sección 3A, variables seleccionadas)
# =========================================================================
# Nota: variables para calcular el Consumo diario (Q * FC * PC / PM)
# *   Q  = Cantidad registrada en la encuesta
#          Sec 2  -> CONSUMO_EXCLUSIVO_HOGAR (pregunta 9: "Del inventario
#                     inicial ¿cuánto utilizó exclusivamente para consumo
#                     del hogar?")
#          Sec 3A -> CANTIDAD_ADQUIRIDA (pregunta 3: "Cantidad adquirida")
#                     OJO: no confundir con CANTIDAD_UNIDADES_PRESENTACION
#                     (número de unidades del empaque, pregunta 5)
# **  FC = Factor de conversión de unidades no estándar a gramos
#          (se construye en 03_fc_pc.R a partir de ID_UNIDAD_MEDIDA; todavía no
#          disponible en este dataset -> pendiente de tabla de conversión)
# *** PC = Porción comestible (pendiente de tabla de composición alimentaria)
# *** PM = Periodo de medición
#          Sec 2  -> 30 días (recordatorio de inventario mensual)
#          Sec 3A -> 1 día (recordatorio de 24 horas); un hogar puede tener
#                    hasta 7 registros (variable `dia`) a agregar en 03_fc_pc.R
# El identificador único de hogar es la combinación VIVIENDA + HOGAR:
# HOGAR se repite entre viviendas distintas, por lo que usar solo HOGAR
# como id mezclaría hogares diferentes.
# =========================================================================

# 1. Configuración general -------------------------------------------------
rm(list = ls())   # limpia el entorno
options(stringsAsFactors = FALSE)

library(conflicted)
library(readxl)
library(readr)
library(here)
library(dplyr)
library(janitor)
conflicts_prefer(dplyr::filter)

# ruta a los datos originales (fuente única de verdad para el path)
ruta_ENGIH2018 <- here("data", "raw", "Registros_Cuestionario_B.xlsx")
ruta_tca <- here("data", "raw", "food_composition_INCAP.xlsx")
ruta_crosswalk <- here("data", "raw", "crosswalk_variedad_INCAP.xlsx")


# 2. Lectura de diccionario complementario para unidades de medida ---------
# - Diccionario para codificar unidades de medida no estandarizadas.
#   Aplica a las Secciones 2 y 3A.
# Nota: el catálogo de variedades (grupos/subgrupos/clases) no se carga
# todavía; se incorporará en 03_transform.R cuando se necesite agrupar
# alimentos por categoría.
data_raw_unidades <- read_excel(ruta_ENGIH2018, sheet = "Unidades_medida") |>
  clean_names()

write_delim(data_raw_unidades, file = here("data", "raw", "data_raw_unidades.csv"),
            col_names = T, 
            delim = ";")
# 3. Sección 2: INVENTARIO INICIAL Y FINAL EN LA DESPENSA Y REFRIGERADOR ----
# Dataset en formato long (hogares x alimentos), 47,837 filas, 12 variables:
#  $ vivienda                       <dbl>
#  $ hogar                          <dbl>  -- OJO: se repite entre viviendas
#  $ variedad                       <dbl>  alimento (código)
#  $ descripcion                    <chr>  alimento (texto)
#  $ id_unidad_medida_presentacion  <dbl>
#  $ cantidad_unidades_presentacion <dbl>
#  $ contenido_empaque_presentacion <dbl>
#  $ id_unidad_medida               <dbl>  unidad de la cantidad reportada
#  $ cantidad_inicial               <dbl>
#  $ cantidad_final                 <dbl>
#  $ consumo_exclusivo_hogar        <dbl>  == Q (pregunta 9)
#  $ factor_anual                   <dbl>  factor de expansión

data_raw_sec2 <- read_excel(ruta_ENGIH2018, sheet = "Cuest. B Sec 2") |>
  clean_names()

# Guardo los datos originales sin transformar
write_delim(data_raw_sec2, file = here("data", "raw", "data_raw_sec2.csv"),
            col_names = T, 
            delim = ";")

# Selecciono y transformo con cambios mínimos
data_sec2 <- data_raw_sec2 |>
  left_join(data_raw_unidades, by = "id_unidad_medida") |>
  transmute(
    id_vivienda = vivienda,
    id_hogar    = hogar,
    id          = paste(vivienda, hogar, sep = "_"),  # id único de hogar
    id_variedad = variedad, 
    variedad    = descripcion,
    id_unidad_medida,
    unidad_medida = des_unidad_medida,
    id_unidad_medida_presentacion,
    cantidad_unidades_presentacion,
    contenido_empaque_presentacion,
    cantidad_inicial,
    cantidad_final,
    cantidad = consumo_exclusivo_hogar,   # Q: consumo del inventario inicial
    factor_anual
  )

write_delim(x = data_sec2, file = here("data", "clean", "data_sec2.csv"),
            col_names = T, delim = ";")

message(sprintf("Sección 2: %d filas, %d hogares únicos",
                nrow(data_sec2), n_distinct(data_sec2$id)))

# 4. Sección 3A: DETALLE DE LAS ADQUISICIONES DIARIAS ------------------------
# Dataset long, 342,046 filas, 33 variables. Relevantes para Q/FC/PM:
#  $ vivienda                       <dbl>
#  $ hogar                          <dbl>  -- OJO: se repite entre viviendas
#  $ dia                            <dbl>  día del registro (1-7)
#  $ id_variedad                    <dbl>  alimento (código)
#  $ descripcion                    <chr>  alimento (texto)
#  $ cantidad_adquirida             <dbl>  == Q (pregunta 3)
#  $ id_unidad_medida_presentacion  <dbl>
#  $ cantidad_unidades_presentacion <dbl>  NO es Q (número de unidades)
#  $ contenido_empaque_presentacion <dbl>
#  $ id_unidad_medida               <dbl>  unidad de cantidad_adquirida
#  $ tamano                         <dbl>
#  $ porcentaje_hogar               <dbl>  % de lo adquirido para el hogar
#  $ factor_expansion               <dbl>

data_raw_sec3a <- read_excel(ruta_ENGIH2018, 
                             sheet = "Cuest. B Sec 3A", 
                             col_types = c("guess",
                                           "guess", 
                                           "guess",
                                           "guess",
                                           "numeric",
                                           "text", 
                                           "guess",
                                           "guess", 
                                           "guess", 
                                           "guess",
                                           "guess", 
                                           "guess", 
                                           "skip", 
                                           "skip",
                                           "skip", 
                                           "skip",
                                           "skip", 
                                           "skip", 
                                           "skip", 
                                           "skip",
                                           "skip", 
                                           "skip",
                                           "skip", 
                                           "skip", 
                                           "skip", 
                                           "skip", 
                                           "skip", 
                                           "skip", 
                                           "skip",
                                           "guess", 
                                           "guess", 
                                           "guess", 
                                           "guess"),
                             col_names = TRUE,) |>
  clean_names()

write_delim(data_raw_sec3a, 
            file = here("data", "raw", "data_raw_sec3a.csv"),
            col_names = T, 
            delim = ";")

data_sec3a <- data_raw_sec3a |>
  left_join(data_raw_unidades, by = "id_unidad_medida") |>
  transmute(
    id_vivienda = vivienda,
    id_hogar    = hogar,
    id          = paste(vivienda, hogar, sep = "_"),  # id único de hogar
    dia,
    orden,
    id_variedad,
    variedad    = descripcion,
    id_unidad_medida,
    unidad_medida = des_unidad_medida,
    cantidad = cantidad_adquirida,        # Q: cantidad adquirida (preg. 3)
    id_unidad_medida_presentacion,
    cantidad_unidades_presentacion,
    contenido_empaque_presentacion,
    tamano,
    porcentaje_hogar,
    factor_expansion
  )

write_delim(data_sec3a, file = here("data", "clean", "data_sec3a.csv"),
            col_names = T, 
            delim = ";")

message(sprintf("Sección 3A: %d filas, %d hogares únicos",
                nrow(data_sec3a), n_distinct(data_sec3a$id)))

# Resumen (hasta 17/agosto/2026). Siguientes pasos  ----------------------
# - Construir tabla de Factores de Conversión (FC) por id_unidad_medida -> gramos
# - Construir tabla de Porciones Comestibles (PC) por alimento (variedad/artículo)
# - Aplicar Consumo diario (gramos) = Q * FC * PC / PM
#   (PM = 30 en Sec 2; PM = 1 en Sec 3A, agregado luego por hogar)
# - Controles de calidad: valores atípicos y verificación de distribución
#   (ver "Paso 7" de la guía metodológica) antes de agregar a nivel de hogar
# - Incorporar otras variable de estratificación sociodemográfica disponibles en ENGIH 2018 (informe y dashboard )
# Una vez que tengo el consumo diario en gramos comestibles, puedo calcular:
# Ingesta energética → kcal por persona/día.
# Ingesta de macronutrientes → proteínas, grasas, carbohidratos.
# Ingesta de micronutrientes → hierro, zinc, vitamina A, etc., usando la tabla INCAP.
# Adecuación nutricional → % de requerimiento cubierto según edad/sexo.
# Distribución del consumo por grupos alimentarios → cereales, lácteos, frutas, carnes, etc.
# Patrones de dieta → alimentos más consumidos, diferencias rural/urbano.
# Indicadores de seguridad alimentaria → diversidad dietética, gasto en alimentos vs ingreso total.
# Equivalente de mujer adulta (AWE) → ajuste demográfico para comparar hogares de distinto tamaño y composición.

# 5. Tabla de composición  (incluye el factor de porción comestible PC) ------------------------
# nota
# food_composition_INCAP.xlsx → Es la tabla de composición de alimentos que me envió Santiago.
# La tabla de composición incluye el (PC) factor de porción comestible 
# Contiene la composición nutricional por 100 g comestibles y, en muchos casos, el factor de porción comestible (PC).
data_tca<- read_excel(path = ruta_tca) |> clean_names()
# Nota: 
# debo conectar data_tca con los datos con data_raw_sec2 y data_raw_sec3a
# los datos de data_tca y data_raw_sec3a no tienen llaves compatibles para unir los datos 
# Para solucionarlo hice una tercera base de datos manual (crosswalk_variedad_incap) para conectarlos y revisar manual
# Se reducen la dimesion de los alimentos y eliminan algunos elementos como el cigarro que no son alimentos

# 1. Tabla puente validada
data_crosswalk <- read_excel(ruta_crosswalk, sheet = "Datos") |> 
  clean_names() |> 
  filter(validado == TRUE) |> 
  select(id_variedad, enhance_id_final)

# 2. Join ENGIH con tabla puente
data_sec3a_join <- data_sec3a |>
  left_join(data_crosswalk, by = "id_variedad")

# 3. Join con tabla INCAP usando enhance_id
data_sec3a_comp <- data_sec3a_join |>
  left_join(data_tca, by = c("enhance_id_final" = "enhance_id"))

