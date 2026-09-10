# 05_ingesta_micronutrientes.R
#
# Ingesta aparente de micronutrientes por EMA (hogar).
#
# Versión completa (2026-09-10). El borrador anterior (ancla 2026-09-09) dejaba
# los joins como TODO. Esta versión los completa siguiendo una verificación
# independiente del pipeline completo en Python
# (scripts/audit/verificacion_cruzada_pipeline.py, misma fecha), que ya
# produjo los números esperados para contrastar cuando se corra este script
# (ver "VERIFICACIÓN CRUZADA" al final). Nada aquí es especulativo: cada join
# y cada supuesto está verificado contra los archivos reales del repo.
#
# Alcance (decisión 2026-09-09, HOJA_DE_RUTA "PRIORIDAD ACTUAL"): 4 nutrientes
# de punta a punta antes de ampliar:
#   Energia, Hierro, Acido folico, Vitamina A
#
# Tabla de equivalencia de columnas (VERIFICADA contra los archivos reales):
#   Nutriente      | INCAP      | FNDDS                   | Unidad
#   Energia        | ENERC_KCAL | Energy (kcal)           | kcal
#   Hierro         | FE         | Iron\n(mg)              | mg       (ojo: salto de linea en FNDDS)
#   Acido folico   | FOLDFE     | Folate, DFE (mcg_DFE)   | mcg DFE  (NO usar "Folate, food" ni "Folate, total")
#   Vitamina A     | VITA_RAE   | Vitamin A, RAE (mcg_RAE)| mcg RAE
#   Ambas tablas vienen POR 100 g -> se dividen entre 100 aqui.
#
# VERIFICADO (2026-09-10, contra los archivos reales, no asumido):
#   - Los ENHANCE_ID de INCAP (1,466) y los Food codes de FNDDS (7,083) NO
#     colisionan (interseccion vacia). bind_rows es seguro: un mismo
#     enhance_id numerico no puede existir en ambas fuentes.
#   - Ninguna de las dos tablas tiene enhance_id/food code faltante.
#   - data_gramos_por_ema.csv YA trae enhance_id por fila (heredado del join
#     con el crosswalk en 01_import.R): no hace falta re-unir el crosswalk
#     acá. Solo las filas con alimento validado tienen enhance_id; el resto
#     da NA en nutrientes y queda contabilizado en la cobertura (Paso 4).
#
# LIMITACIONES QUE ESTE SCRIPT REPORTA, NO OCULTA (principios 3-5 del proyecto):
#   - Cobertura: solo entra al calculo la fraccion del crudo con FC + PC +
#     enhance_id. El % exacto se calcula e imprime en el Paso 4 y DEBE
#     citarse junto a cualquier resultado (Sec 2 ~90.7%, Sec 3A ~71.9% de
#     filas al 2026-09-10, estado post-correccion de data_raw_unidades.xlsx).
#   - Es ingesta APARENTE por hogar (adquisiciones), nivel hogar por EMA --
#     no ingesta individual usual. Comparar contra EAR a nivel de hogar es
#     ilustrativo (ver caveats en el reporte final, no usar tal cual para
#     prevalencia poblacional).
#   - Los vehiculos fortificados (arroz, harina, azucar) apuntan hoy a
#     entradas que NO reflejan el programa real de RD 2018 (ver Paso 6):
#     el escenario "crosswalk actual" es un MIXTO y no debe reportarse como
#     linea base.

library(conflicted)
library(readr)
library(dplyr)
library(readxl)
library(here)
conflicts_prefer(dplyr::filter)

# ============================================================================
# Paso 1: Cargar consumo por EMA (construido en 04_equivalente_adulto.R)
# ============================================================================
gramos_por_ema <- read_delim(
  here("data", "clean", "data_gramos_por_ema.csv"),
  delim = ";",
  show_col_types = FALSE
) |>
  mutate(enhance_id = as.numeric(enhance_id))
# as.numeric defensivo: read_delim puede leer enhance_id como texto si hay
# celdas raras; el join con nutrientes exige double en ambos lados (mismo
# tipo de bug ya ocurrido con id_variedad -- ver HOJA_DE_RUTA 2026-09-09).

# ============================================================================
# Paso 2: Cargar los 4 nutrientes de cada tabla de composicion, estandarizados
# ============================================================================
nutrientes_incap <- read_excel(
  here("data", "raw", "food_composition_INCAP.xlsx"),
  sheet = "nutrient_values"
) |>
  transmute(
    enhance_id         = as.numeric(ENHANCE_ID),
    energia_kcal       = ENERC_KCAL / 100,
    hierro_mg          = FE / 100,
    folato_mcg_dfe     = FOLDFE / 100,
    vitamina_a_mcg_rae = VITA_RAE / 100
  ) |>
  filter(!is.na(enhance_id))

nutrientes_fndds <- read_excel(
  here("data", "raw", "food_composition_FNDDS.xlsx"),
  sheet = "nutrient_values",
  skip = 1
) |>
  transmute(
    enhance_id         = as.numeric(`Food code`),
    energia_kcal       = `Energy (kcal)` / 100,
    hierro_mg          = `Iron\n(mg)` / 100,                    # salto de linea real en el nombre
    folato_mcg_dfe     = `Folate, DFE (mcg_DFE)` / 100,         # NO las otras 2 columnas de folato
    vitamina_a_mcg_rae = `Vitamin A, RAE (mcg_RAE)` / 100
  ) |>
  filter(!is.na(enhance_id))

# Verificacion dura: IDs disjuntos entre fuentes (verificado 2026-09-10, pero
# estos archivos pueden cambiar en el futuro -- el check es barato y evita un
# bug silencioso de doble fuente para un mismo ID).
colision <- intersect(nutrientes_incap$enhance_id, nutrientes_fndds$enhance_id)
if (length(colision) > 0) {
  stop("BUG: ", length(colision), " enhance_id aparecen en INCAP y FNDDS a la vez. ",
       "No se puede combinar sin una regla de fuente. Investigar antes de continuar.")
}

nutrientes <- bind_rows(nutrientes_incap, nutrientes_fndds) |>
  distinct(enhance_id, .keep_all = TRUE)  # defensa contra duplicados futuros en la fuente

# ============================================================================
# Paso 3: Unir nutrientes al consumo y calcular ingesta por hogar
# ============================================================================
ingesta_hogar <- gramos_por_ema |>
  left_join(nutrientes, by = "enhance_id") |>
  mutate(
    intake_energia_kcal       = Gramos_por_EMA_dia * energia_kcal,
    intake_hierro_mg          = Gramos_por_EMA_dia * hierro_mg,
    intake_folato_mcg_dfe     = Gramos_por_EMA_dia * folato_mcg_dfe,
    intake_vitamina_a_mcg_rae = Gramos_por_EMA_dia * vitamina_a_mcg_rae
  ) |>
  group_by(id_hogar_unico) |>
  summarise(
    gramos_por_ema_dia = sum(Gramos_por_EMA_dia, na.rm = TRUE),
    energia_kcal       = sum(intake_energia_kcal, na.rm = TRUE),
    hierro_mg          = sum(intake_hierro_mg, na.rm = TRUE),
    folato_mcg_dfe     = sum(intake_folato_mcg_dfe, na.rm = TRUE),
    vitamina_a_mcg_rae = sum(intake_vitamina_a_mcg_rae, na.rm = TRUE),
    .groups = "drop"
  )

# ============================================================================
# Paso 4: Cobertura honesta -- que parte del crudo entro al calculo
# ============================================================================
# Las filas de gramos_por_ema ya superaron el filtro FC + PC (sin ellas no hay
# Consumo_diario_g). Para reportar la cobertura completa hay que volver a las
# salidas de 03_transform.R y medir contra el total del crudo.
archivos_consumo <- c(
  sec2  = here("data", "clean", "data_sec2_consumo.csv"),
  sec3a = here("data", "clean", "data_sec3a_consumo.csv")
)
cobertura <- bind_rows(lapply(names(archivos_consumo), function(s) {
  d <- read_delim(archivos_consumo[[s]], delim = ";", show_col_types = FALSE)
  tibble(
    seccion           = s,
    filas_total       = nrow(d),
    filas_con_consumo = sum(!is.na(d$Consumo_diario_g)),
    pct_cobertura     = round(100 * sum(!is.na(d$Consumo_diario_g)) / nrow(d), 1)
  )
}))

message("\n== Cobertura del calculo (filas del crudo que entran) ==")
print(cobertura)
message("OJO: todo resultado de este script esta calculado SOBRE esa fraccion. ",
        "Citar siempre junto al resultado (principios 3-5, VISION_Y_ARQUITECTURA).")

# ============================================================================
# Paso 5: Guardar salida principal
# ============================================================================
write_delim(ingesta_hogar, here("data", "clean", "data_ingesta_hogar.csv"), delim = ";")
message("\nSalida: data/clean/data_ingesta_hogar.csv (", nrow(ingesta_hogar), " hogares)")

# ============================================================================
# Paso 6: Escenarios de fortificacion (capa de intercambio de entradas)
# ============================================================================
# HALLAZGO CLAVE (auditoria 2026-09-10, ver INFORME_AUDITORIA_2026-09-10.md):
# el programa real de RD hacia 2018 fortifica harina de trigo de panificacion
# (obligatoria desde 2009: 45 mg/kg Fe fumarato ferroso, 1.8 mg/kg acido
# folico, NORDOM), azucar con vitamina A (NORDOM 606: 5-25 mg/kg) y sal con
# yodo -- PERO NO EL ARROZ. El crosswalk actual apunta el arroz a entradas
# ENRIQUECIDAS (70213002) y la harina/azucar a entradas SIN fortificar: es un
# mixto que no corresponde a ningun escenario real.
#
# La tabla INCAP ya tiene las entradas pareadas, asi que cada escenario es
# solo un intercambio de enhance_id por vehiculo (verificado contra la tabla
# real el 2026-09-10):
#   Arroz blanco crudo:   enriquecido 70213002 (Fe 4.36, FOL 386 mcg/100g)
#                         s/enrio     70213004 (Fe 0.80, FOL 9 mcg/100g)
#   Harina de trigo:      enriquecida 70213039 (Fe 4.64, FOL 291) | s/enrio 70213038 (Fe 1.17, FOL 26)
#   Azucar blanca:        fortif. A   70215002 (VIT A 1000 mcg/100g = 10 mg/kg) | s/fort 70215001
#
# PENDIENTE DE DECISION DEL EQUIPO (no decidir en silencio): pan, pastas y
# galletas elaborados con harina fortificada mantienen hoy su entrada INCAP
# tal cual; en RD la fortificacion de harina para pastas/galletas es
# VOLUNTARIA (FFI, informe RD). Cada escenario debe declarar que asume.
definir_escenarios <- function() {
  list(
    a_sin_fortificacion = c(
      "70213002" = "70213004",  # arroz -> sin enriquecer
      "70215001" = "70215001",  # azucar sin fortificar (ya lo esta)
      "70215036" = "70215001"   # azucar blanca fina -> sin fortificar
    ),
    b_norma_rd_2018 = c(
      "70213002" = "70213004",  # arroz sigue sin fortificar en RD (no hay norma de arroz)
      "70213038" = "70213039",  # harina de trigo enriquecida (obligatoria desde 2009)
      "70215001" = "70215002",  # azucar fortificada con vitamina A (NORDOM 606)
      "70215036" = "70215002"
    ),
    c_crosswalk_actual_mixto = c()  # tal como esta el crosswalk hoy (NO reportar como linea base)
  )
}

calcular_escenario <- function(gramos, swaps) {
  g <- gramos |>
    mutate(
      enhance_id = coalesce(as.numeric(swaps[as.character(enhance_id)]), enhance_id)
    ) |>
    left_join(nutrientes, by = "enhance_id")
  g |>
    transmute(id_hogar_unico,
              hierro      = Gramos_por_EMA_dia * hierro_mg,
              folato      = Gramos_por_EMA_dia * folato_mcg_dfe,
              vitamina_a  = Gramos_por_EMA_dia * vitamina_a_mcg_rae,
              energia     = Gramos_por_EMA_dia * energia_kcal) |>
    group_by(id_hogar_unico) |>
    summarise(across(where(is.numeric), \(x) sum(x, na.rm = TRUE)), .groups = "drop")
}

# Referencias para lectura de orden de magnitud (mujer adulta 19-50, IOM DRI):
# hierro EAR 8.1 mg/dia; folato EAR 320 mcg DFE/dia; vitamina A EAR 500 mcg RAE/dia.
# ILUSTRATIVO a nivel hogar-por-EMA: no es prevalencia individual.
refs <- c(hierro = 8.1, folato = 320, vitamina_a = 500)

# Pesos del hogar para los porcentajes ponderados
ema_hogar <- read_delim(here("data", "clean", "data_ema_hogar.csv"),
                        delim = ";", show_col_types = FALSE) |>
  select(id_hogar_unico, factor_expansion)

pct_ponderado_bajo <- function(x, ref, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  100 * sum(w[ok & x < ref]) / sum(w[ok])
}

escenarios <- definir_escenarios()
resumen_escenarios <- bind_rows(lapply(names(escenarios), function(nom) {
  h <- calcular_escenario(gramos_por_ema, escenarios[[nom]]) |>
    left_join(ema_hogar, by = "id_hogar_unico")
  tibble(
    escenario  = nom,
    hierro_mg_mediana       = median(h$hierro),
    hierro_pct_bajo_EAR     = pct_ponderado_bajo(h$hierro, refs["hierro"], h$factor_expansion),
    folato_mcg_mediana      = median(h$folato),
    folato_pct_bajo_EAR     = pct_ponderado_bajo(h$folato, refs["folato"], h$factor_expansion),
    vitA_mcg_mediana        = median(h$vitamina_a),
    vitA_pct_bajo_EAR       = pct_ponderado_bajo(h$vitamina_a, refs["vitamina_a"], h$factor_expansion),
    energia_kcal_mediana    = median(h$energia)  # no cambia entre escenarios (sanity check)
  )
}))

message("\n== Escenarios de fortificacion (mediana hogar por EMA, ponderado) ==")
print(as.data.frame(resumen_escenarios), digits = 4)

write_csv(resumen_escenarios, here("data", "eda", "escenarios_fortificacion_R.csv"))

# ============================================================================
# VERIFICACION CRUZADA -- numeros esperados (replica Python, 2026-09-10,
# scripts/audit/verificacion_cruzada_pipeline.py, contra los mismos datos):
#   Cobertura filas: Sec 2 = 90.7% | Sec 3A = 71.9%
#   Energia (mixto): mediana 2,102 kcal/EMA por hogar
#   Escenario (a) sin fortificacion:  hierro mediana 8.7 mg  (44.8% hogares < 8.1)
#                                      folato mediana 266 mcg (60.3% < 320)
#                                      vit.A  mediana 163 mcg (86.9% < 500)
#   Escenario (b) norma RD 2018:       hierro 8.9 mg (44.3%) | folato 274 mcg (59.3%)
#                                      vit.A 326 mcg (60.3% -- el efecto es el
#                                      azucar fortificada con vitamina A)
#   Escenario (c) crosswalk actual:    hierro 13.8 mg (24.8%) | folato 794 mcg (23.3%)
#                                      vit.A 163 mcg (86.9%)  <- NO es linea base real
# Si este script produce numeros muy distintos a estos, investigar la
# discrepancia ANTES de usar cualquiera de los dos (principio 5). Diferencias
# menores (<1-2%) pueden venir de detalles de redondeo/quantiles entre R y
# Python; diferencias grandes indican un bug en alguno de los dos lados.
# ============================================================================
