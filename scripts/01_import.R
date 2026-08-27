# Script: 01_import.R (Lectura de datos ENGIH 2018)
# Proyecto: ENGIH 2018 - Consumo de alimentos y nutrición
# Fecha: 2026-08-18
#
# Objetivos:
#
#   1. Importar datos originales de la ENGIH 2018
#      (Sección 2 y Sección 3A)
#
#   2. Identificar variables necesarias para el cálculo de consumo:
#
#      Q  = Cantidad observada
#      FC = Factor de conversión a gramos
#      PC = Factor de porción comestible
#      PM = Período de medición
#
#   3. Generar datasets limpios de trabajo
#
#   4. Preparar la integración posterior con tablas de composición
#      alimentaria y crosswalks validados.
#
#
# Salidas de esta etapa
#
#   data/raw/data_raw_sec2.csv
#   data/raw/data_raw_sec3a.csv
#
#   data/clean/data_sec2.csv
#   data/clean/data_sec3a.csv
#
# Esta etapa NO calcula nutrientes ni consumo diario.
#
# =========================================================================
#
# Fórmula base del proyecto
#
#   Consumo diario (g) = Q × FC × PC / PM
#
# donde:
#
#   Q  = cantidad registrada en la encuesta
#   FC = factor de conversión a gramos
#   PC = porción comestible
#   PM = período de medición
#
# Ninguna estimación nutricional posterior es válida si esta etapa no
# queda correctamente implementada.
#
# =========================================================================
#
# Arquitectura general del sistema
#
# Fuentes de composición alimentaria
# ----------------------------------
#
#   food_composition_INCAP.xlsx
#   food_composition_USDA.xlsx
#   food_composition_FNDDS.xlsx
#
# Estas tablas se mantienen como fuentes independientes.
#
#
# Crosswalks de correspondencia alimentaria
# -----------------------------------------
#
#   crosswalk_variedad_INCAP.xlsx
#   crosswalk_variedad_USDA.xlsx
#   crosswalk_variedad_FNDDS.xlsx
#                   ↓
#   crosswalk_variedad_MASTER.xlsx
#
# Los crosswalks contienen las decisiones manuales de correspondencia
# entre los alimentos observados en ENGIH y las tablas de composición.
#
# El archivo MASTER se genera automáticamente a partir de los
# crosswalks validados por fuente.
#
#
# Dataset nutricional integrado
# -----------------------------
#
#   data_sec3a.csv
#           +
#   crosswalk_variedad_MASTER.xlsx
#           +
#   food_composition_*.xlsx
#           ↓
#   dataset_nutricional
#
# dataset_nutricional constituye el principal objeto analítico del
# proyecto.
#
# Cada registro alimentario de ENGIH quedará asociado a:
#
#   - porción comestible (PC)
#   - energía
#   - macronutrientes
#   - micronutrientes
#   - metadatos de la correspondencia utilizada
#
# Todas las fases posteriores:
#
#   - EDA
#   - Transformación
#   - Cálculo de consumo
#   - Adecuación nutricional
#   - Fortificación
#   - Modelación
#   - Visualización
#
# deberán consumir preferentemente dataset_nutricional.
#
# Los análisis no deben depender directamente de INCAP, USDA o FNDDS.
#
# =========================================================================
#
# Nota metodológica
#
# Durante la fase actual:
#
#   INCAP es la fuente principal de composición alimentaria.
#
# USDA y FNDDS se incorporarán progresivamente cuando existan alimentos
# frecuentes de ENGIH que no puedan representarse adecuadamente con INCAP.
#
# La prioridad del proyecto es mejorar gradualmente la cobertura
# nutricional manteniendo la trazabilidad de las decisiones y evitando
# complejidad innecesaria.
#
# =========================================================================
#
# Identificación de hogares
#
# El identificador único de hogar es:
#
#   VIVIENDA + HOGAR
#
# La variable HOGAR no es única dentro de la encuesta y no debe
# utilizarse de forma aislada.
#
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
#   (PM_SEC2 = 7: el formulario oficial dice "inventario ... el día 1 y 8
#    de la entrevista"; el valor 30 que se usaba antes NO aparece en el
#    formulario -> CONFIRMAR CON MIMI. PM_SEC3A = 1 por registro, diario
#    de 7 días -> promediar entre 7. Ver 03_transform.R y PLAN_DE_TRABAJO.md)
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

# 5. Composición alimentaria (MOVIDO a 03_transform.R) ----------------------
# Regla de gobernanza (VISION_Y_ARQUITECTURA_PROYECTO.md): los scripts
# analíticos no leen fuentes individuales (INCAP/USDA/FNDDS). El join
# ENGIH <-> crosswalk <-> composición se hace en 03_transform.R sobre las
# capas maestras que genera 00_master.R:
#
#   data/master/crosswalk_variedad_MASTER.xlsx   (puente, llave con
#                                                espacio de nombres CAT:/SEC2:)
#   data/master/food_composition_MASTER.xlsx     (composición armonizada
#                                                + pc_factor)
#
# Nota histórica: la tercera base manual (crosswalk_variedad_INCAP.xlsx)
# sigue siendo la entrada editada manualmente; lo que cambió es que su
# uso está mediado por el MASTER. Los alimentos que no son comida
# (tabaco, etc.) se excluyen de forma EXPLÍCITA en el MASTER
# (estado = "excluido"), no por ausencia del join.

