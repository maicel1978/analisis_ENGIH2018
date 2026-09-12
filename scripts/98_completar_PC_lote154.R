# ==============================================================================
# 98_completar_PC_lote154.R
# Uso unico (2026-09-12). Borrar del repo una vez commiteado el resultado.
#
# PROBLEMA QUE RESUELVE
# El merge del crosswalk (99_aplicar_correcciones_crosswalk.R) dejo 407 alimentos
# con enhance_id, pero food_factors.xlsx solo tiene porcion comestible (PC) para
# los 253 originales. Sin PC la formula Q x FC x PC / PM no se completa, asi que
# esos 154 alimentos NO entran al calculo pese a estar mapeados.
#
# POR QUE NO REQUIERE CRITERIO
# Los 154 son todos de fuente INCAP y la tabla INCAP trae EDIBLE indexado por el
# mismo ENHANCE_ID que ya esta asignado. Es una extraccion determinista, no una
# decision. Verificado antes de escribir este script: los 154 tienen EDIBLE, sin
# nulos ni ceros.
#
# TRAZABILIDAD
# Escribe data/eda/log_PC_lote154_2026-09-12.csv con cada valor incorporado y su
# origen. El .xlsx es binario y no diffea en git; el log es la evidencia.
# ==============================================================================

library(readxl)
library(dplyr)
library(readr)
library(here)
library(janitor)

if (!requireNamespace("writexl", quietly = TRUE)) install.packages("writexl")

f_factors <- here("data", "raw", "food_factors.xlsx")
f_cross   <- here("data", "raw", "crosswalk_tablas_composicion.xlsx")
f_incap   <- here("data", "raw", "food_composition_INCAP.xlsx")

hoja_sec2  <- "Cuest. B Sec 2"
hoja_sec3a <- "Cuest. B Sec 3A"

# --- Lectura ------------------------------------------------------------------
# Todo como texto: en la hoja actual EDIBLE esta guardado como texto con coma
# decimal ("1,00"). 01_import.R ya normaliza la coma, asi que mantener texto
# evita que writexl reescriba el tipo de las filas existentes.
pc_sec2  <- read_excel(f_factors, sheet = hoja_sec2,  col_types = "text")
pc_sec3a <- read_excel(f_factors, sheet = hoja_sec3a, col_types = "text")

cw_sec3a <- read_excel(f_cross, sheet = hoja_sec3a, col_types = "text")

incap <- read_excel(f_incap, sheet = "nutrient_values") |>
  select(ENHANCE_ID, EDIBLE, food_name_other) |>
  mutate(enhance_id = as.character(as.integer(ENHANCE_ID)))

# --- Identificar el hueco -----------------------------------------------------
faltantes <- cw_sec3a |>
  filter(!is.na(enhance_id), !is.na(id_variedad)) |>
  filter(!id_variedad %in% pc_sec3a$id_variedad) |>
  mutate(enhance_id = as.character(as.integer(as.numeric(enhance_id))))

message("Alimentos con enhance_id pero sin PC: ", nrow(faltantes))

no_incap <- faltantes |> filter(fuente != "INCAP")
if (nrow(no_incap) > 0) {
  message("  De fuente distinta a INCAP (se les asigna 1.00 con justificacion): ",
          nrow(no_incap))
}

# --- Extraer EDIBLE -----------------------------------------------------------
nuevos <- faltantes |>
  left_join(incap |> select(enhance_id, EDIBLE, food_name_other), by = "enhance_id") |>
  mutate(
    edible = case_when(
      fuente == "INCAP" & !is.na(EDIBLE) ~ as.character(round(as.numeric(EDIBLE), 2)),
      fuente != "INCAP"                  ~ "1",
      TRUE                               ~ NA_character_
    ),
    notas = case_when(
      fuente == "INCAP" & !is.na(EDIBLE) ~
        paste0("PC tomado de INCAP (EDIBLE de ", food_name_other, ")"),
      fuente != "INCAP" ~
        "Fuente no reporta factor de porcion comestible; se asume 1.00 (producto procesado o ya sin parte no comestible)",
      TRUE ~ NA_character_
    )
  )

sin_resolver <- nuevos |> filter(is.na(edible))
if (nrow(sin_resolver) > 0) {
  message("\nATENCION -- ", nrow(sin_resolver),
          " alimentos no se pudieron resolver. Quedan fuera y se listan en el log.")
  print(sin_resolver |> select(id_variedad, descripcion_engih, enhance_id, fuente))
}

resueltos <- nuevos |> filter(!is.na(edible))

# --- Ensamblar ----------------------------------------------------------------
# Se respetan las columnas de la hoja existente, en su mismo orden.
nuevas_filas <- resueltos |>
  transmute(
    id_variedad,
    descripcion_engih,
    enhance_id,
    fuente,
    edible,
    notas
  ) |>
  select(any_of(names(pc_sec3a)))

pc_sec3a_nuevo <- bind_rows(pc_sec3a, nuevas_filas)

# --- Guardas ------------------------------------------------------------------
stopifnot(
  "Se perdieron filas existentes"      = nrow(pc_sec3a_nuevo) >= nrow(pc_sec3a),
  "Hay id_variedad duplicados"         = !any(duplicated(pc_sec3a_nuevo$id_variedad)),
  "Cambiaron las columnas de la hoja"  = identical(names(pc_sec3a_nuevo), names(pc_sec3a))
)

# --- Salidas ------------------------------------------------------------------
# UTF-8 con BOM: sin esto Excel abre el CSV como Latin-1 y corrompe los acentos
# (paso con el lote anterior: "KÃ©tchup" en vez de "Ketchup").
log_pc <- resueltos |>
  transmute(id_variedad, descripcion_engih, enhance_id, fuente,
            edible, nombre_incap = food_name_other, notas)

write_excel_csv(log_pc, here("data", "eda", "log_PC_lote154_2026-09-12.csv"))

writexl::write_xlsx(
  setNames(list(pc_sec2, pc_sec3a_nuevo), c(hoja_sec2, hoja_sec3a)),
  path = f_factors
)

# --- Verificacion -------------------------------------------------------------
cw_con_id <- cw_sec3a |> filter(!is.na(enhance_id), !is.na(id_variedad))
cubiertos <- sum(cw_con_id$id_variedad %in% pc_sec3a_nuevo$id_variedad)

freq <- function(df) sum(suppressWarnings(as.numeric(df$freq_registros)), na.rm = TRUE)
freq_total   <- freq(cw_sec3a)
freq_con_pc  <- freq(cw_con_id |> filter(id_variedad %in% pc_sec3a_nuevo$id_variedad))

cat("\n--------------------------------------------------\n")
cat("PC incorporados en este lote:", nrow(resueltos), "\n")
cat("Alimentos mapeados con PC:", cubiertos, "de", nrow(cw_con_id), "\n")
cat("Cobertura efectiva del calculo (Sec 3A):",
    round(100 * freq_con_pc / freq_total, 1), "% de los registros\n")
cat("Sin resolver:", nrow(sin_resolver), "\n")
cat("--------------------------------------------------\n")
cat("\nSiguiente paso: volver a correr 01_import.R y 03_transform.R\n")
cat("para que los nuevos PC entren al calculo.\n")
