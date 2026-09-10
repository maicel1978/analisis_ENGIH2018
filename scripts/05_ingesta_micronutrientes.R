# 05_ingesta_micronutrientes.R
#
# BORRADOR/ANCLA (2026-09-09) -- primer paso verificado, no un pipeline
# completo todavia. Ver "PRIORIDAD ACTUAL" en HOJA_DE_RUTA_PROYECTO.md.
#
# Alcance deliberadamente acotado a 4 nutrientes (no los ~65 disponibles),
# para tener un resultado real de punta a punta antes de ampliar:
#   Energia, Hierro, Acido folico, Vitamina A
# (los que Santiago nombro explicitamente + los que tienen benchmark de
# comparacion documentado, ENM 2009/2024 -- ver VISION_Y_ARQUITECTURA).
#
# YA VERIFICADO (2026-09-09), no asumido -- ver tabla de equivalencia:
#   Nutriente      | INCAP      | FNDDS                        | Unidad
#   Energia        | ENERC_KCAL | Energy (kcal)                | kcal
#   Hierro         | FE         | Iron (mg)                    | mg
#   Acido folico   | FOLDFE     | Folate, DFE (mcg_DFE)         | mcg DFE
#   Vitamina A     | VITA_RAE   | Vitamin A, RAE (mcg_RAE)      | mcg RAE
#
# OJO -- trampa real encontrada al verificar: FNDDS tiene TRES columnas de
# folato ("Folate, food", "Folate, DFE", "Folate, total"). Solo "Folate, DFE"
# corresponde a FOLDFE de INCAP (mismo ajuste de equivalencia dietetica).
# Las otras dos miden algo distinto -- NO usarlas por error.
#
# Las 4 unidades coinciden exactamente entre INCAP y FNDDS -- no hace falta
# factor de conversion para estos 4 nutrientes especificamente (puede que
# si haga falta al ampliar a otros).
#
# PENDIENTE (no hecho en este borrador, dejarlo para cuando se retome):
#   - Ejecutar y confirmar que corre limpio contra los datos reales.
#   - Extender a mas nutrientes una vez este resultado este validado.
#   - Sec 3A: ~45% de los alimentos todavia sin enhance_id validado en el
#     crosswalk (55% completo) -- esas filas daran NA en el resultado,
#     es esperado, no un bug. Documentar el % de cobertura real del
#     resultado final, no solo presentarlo sin ese contexto.

library(conflicted)
library(readr)
library(dplyr)
library(readxl)
library(here)
conflicts_prefer(dplyr::filter)

# Paso 1: Cargar consumo por EMA (ya construido en 04_equivalente_adulto.R) -
gramos_por_ema <- read_delim(
  here("data", "clean", "data_gramos_por_ema.csv"),
  delim = ";",
  show_col_types = FALSE
)

# Paso 2: Cargar crosswalk (fuente de enhance_id + de donde viene: INCAP/FNDDS)
crosswalk_sec2 <- read_excel(
  here("data", "raw", "crosswalk_tablas_composicion.xlsx"),
  sheet = "Cuest. B Sec 2"
) |>
  filter(!is.na(enhance_id), validado == TRUE) |>
  select(id_variedad, enhance_id, fuente)

crosswalk_sec3a <- read_excel(
  here("data", "raw", "crosswalk_tablas_composicion.xlsx"),
  sheet = "Cuest. B Sec 3A"
) |>
  filter(!is.na(enhance_id), validado == TRUE) |>
  select(id_variedad, enhance_id, fuente)

# TODO: unir crosswalk_sec2/sec3a con gramos_por_ema por id_variedad
# (revisar que el tipo de id_variedad coincida en ambos lados -- ya tuvimos
# un bug real por esto en data_raw_unidades.xlsx, ver HOJA_DE_RUTA, no
# repetir el mismo error aqui sin comprobar el tipo primero).

# Paso 3: Cargar las 4 columnas de nutrientes de cada tabla, con nombres
# de columna ESTANDARIZADOS para poder combinarlas despues (independiente
# de si el alimento vino de INCAP o de FNDDS).
nutrientes_incap <- read_excel(
  here("data", "raw", "food_composition_INCAP.xlsx"),
  sheet = "nutrient_values"
) |>
  transmute(
    enhance_id = ENHANCE_ID,
    energia_kcal = ENERC_KCAL,
    hierro_mg = FE,
    folato_mcg_dfe = FOLDFE,
    vitamina_a_mcg_rae = VITA_RAE
  )

nutrientes_fndds <- read_excel(
  here("data", "raw", "food_composition_FNDDS.xlsx"),
  skip = 1
) |>
  transmute(
    enhance_id = `Food code`,
    energia_kcal = `Energy (kcal)`,
    hierro_mg = `Iron\n(mg)`,  # OJO: el nombre real trae un salto de linea
    folato_mcg_dfe = `Folate, DFE (mcg_DFE)`,  # NO usar las otras 2 columnas de folato
    vitamina_a_mcg_rae = `Vitamin A, RAE (mcg_RAE)`
  )

# TODO: combinar nutrientes_incap + nutrientes_fndds en una sola tabla,
# usar crosswalk$fuente para saber de cual tabla sacar cada enhance_id
# (bind_rows no sirve directo si un mismo enhance_id numerico pudiera
# existir en ambas fuentes por coincidencia -- verificar esto antes de
# combinar, no asumir que los enhance_id son unicos entre fuentes).

# TODO: unir gramos_por_ema + crosswalk + nutrientes; calcular
# ingesta_aparente_por_EMA = sum(Gramos_por_EMA_dia * nutriente_por_gramo)
# agrupado por hogar, para cada uno de los 4 nutrientes.

# TODO: reportar el % de gramos consumidos (ponderado, no solo conteo de
# filas) que SI logro match de nutriente, vs. el % que quedo sin match
# por crosswalk incompleto -- ese numero es tan importante como el
# resultado final, no ocultarlo.

message("Borrador cargado. Columnas de nutrientes verificadas y listas para unir -- falta el join final y la agregacion por hogar (ver TODOs arriba).")