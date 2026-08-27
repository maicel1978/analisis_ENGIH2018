# =========================================================================
# Script: 00_master.R
# Proyecto: ENGIH 2018 - Evidencia Nutricional (WFP / MIMI)
# Fecha: 2026-08-27
#
# Objetivo: generar las DOS CAPAS MAESTRAS que consumen todas las fases
# posteriores del pipeline. Ningún script analítico debe leer fuentes
# individuales (INCAP/USDA/FNDDS) directamente (regla de gobernanza de
# VISION_Y_ARQUITECTURA_PROYECTO.md).
#
#   Entradas (se editan manualmente; única fuente de verdad):
#     data/raw/crosswalk_variedad_INCAP.xlsx   (3A, llave del CATÁLOGO)
#     data/raw/crosswalk_variedad_USDA.xlsx    (3A, llave del CATÁLOGO)
#     data/raw/crosswalk_variedad_FNDDS.xlsx   (3A, llave del CATÁLOGO)
#     data/raw/crosswalk_variedad_SEC2.xlsx    (despensa, llave FORMULARIO)
#     data/raw/food_composition_INCAP.xlsx
#     data/raw/food_composition_FNDDS.xlsx
#     data/raw/Registros_Cuestionario_B.xlsx   (hoja "Catálogo variedades")
#
#   Salidas (NUNCA editar a mano; se regeneran con este script):
#     data/master/crosswalk_variedad_MASTER.xlsx
#     data/master/food_composition_MASTER.xlsx
#
# =========================================================================
# LLAVES DE VARIEDAD (descubrimiento 2026-08-27, CRÍTICO)
#
#   La Sección 3A usa ID_VARIEDAD del CATÁLOGO de variedades (p.ej.
#   408 = Cebolla roja). La Sección 2 (despensa) usa los CÓDIGOS LOCALES
#   DEL FORMULARIO (p.ej. 2 = GALLETAS DULCES), que NO coinciden con el
#   catálogo (en el catálogo 2 = Pan sobado). El mismo número puede ser
#   un alimento distinto en cada sección, por lo que la llave canónica
#   lleva espacio de nombres:
#
#     CAT:<id>   -> llave del catálogo (Sec 3A + los 15 códigos de Sec 2
#                   que sí son códigos de catálogo)
#     SEC2:<id>  -> código local del formulario de despensa
#
# =========================================================================
# REGLAS DE INTEGRACIÓN
#
#   1. Una fila de crosswalk es UTIL (resuelta) si:
#        validado == TRUE  Y  el ID final de la fuente no está vacío.
#      Columna de ID final por fuente:
#        INCAP: ENHANCE_ID_final | USDA: USDA_FDC_ID_final | FNDDS: FNDDS_ID_final
#
#   2. Estado derivado por fila:
#        excluido  -> tipo_equivalencia == "no_alimento_excluir"
#                     (tabaco, pañales...; quedan en el MASTER para que la
#                      exclusión sea EXPLÍCITA, no silenciosa)
#        resuelto  -> regla 1 cumplida
#        pendiente -> sin ID final (con o sin revisar): visible y
#                     contabilizada; NUNCA se descarta en silencio
#
#   3. Prioridad por fuente del mismo alimento: INCAP > USDA > FNDDS.
#      Los conflictos se reportan en consola.
#
#   4. food_composition_MASTER contiene SOLO las filas referenciadas por
#      el crosswalk MASTER resuelto (tabla "viva"). Armonización:
#        - columnas estándar (ver col_estandar), unidades por 100 g;
#        - INCAP: base "100 g comestibles", pc_factor = EDIBLE (0.17-1.0)
#        - FNDDS: base "100 g como se consume", pc_factor = 1
#        - id_composicion_ns = "<FUENTE>:<id>" (evita colisiones entre
#          espacios numéricos: INCAP 702xxxxx vs FNDDS 8 dígitos).
#      NOTA: las unidades de algunas columnas INCAP (p.ej. vitamina D)
#      deben confirmarse contra el diccionario INCAP antes de publicar
#      estimaciones (ver PLAN_DE_TRABAJO.md, Fase 1.5).
#
#   5. Para reproducir: ver PLAN_DE_TRABAJO.md (Fase 0.4: dependencias;
#      KPI esperados en Fase 1).
# =========================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(here)
  library(dplyr)
  library(writexl)
})

dir.create(here("data", "master"), showWarnings = FALSE)

# Normalización determinista de nombres de columna:
# minúsculas y todo carácter no alfanumérico -> "_"
norm <- function(df) {
  nms <- tolower(gsub("[^a-z0-9]+", "_", names(df)))
  nms <- gsub("^_+|_+$", "", nms)
  names(df) <- make.unique(nms)
  df
}

# ---------------------------------------------------------------------
# 1. Lectura de crosswalks por fuente
# ---------------------------------------------------------------------
leer_crosswalk <- function(archivo, col_id_final, fuente, espacio) {
  df <- read_excel(archivo, sheet = "Datos") |> norm()
  id_ok <- setdiff(c("id_variedad", col_id_final), names(df))
  if (length(id_ok) > 0)
    stop(sprintf("Crosswalk %s: faltan columnas: %s", fuente,
                 paste(id_ok, collapse = ", ")))
  df |>
    mutate(
      fuente_composicion = fuente,
      id_composicion = .data[[col_id_final]],
      clave_variedad = if (espacio == "CAT")
        paste0("CAT:", id_variedad) else paste0("SEC2:", id_variedad)
    ) |>
    select(clave_variedad, id_variedad, starts_with("descripcion"),
           fuente_composicion, id_composicion,
           tipo_equivalencia, validado, notas, starts_with("freq"))
}

cw_incap <- leer_crosswalk(here("data", "raw", "crosswalk_variedad_INCAP.xlsx"),
                           "enhance_id_final", "INCAP", "CAT")
cw_usda  <- leer_crosswalk(here("data", "raw", "crosswalk_variedad_USDA.xlsx"),
                           "usda_fdc_id_final", "USDA", "CAT")
cw_fnnds <- leer_crosswalk(here("data", "raw", "crosswalk_variedad_FNDDS.xlsx"),
                           "fndds_id_final", "FNDDS", "CAT")

# Despensa (Sec 2): clave local del formulario. La fuente de composición
# se declara POR FILA (fuente_composicion + id_composicion_final), porque
# los gaps (pica pica, habichuelas enlatadas...) irán a USDA/FNDDS.
# Las filas con clave_catalogo no vacío resuelven el MISMO alimento en el
# espacio CAT, así que se duplican ahí (sin reemplazar resolución
# existente: la prioridad por estado/fuente se aplica al final).
raw_sec2 <- read_excel(here("data", "raw", "crosswalk_variedad_SEC2.xlsx"),
                       sheet = "Datos") |> norm()
stopifnot(all(c("id_variedad", "clave_catalogo", "fuente_composicion",
                "id_composicion_final", "tipo_equivalencia", "validado",
                "notas", "freq_sec2", "descripcion_item") %in% names(raw_sec2)))
cw_sec2 <- raw_sec2 |>
  mutate(fuente_composicion = ifelse(is.na(fuente_composicion) |
                                       fuente_composicion == "",
                                     "INCAP", fuente_composicion)) |>
  select(clave_variedad = id_variedad, id_variedad,
         starts_with("descripcion"), fuente_composicion,
         id_composicion = id_composicion_final,
         tipo_equivalencia, validado, notas,
         freq = freq_sec2) |>
  mutate(clave_variedad = paste0("SEC2:", clave_variedad)) |>
  left_join(raw_sec2 |> select(id_variedad, clave_catalogo) |>
              mutate(clave_catalogo = as.integer(clave_catalogo)),
            by = "id_variedad") |>
  mutate(clave_variedad = ifelse(!is.na(clave_catalogo),
                                 paste0("CAT:", clave_catalogo),
                                 clave_variedad))

# ---------------------------------------------------------------------
# 2. Estado por fila y resolución por prioridad de fuente
# ---------------------------------------------------------------------
derivar_estado <- function(df) {
  id_vacio <- is.na(df$id_composicion) |
    trimws(as.character(df$id_composicion)) %in% c("", "NA")
  df |>
    mutate(
      estado = case_when(
        !is.na(tipo_equivalencia) &
          tolower(trimws(as.character(tipo_equivalencia))) == "no_alimento_excluir" ~ "excluido",
        validado == TRUE & !id_vacio ~ "resuelto",
        TRUE                          ~ "pendiente"
      )
    )
}

ord_fuente <- c(INCAP = 1, USDA = 2, FNDDS = 3)
ord_estado <- c(resuelto = 0, excluido = 1, pendiente = 2)

todos <- bind_rows(cw_incap, cw_usda, cw_fnnds, cw_sec2) |>
  derivar_estado()

# Conflictos visibles: mismo alimento resuelto en más de una fuente
conflictos <- todos |>
  filter(estado == "resuelto") |>
  count(clave_variedad, fuente_composicion) |>
  group_by(clave_variedad) |>
  summarise(n = n(), .groups = "drop") |>
  filter(n > 1)
if (nrow(conflictos) > 0)
  warning("Conflictos de fuente (se usó INCAP>USDA>FNDDS): ",
          paste(conflictos$clave_variedad, collapse = ", "))

master_cw <- todos |>
  mutate(ord_e = ord_estado[estado], ord_f = ord_fuente[fuente_composicion]) |>
  arrange(clave_variedad, ord_e, ord_f) |>
  group_by(clave_variedad) |>
  slice_head(n = 1) |>
  ungroup() |>
  distinct() |>
  mutate(id_composicion_ns = ifelse(estado == "resuelto",
                                    paste(fuente_composicion, id_composicion,
                                          sep = ":"),
                                    NA_character_))

# Descripción canónica desde el catálogo (solo llaves CAT)
catalogo <- read_excel(here("data", "raw", "Registros_Cuestionario_B.xlsx"),
                       sheet = "Catálogo variedades") |>
  norm() |>
  select(id_variedad, des_variedad) |>
  mutate(clave_variedad = paste0("CAT:", id_variedad))

master_cw <- master_cw |>
  left_join(catalogo, by = "clave_variedad", suffix = c("", "_cat")) |>
  mutate(descripcion_canonica = ifelse(
    !is.na(des_variedad_cat), des_variedad_cat,
    dplyr::coalesce(descripcion_engih, NA_character_))) |>
  select(clave_variedad, descripcion_canonica, id_variedad,
         fuente_composicion, id_composicion_ns,
         tipo_equivalencia, validado, estado, notas,
         starts_with("freq"))

# ---------------------------------------------------------------------
# 3. food_composition_MASTER (solo filas referenciadas por el MASTER)
# ---------------------------------------------------------------------
col_estandar <- c("id_composicion_ns", "fuente_composicion",
                  "nombre_es", "nombre_en", "base_composicion", "pc_factor",
                  "energia_kcal", "proteina_g", "grasa_g", "carbohidratos_g",
                  "fibra_g", "azucares_g", "sodio_mg", "colesterol_mg",
                  "calcio_mg", "hierro_mg", "zinc_mg", "magnesio_mg",
                  "fosforo_mg", "potasio_mg", "selenio_mg",
                  "vitamina_a_rae_mcg", "vitamina_c_mg", "tiamina_mg",
                  "riboflavina_mg", "niacina_mg", "vitamina_b6_mg",
                  "folato_mcg", "vitamina_b12_mcg", "vitamina_d_mcg",
                  "vitamina_e_mg", "vitamina_k_mcg", "agua_g")

ref <- master_cw |>
  filter(estado == "resuelto") |>
  separate(id_composicion_ns, into = c("fuente_ref", "id_ref"), sep = ":")
ids_incap <- suppressWarnings(as.numeric(ref$id_ref[ref$fuente_ref == "INCAP"]))
ids_fnDDS <- suppressWarnings(as.numeric(ref$id_ref[ref$fuente_ref == "FNDDS"]))

# INCAP: se referencian los nombres ORIGINALES del archivo (sin limpiar)
tca_incap <- read_excel(here("data", "raw", "food_composition_INCAP.xlsx")) |>
  filter(ENHANCE_ID %in% ids_incap) |>
  transmute(
    id_composicion_ns = paste0("INCAP:", ENHANCE_ID),
    fuente_composicion = "INCAP",
    nombre_es = food_name_other,
    nombre_en = food_name_english,
    base_composicion = "100 g comestibles",
    pc_factor = EDIBLE,
    energia_kcal = ENERC_KCAL, proteina_g = PROTCNT, grasa_g = FAT,
    carbohidratos_g = coalesce(CHOAVLDF, 0),
    fibra_g = FIBTG, azucares_g = SUCS, sodio_mg = SODIUM,
    colesterol_mg = CHOLE, calcio_mg = CA, hierro_mg = FE, zinc_mg = ZN,
    magnesio_mg = MG, fosforo_mg = P, potasio_mg = K, selenio_mg = SE,
    vitamina_a_rae_mcg = VITA_RAE, vitamina_c_mg = VITC,
    tiamina_mg = THIA, riboflavina_mg = RIBF, niacina_mg = NIAEQ,
    vitamina_b6_mg = VITB6C, folato_mcg = coalesce(FOLDFE, 0),
    vitamina_b12_mcg = VITB12, vitamina_d_mcg = VITD,
    vitamina_e_mg = VITE, vitamina_k_mcg = VITK, agua_g = WATER
  )

# FNDDS: la hoja tiene una fila de título ANTES del header -> skip = 1
tca_fnDDS <- read_excel(here("data", "raw", "food_composition_FNDDS.xlsx"),
                        sheet = "FNDDS Nutrient Values", skip = 1) |>
  norm() |>
  filter(food_code %in% ids_fnDDS) |>
  transmute(
    id_composicion_ns = paste0("FNDDS:", food_code),
    fuente_composicion = "FNDDS",
    nombre_es = NA_character_,
    nombre_en = main_food_description,
    base_composicion = "100 g como se consume",
    pc_factor = 1,
    energia_kcal = energy_kcal, proteina_g = protein_g,
    grasa_g = total_fat_g, carbohidratos_g = carbohydrate_g,
    fibra_g = fiber_total_dietary_g, azucares_g = sugars_total_g,
    sodio_mg = sodium_mg, colesterol_mg = cholesterol_mg,
    calcio_mg = calcium_mg, hierro_mg = iron_mg, zinc_mg = zinc_mg,
    magnesio_mg = magnesium_mg, fosforo_mg = phosphorus_mg,
    potasio_mg = potassium_mg, selenio_mg = selenium_mcg,
    vitamina_a_rae_mcg = vitamin_a_rae_mcg_rae,
    vitamina_c_mg = vitamin_c_mg, tiamina_mg = thiamin_mg,
    riboflavina_mg = riboflavin_mg, niacina_mg = niacin_mg,
    vitamina_b6_mg = vitamin_b_6_mg, folato_mcg = folate_total_mcg,
    vitamina_b12_mcg = vitamin_b_12_mcg,
    vitamina_d_mcg = vitamin_d_d2_d3_mcg,
    vitamina_e_mg = vitamin_e_alpha_tocopherol_mg,
    vitamina_k_mcg = vitamin_k_phylloquinone_mcg, agua_g = water_g
  )

master_tca <- bind_rows(tca_incap, tca_fnDDS) |>
  select(all_of(col_estandar))

# La TCA INCAP tiene un ID duplicado con alimentos DIFERENTES (70211110:
# "Elote dulce... enlatado" y "Sal de mesa"). Deducar por id_composicion_ns
# (queda la primera ocurrencía) y reportar; avisar a MIMI del error de origen.
dups <- master_tca |>
  count(id_composicion_ns) |>
  filter(n > 1)
if (nrow(dups) > 0)
  warning("IDs de composición duplicados en origen: ",
          paste(dups$id_composicion_ns, collapse = ", "))
# Regla de dedup: por ID, prioriza la fila de SAL (caso conocido 70211110,
# que el crosswalk usa para Sal en grano CAT:4413); si no, la primera fila.
master_tca <- master_tca |>
  mutate(sal_flag = grepl("sal de mesa|table salt",
                          tolower(paste(nombre_es, nombre_en, sep = " ")))) |>
  group_by(id_composicion_ns) |>
  slice_max(order_by = sal_flag, n = 1, with_ties = TRUE) |>
  slice_head(n = 1) |>
  ungroup() |>
  distinct()

# ---------------------------------------------------------------------
# 4. Escritura + KPI en consola
# ---------------------------------------------------------------------
resumen_master <- master_cw |>
  count(estado, fuente_composicion, .drop = FALSE)

write_xlsx(list(Datos = master_cw,
                Resumen = resumen_master),
           path = here("data", "master", "crosswalk_variedad_MASTER.xlsx"))
write_xlsx(list(Datos = master_tca),
           path = here("data", "master", "food_composition_MASTER.xlsx"))

message(sprintf("crosswalk_variedad_MASTER: %d llaves | resueltas: %d | excluidas: %d | pendientes: %d",
                nrow(master_cw),
                sum(master_cw$estado == "resuelto"),
                sum(master_cw$estado == "excluido"),
                sum(master_cw$estado == "pendiente")))
message(sprintf("food_composition_MASTER: %d alimentos | INCAP: %d | FNDDS: %d",
                nrow(master_tca),
                sum(master_tca$fuente_composicion == "INCAP"),
                sum(master_tca$fuente_composicion == "FNDDS")))
message("Pendientes prioritarios (top 10 por frecuencia):")
print(master_cw |>
        filter(estado == "pendiente") |>
        arrange(dplyr::desc(coalesce(freq_registros, freq, 0L))) |>
        slice_head(n = 10) |>
        select(clave_variedad, descripcion_canonica,
               coalesce(freq_registros, freq, 0L)))
