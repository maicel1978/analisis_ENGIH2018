# ==============================================================================
# 99_aplicar_correcciones_crosswalk.R
# Uso unico (2026-09-11). Borrar del repo una vez commiteado el resultado.
#
# Carga en data/raw/crosswalk_tablas_composicion.xlsx (hoja "Cuest. B Sec 3A")
# los mapeos revisados de data/eda/crosswalk_tablas_composicion_backup.xlsx
# (hoja "para_revisar"), aplicando 15 correcciones manuales.
#
# Trazabilidad: escribe data/eda/log_merge_crosswalk_2026-09-11.csv con
# id_variedad, valor anterior, valor nuevo y motivo de CADA fila modificada.
# El .xlsx es binario y no diffea en git; el log es la evidencia auditable.
# ==============================================================================

library(readxl)
library(dplyr)
library(readr)
library(here)

if (!requireNamespace("writexl", quietly = TRUE)) install.packages("writexl")

f_cross  <- here("data", "raw", "crosswalk_tablas_composicion.xlsx")
f_backup <- here("data", "eda", "crosswalk_tablas_composicion_backup.xlsx")
hoja     <- "Cuest. B Sec 3A"

hojas <- excel_sheets(f_cross)
todas <- lapply(hojas, function(h) read_excel(f_cross, sheet = h, col_types = "text"))
names(todas) <- hojas

cw  <- todas[[hoja]]
rev <- read_excel(f_backup, sheet = "para_revisar", col_types = "text") %>%
  filter(!is.na(id_variedad)) %>%                      # descarta 4 filas vacias
  select(id_variedad, enhance_id_rev = enhance_id)

# --- 15 correcciones manuales -------------------------------------------------
# 9 errores detectados dentro del bloque marcado "OK" en revision_154_sugerencias.csv
# + 6 filas que ese archivo dejo como DUDOSA / NO
corr <- tribble(
  ~id_variedad, ~enhance_id_corr, ~motivo,
  "316",  "70212002", "Cereza: en RD es acerola, no guinda dulce (vit C 1600 vs 7 mg/100g)",
  "165",  "70207041", "Jamon ahumado: era jamon de PAVO; el generico es de cerdo",
  "121",  "70203028", "Higado de pollo: era PATE envasado, no la viscera cruda",
  "327",  "70212152", "Zapote: era zapote VERDE; el consumido es zapote mamey",
  "3807", "70213060", "Macarrones: era pasta ENLATADA c/queso; se compra pasta seca",
  "467",  "70201080", "Dulce de leche: era SUERO dulce de leche (producto distinto)",
  "529",  "70217156", "Manzanilla: era la fruta manzanita; en RD es la infusion",
  "512",  "70211140", "Perejil: era seco congelado; el generico es fresco",
  "397",  "70211144", "Rabano: eran las HOJAS; se consume la raiz",
  "398",  "70211147", "Remolacha (DUDOSA): eran las hojas; se consume la raiz",
  "277",  "70201041", "Yogurt bebible natural (DUDOSA): integro, no descremado",
  "5599", "70214127", "Pan dulce (DUDOSA): generico simple, no de coco",
  "346",  "70212120", "Pera (NO): era pepino dulce; pera importada s/cascara",
  "4199", "70207024", "Salchicha de pollo (DUDOSA): existe el codigo puro de pollo",
  "5835", "70213158", "Harina integral (DUDOSA): era harina de ARROZ integral"
)

# --- tipo_equivalencia --------------------------------------------------------
# Por defecto sustituto_por_criterio (conservador: declara que hubo criterio).
# Solo se marca "directa" donde el nombre INCAP corresponde al item de la ENGIH.
ids_directa <- as.character(c(
  608, 312, 9, 97, 3992, 171, 2473, 21, 117, 214, 297, 426, 165, 348, 528, 112,
  121, 322, 327, 169, 522, 145, 318, 321, 511, 101, 143, 412, 209, 451, 162, 335,
  208, 127, 404, 331, 415, 122, 300, 296, 5839, 295, 4611, 3, 339, 351, 92, 512,
  194, 306, 212, 170, 466, 409, 2869, 69, 125, 201, 15, 4999, 329, 22, 135, 176,
  365, 518, 561, 4707, 294, 513, 211, 253, 5958, 519, 344, 147, 62, 189, 7392,
  5875, 3007, 345, 119, 3994, 4261, 416, 7838, 520, 61, 7839, 3527, 3584, 227,
  309, 266, 5164, 81, 4668, 5600, 146, 3500, 4269, 6465, 308, 141, 142, 2887,
  6743, 398, 277, 346, 4199, 5835
))

# --- merge --------------------------------------------------------------------
antes <- cw %>% select(id_variedad, enhance_id_ant = enhance_id,
                       tipo_ant = tipo_equivalencia, descripcion_engih)

cw2 <- cw %>%
  left_join(rev,  by = "id_variedad") %>%
  left_join(corr, by = "id_variedad") %>%
  mutate(
    nuevo_id = coalesce(enhance_id_corr, enhance_id_rev),
    cambia   = !is.na(nuevo_id) & (is.na(enhance_id) | enhance_id != nuevo_id),
    enhance_id        = if_else(cambia, nuevo_id, enhance_id),
    tipo_equivalencia = if_else(cambia,
                                if_else(id_variedad %in% ids_directa,
                                        "directa", "sustituto_por_criterio"),
                                tipo_equivalencia),
    validado = if_else(cambia, "VERDADERO", validado),
    fuente   = if_else(cambia, "INCAP", fuente),
    notas    = if_else(cambia & !is.na(motivo),
                       paste0("CORREGIDO (revision manual 2026-09-11): ", motivo),
                       notas)
  )

log_cambios <- cw2 %>%
  filter(cambia) %>%
  left_join(antes %>% select(id_variedad, enhance_id_ant, tipo_ant),
            by = "id_variedad") %>%
  transmute(id_variedad, descripcion_engih, freq_registros,
            enhance_id_anterior = enhance_id_ant,
            enhance_id_nuevo    = enhance_id,
            tipo_equivalencia,
            motivo = coalesce(motivo, "Carga de sugerencia revisada (bloque 154)"))

cw2 <- cw2 %>% select(all_of(names(cw)))

# --- salidas ------------------------------------------------------------------
write_csv(log_cambios, here("data", "eda", "log_merge_crosswalk_2026-09-11.csv"))
todas[[hoja]] <- cw2
writexl::write_xlsx(todas, path = f_cross)

cat("\nFilas modificadas:", nrow(log_cambios), "\n")
cat("Filas con enhance_id:", sum(!is.na(cw2$enhance_id)), "de", nrow(cw2), "\n")
cat("Cobertura por registros:",
    round(100 * sum(as.numeric(cw2$freq_registros)[!is.na(cw2$enhance_id)], na.rm = TRUE) /
            sum(as.numeric(cw2$freq_registros), na.rm = TRUE), 1), "%\n")
cat("Filas con enhance_id pero sin tipo_equivalencia (debe ser 0):",
    sum(!is.na(cw2$enhance_id) & is.na(cw2$tipo_equivalencia)), "\n")
