# =========================================================================
# Script: 03_transform.R
# Proyecto: ENGIH 2018 - Evidencia Nutricional (WFP / MIMI)
# Fecha: 2026-08-27
#
# Fase TRANSFORMAR (esqueleto mínimo operativo).
#
# Convierte las cantidades observadas en consumo diario (g) y aporte
# nutricional, aplicando la fórmula núcleo de la guía MIMI/WFP:
#
#     Consumo diario (g) = Q × FC × PC / PM
#
#   Q  = cantidad registrada (ver abajo: campos de presentación)
#   FC = factor de conversión a gramos (por unidad)
#   PC = porción comestible (pc_factor de food_composition_MASTER)
#   PM = período de medición (constantes de configuración, abajo)
#
# Este script NO lee fuentes individuales (INCAP/USDA/FNDDS): consume
# EXCLUSIVAMENTE las capas maestras generadas por 00_master.R.
#
#   Entradas:
#     data/clean/data_sec3a.csv, data/clean/data_sec2.csv
#     data/master/crosswalk_variedad_MASTER.xlsx
#     data/master/food_composition_MASTER.xlsx
#     data/raw/data_raw_unidades.csv
#
#   Salidas:
#     data/clean/consumo_diario_3A_hogar.csv   (hogar x variedad, g/día)
#     data/clean/consumo_diario_2_hogar.csv
#     data/eda/qc_gramos_3A.csv, data/eda/qc_gramos_2.csv
#
# =========================================================================
# DECISIONES CONFIGURABLES (todas pendientes de confirmación; ver PLAN)
# =========================================================================
# PM (período de medición):
#   Sec 2  -> 7 días. El formulario oficial dice "inventario inicial y final
#              ... el día 1 y 8 de la entrevista". El valor 30 que circuló
#              antes NO aparece en el formulario. CONFIRMAR CON MIMI/BCRD.
#   Sec 3A -> 1 día por registro (diario de 7 días: cada administración es
#              el gasto del "día de ayer"); se promedia por hogar entre
#              DIAS_SEC3A = 7.
#
# Q (cantidad) y campos de presentación:
#   Cada registro puede declararse como conteo de presentaciones:
#     cantidad_unidades_presentacion × contenido_empaque_presentacion
#   (contenido expresado en la unidad declarada id_unidad_medida).
#   Evidencia en los datos: en 96-99% de las filas con presentación,
#   cantidad <= 5 y cantidad == unidades en ~72% (3A) -> cantidad es el
#   CONTEO de presentaciones, no el total en la unidad.
#   REGLA_PRESENTACION = "presentacion" (default): usa unidades×contenido
#   cuando existe; "directa": usa cantidad siempre. Las filas donde
#   cantidad != unidades se marcan pres_inconsistente (3A: 27.8% de las
#   filas con presentación; Sec 2: 76.0%) -> PREGUNTAR A BCRD/MIMI.
#
# porcentaje_hogar (3A): % de lo adquirido para consumo exclusivo del
#   hogar. Se aplica multiplicando Q × pct/100 (3.8% de los registros
#   tienen pct < 100; 630 tienen 0). Alternativa: excluirlos.
#
# Pesos (factor_anual / factor_expansion): NO se usan en perfiles por
#   hogar; se usarán en estimaciones nacionales ponderadas (fase Analizar).
# =========================================================================

suppressPackageStartupMessages({
  library(readr)
  library(readxl)
  library(here)
  library(dplyr)
})

# ----------------------------- configuración ------------------------------
PM_SEC2          <- 7
DIAS_SEC3A       <- 7
REGLA_PRESENTACION <- "presentacion"   # "presentacion" | "directa"
USAR_PCT_HOGAR   <- TRUE

NUTRIENTES <- c("energia_kcal", "proteina_g", "grasa_g", "hierro_mg",
                "zinc_mg", "vitamina_a_rae_mcg", "folato_mcg", "calcio_mg")

# FC fijas (gr por unidad) para unidades universales. Las demás (Unidad,
# Atado, Cucharada, Lata, Jarro, ...) requieren FC por alimento:
#   Sec 2 -> hoja "FC_pendientes" de crosswalk_variedad_SEC2.xlsx (~20 celdas)
#   Sec 3A -> pendiente (Fase 4 del PLAN; ~36% de los registros)
FC_FIJAS <- c("Gramos" = 1, "Kilogramos" = 1000, "Libra" = 453.59237,
              "Onza" = 28.3495231, "Miligramos" = 0.001,
              "Mililitros o CC" = 1, "Litro" = 1000,
              "Centímetro cúbico (cc)" = 1, "Galón" = 3785.411784)

# ----------------------------- lecturas -----------------------------------
sec3a  <- read_csv2(here("data", "clean", "data_sec3a.csv"), show_col_types = FALSE)
sec2   <- read_csv2(here("data", "clean", "data_sec2.csv"),  show_col_types = FALSE)
unidades <- read_csv2(here("data", "raw", "data_raw_unidades.csv"),
                      show_col_types = FALSE)
cw_master <- read_excel(here("data", "master", "crosswalk_variedad_MASTER.xlsx"),
                        sheet = "Datos")
tca_master <- read_excel(here("data", "master", "food_composition_MASTER.xlsx"),
                         sheet = "Datos")

unidades <- unidades |> mutate(fc_gramos = FC_FIJAS[des_unidad_medida])

# Llave canónica por sección (ver 00_master.R: espacios CAT:/SEC2:)
sec3a <- sec3a |> mutate(clave_variedad = paste0("CAT:", id_variedad))

clave_sec2 <- read_excel(here("data", "raw", "crosswalk_variedad_SEC2.xlsx"),
                         sheet = "Datos") |>
  select(id_variedad, clave_catalogo)
sec2 <- sec2 |>
  left_join(clave_sec2, by = "id_variedad") |>
  mutate(clave_variedad = ifelse(!is.na(clave_catalogo),
                                 paste0("CAT:", clave_catalogo),
                                 paste0("SEC2:", id_variedad)))

# Composición resoluble (solo filas resueltas del MASTER)
comp <- cw_master |>
  filter(estado == "resuelto") |>
  select(clave_variedad, id_composicion_ns) |>
  left_join(tca_master, by = "id_composicion_ns")

# ----------------------------- transformación -----------------------------
transformar <- function(df, seccion) {
  pm <- if (seccion == "3A") 1 else PM_SEC2
  divisor <- if (seccion == "3A") DIAS_SEC3A else PM_SEC2

  df <- df |>
    left_join(unidades |> select(id_unidad_medida, fc_gramos),
              by = "id_unidad_medida")

  pres <- !is.na(df$cantidad_unidades_presentacion) &
    !is.na(df$contenido_empaque_presentacion) &
    df$contenido_empaque_presentacion > 0

  g_directa  <- df$cantidad * df$fc_gramos
  g_pres     <- df$cantidad_unidades_presentacion *
    df$contenido_empaque_presentacion * df$fc_gramos
  gramos     <- if (REGLA_PRESENTACION == "presentacion")
    ifelse(pres, g_pres, g_directa) else g_directa

  df <- df |>
    mutate(
      gramos = gramos,
      # Q del hogar (3A): % adquirido para consumo exclusivo del hogar
      gramos = if (seccion == "3A" && USAR_PCT_HOGAR)
        gramos * porcentaje_hogar / 100 else gramos,
      pres_inconsistente = pres & (cantidad != cantidad_unidades_presentacion)
    ) |>
    left_join(comp, by = "clave_variedad") |>
    mutate(
      estado_composicion = ifelse(!is.na(id_composicion_ns), "resuelto",
                                  "sin_composicion"),
      # PC: gramos comestibles = gramos × pc_factor (fórmula núcleo)
      g_comestibles = gramos * pc_factor
    )
  for (n in NUTRIENTES) {
    df[[paste0(n, "_reg")]] <- df[[n]] * df$g_comestibles / 100
  }

  # --- Paso 7 (guía WFP): control de calidad SOBRE GRAMOS -----------------
  q <- df |>
    filter(!is.na(gramos), gramos > 0) |>
    group_by(clave_variedad) |>
    mutate(p01 = quantile(gramos, 0.01, na.rm = TRUE),
           p99 = quantile(gramos, 0.99, na.rm = TRUE),
           atipico = gramos < p01 | gramos > p99) |>
    ungroup()
  top_atipicos <- q |>
    filter(atipico) |>
    count(clave_variedad, descripcion_canonica, sort = TRUE, name = "n") |>
    slice_head(n = 20)
  write_csv2(top_atipicos, here("data", "eda",
                                sprintf("qc_gramos_%s.csv", seccion)))

  # --- Agregado por hogar (consumo diario) --------------------------------
  hogares <- df |>
    group_by(id, id_vivienda, clave_variedad, variedad, estado_composicion) |>
    summarise(
      n_registros = n(),
      n_convertidos = sum(!is.na(gramos)),
      g_dia = sum(gramos, na.rm = TRUE) / divisor,
      .groups = "drop"
    )

  # Nutrientes por hogar/día (agrupado por hogar x variedad; join explícito)
  nut_hogar <- df |>
    group_by(id, clave_variedad) |>
    summarise(
      across(all_of(paste0(NUTRIENTES, "_reg")),
             ~ sum(.x, na.rm = TRUE) / divisor),
      .groups = "drop"
    ) |>
    rename_with(~ paste0(.x, "_dia"), all_of(NUTRIENTES))
  hogares <- hogares |> left_join(nut_hogar, by = c("id", "clave_variedad"))

  write_csv2(hogares, here("data", "clean",
                           sprintf("consumo_diario_%s_hogar.csv", seccion)))

  # --- KPI ------------------------------------------------------------------
  tot_g <- sum(df$gramos, na.rm = TRUE)
  cov_g <- sum(df$gramos[df$estado_composicion == "resuelto"], na.rm = TRUE)
  message(sprintf("Sec %s: %d registros | convertibles a g: %d (%.1f%%) | " +
                    "composición: %d filas / %.1f%% de los gramos | " +
                    "presentación ambigua: %d | atípicos g: %d",
                  seccion, nrow(df), sum(!is.na(df$gramos)),
                  100 * mean(!is.na(df$gramos)),
                  sum(df$estado_composicion == "resuelto"),
                  100 * cov_g / tot_g,
                  sum(df$pres_inconsistente, na.rm = TRUE),
                  sum(q$atipico)))
  invisible(hogares)
}

transformar(sec3a, "3A")
transformar(sec2, "2")

# ---------------------------------------------------------------------------
# Siguiente paso: completar crosswalk_variedad_SEC2.xlsx (46 filas, starter
# en data/raw) + tabla FC de despensa -> Sec 2 se habilita sola al correr
# 00_master.R + este script. Ver PLAN_DE_TRABAJO.md (Fases 2 y 3).
# ---------------------------------------------------------------------------
