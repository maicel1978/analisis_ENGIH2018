# =========================================================================
# Script: 02_eda.R (Control de calidad y caracterización - ENGIH 2018)
# Proyecto: ENGIH 2018 - Consumo de alimentos (WFP / MIMI)
# Fecha: 2026-08-16
#
# Objetivo: generar evidencia para el informe de factibilidad (ToR 4.1-4.3)
# Entradas: data/clean/data_sec2.csv, data/clean/data_sec3a.csv
# Salidas:  mensajes de diagnóstico en consola + data/eda/*.csv
#           + data/eda/*.html (reporte dlookr, opcional)
# =========================================================================

library(dplyr)
library(readr)
library(here)

# dlookr fue removido de CRAN en dic-2023 y resubmitido después. El script
# lo usa SI existe (reporte rico) y degrada a diagnóstico base R si no.
# La versión usada debe registrarse en data/eda/sessionInfo_02_eda.txt.
tiene_dlookr <- requireNamespace("dlookr", quietly = TRUE)
if (tiene_dlookr) {
  library(dlookr)
  message(sprintf("dlookr version: %s", as.character(packageVersion("dlookr"))))
} else {
  message("dlookr no instalado: usando diagnóstico base R (sección 3).")
}

data_sec2  <- read_csv2(here("data", "clean", "data_sec2.csv"),  show_col_types = FALSE)
data_sec3a <- read_csv2(here("data", "clean", "data_sec3a.csv"), show_col_types = FALSE)

dir_eda <- here("data", "eda")
if (!dir.exists(dir_eda)) dir.create(dir_eda, recursive = TRUE)

# 1. Cobertura de hogares ---------------------------------------------------
hh_sec2  <- unique(data_sec2$id)
hh_sec3a <- unique(data_sec3a$id)

cat("\n== 1. Cobertura de hogares ==\n")
cat(sprintf("Sec 2:        %d hogares únicos\n", length(hh_sec2)))
cat(sprintf("Sec 3A:       %d hogares únicos\n", length(hh_sec3a)))
cat(sprintf("En ambas:     %d hogares\n", length(intersect(hh_sec2, hh_sec3a))))
cat(sprintf("Solo Sec 2:   %d hogares\n", length(setdiff(hh_sec2, hh_sec3a))))
cat(sprintf("Solo Sec 3A:  %d hogares\n", length(setdiff(hh_sec3a, hh_sec2))))

# 2. Unidades estándar vs no estándar ----------------------------------------
# Unidades cuya conversión a gramos es un factor fijo, universal (no depende
# del alimento). Todo lo demás requiere una tabla FC específica por alimento
# (p.ej. "unidad" de plátano != "unidad" de huevo).
unidades_estandar <- c(
  "Gramos", "Kilogramos", "Libra", "Onza", "Miligramos",
  "Mililitros o CC", "Litro", "Centímetro cúbico (cc)", "Galón"
)

clasificar_unidad <- function(df) {
  df |>
    mutate(tipo_unidad = if_else(unidad_medida %in% unidades_estandar,
                                 "estándar", "no estándar")) |>
    count(tipo_unidad, name = "n_registros") |>
    mutate(pct = round(100 * n_registros / sum(n_registros), 1))
}

cat("\n== 2. Unidades estándar vs no estándar ==\n")
cat("-- Sec 2 --\n");  print(clasificar_unidad(data_sec2))
cat("-- Sec 3A --\n");  print(clasificar_unidad(data_sec3a))

ranking_no_estandar <- bind_rows(sec2 = data_sec2, sec3a = data_sec3a, .id = "seccion") |>
  filter(!unidad_medida %in% unidades_estandar) |>
  count(unidad_medida, sort = TRUE, name = "n_registros")

cat("\nTop 15 unidades no estándar más frecuentes (definen alcance de la tabla FC):\n")
print(head(ranking_no_estandar, 15))
write_csv2(ranking_no_estandar, file.path(dir_eda, "ranking_unidades_no_estandar.csv"))

# 3. Estructura, missingness y estadísticos numéricos -----------------------
# Si dlookr existe: diagnose() sobre todas las columnas + diagnose_numeric()
# SOLO sobre `cantidad` (id_unidad_medida es un código, no una cantidad).
# Si no: equivalente con base R.
diag_base <- function(df, etiqueta) {
  cat(sprintf("\n-- %s: estructura --\n", etiqueta)); print(str(df))
  num <- df |> select(where(is.numeric))
  cat(sprintf("-- %s: resumen de variables numéricas --\n", etiqueta))
  print(sapply(num, function(x) c(
    n_missing = sum(is.na(x)),
    n_zero = sum(x == 0, na.rm = TRUE),
    n_neg = sum(x < 0, na.rm = TRUE),
    min = if (!all(is.na(x))) min(x, na.rm = TRUE) else NA,
    med = if (!all(is.na(x))) median(x, na.rm = TRUE) else NA,
    max = if (!all(is.na(x))) max(x, na.rm = TRUE) else NA
  )))
}
cat("\n== 3. Diagnóstico general ==\n")
if (tiene_dlookr) {
  cat("-- dlookr::diagnose, Sec 2 --\n");  print(diagnose(data_sec2))
  cat("-- dlookr::diagnose, Sec 3A --\n"); print(diagnose(data_sec3a))
  cat("\n-- Estadísticos de `cantidad` (Sec 2) --\n")
  print(data_sec2 |> select(cantidad) |> diagnose_numeric())
  cat("\n-- Estadísticos de `cantidad` (Sec 3A) --\n")
  print(data_sec3a |> select(cantidad) |> diagnose_numeric())
} else {
  diag_base(data_sec2, "Sec 2")
  diag_base(data_sec3a, "Sec 3A")
}

# Chequeo global rápido de atípicos (referencia, NO el criterio de decisión;
# ver sección 4 para el criterio agrupado por alimento).
cat("\n-- Atípicos globales de `cantidad` (IQR), referencia --\n")
for (et in c("Sec 2", "Sec 3A")) {
  df <- if (et == "Sec 2") data_sec2 else data_sec3a
  q1 <- quantile(df$cantidad, 0.25, na.rm = TRUE)
  q3 <- quantile(df$cantidad, 0.75, na.rm = TRUE)
  iqr <- 1.5 * (q3 - q1)
  message(sprintf("%s: %d registros fuera de [Q1-1.5IQR, Q3+1.5IQR]",
                  et, sum(df$cantidad < q1 - iqr | df$cantidad > q3 + iqr,
                          na.rm = TRUE)))
}

# 4. Valores atípicos POR ALIMENTO (Paso 7 de la guía WFP) -------------------
# Regla: dentro de cada alimento, marcar como atípico un Q fuera de [P1,P99].
# NOTA: este screen se aplica sobre `cantidad` CRUDA (unidades mezcladas
# dentro de cada alimento: gramos, unidades, atados...). El Paso 7 de la
# guía WFP se aplica SOBRE GRAMOS; esa versión definitiva se genera en
# 03_transform.R (data/eda/qc_gramos_*.csv) una vez construida la FC.
detectar_atipicos <- function(df) {
  df |>
    filter(!is.na(cantidad)) |>
    group_by(id_variedad) |>
    mutate(
      p01 = quantile(cantidad, 0.01, na.rm = TRUE),
      p99 = quantile(cantidad, 0.99, na.rm = TRUE),
      atipico = cantidad < p01 | cantidad > p99
    ) |>
    ungroup()
}

atipicos_sec2  <- detectar_atipicos(data_sec2)
atipicos_sec3a <- detectar_atipicos(data_sec3a)

cat("\n== 4. Valores atípicos por alimento (P1-P99 sobre cantidad cruda) ==\n")
cat(sprintf("Sec 2:  %d de %d registros (%.1f%%)\n",
            sum(atipicos_sec2$atipico), nrow(atipicos_sec2),
            100 * mean(atipicos_sec2$atipico)))
cat(sprintf("Sec 3A: %d de %d registros (%.1f%%)\n",
            sum(atipicos_sec3a$atipico), nrow(atipicos_sec3a),
            100 * mean(atipicos_sec3a$atipico)))

top_atipicos_sec3a <- atipicos_sec3a |>
  filter(atipico) |>
  count(id_variedad, variedad, sort = TRUE, name = "n_atipicos") |>
  head(20)

cat("\nTop 20 alimentos con más valores atípicos en Sec 3A:\n")
print(top_atipicos_sec3a)
write_csv2(top_atipicos_sec3a, file.path(dir_eda, "top_atipicos_sec3a.csv"))

# 5. Cobertura del diario de 7 días en Sec 3A --------------------------------
cobertura_dias <- data_sec3a |>
  distinct(id, dia) |>
  count(id, name = "n_dias_registrados")

cat("\n== 5. Cobertura del diario (días registrados por hogar, Sec 3A) ==\n")
print(table(cobertura_dias$n_dias_registrados))
cat(sprintf("Mediana de días registrados por hogar: %.0f\n",
            median(cobertura_dias$n_dias_registrados)))

write_csv2(cobertura_dias, file.path(dir_eda, "cobertura_dias_sec3a.csv"))

# 6. Chequeos de calidad específicos (agregados 2026-08-27) -----------------
# 6a. Dia fuera de rango 1-7 en Sec 3A (afecta el promedio por 7 días)
cat("\n== 6a. Dia fuera de rango 1-7 (Sec 3A) ==\n")
dias_fuera <- data_sec3a |>
  filter(is.na(dia) | dia < 1 | dia > 7)
message(sprintf("Sec 3A: %d registros con dia fuera de 1-7 (%d hogares)",
                nrow(dias_fuera), n_distinct(dias_fuera$id)))
if (nrow(dias_fuera) > 0)
  write_csv2(dias_fuera, file.path(dir_eda, "dias_fuera_rango_3a.csv"))

# 6b. porcentaje_hogar < 100 (Sec 3A): 3.8% de los registros; decisión en
#     03_transform.R (USAR_PCT_HOGAR)
cat("\n== 6b. porcentaje_hogar (Sec 3A) ==\n")
pct <- data_sec3a |>
  count(porcentaje_hogar < 100, porcentaje_hogar == 0) |>
  rename(pct_menor_100 = `porcentaje_hogar < 100`, pct_cero = `porcentaje_hogar == 0`)
print(pct)

# 6c. Unidad de medida faltante (requiere tabla FC; bloquea conversión)
cat("\n== 6c. Unidad faltante ==\n")
message(sprintf("Sec 2:  %d | Sec 3A: %d",
                sum(is.na(data_sec2$unidad_medida)),
                sum(is.na(data_sec3a$unidad_medida))))

# 6d. Presencia de campos de presentación (clave de la conversión a gramos)
cat("\n== 6d. Campos de presentación (empaque) ==\n")
pres <- function(df) sum(!is.na(df$contenido_empaque_presentacion) &
                           df$contenido_empaque_presentacion > 0)
message(sprintf("Sec 2:  %d filas con presentación | Sec 3A: %d",
                pres(data_sec2), pres(data_sec3a)))

# 6. Reporte EDA automatizado (dlookr, OPCIONAL) -----------------------------
# Genera un HTML con estructura, missingness, normalidad y correlaciones.
# Requiere rmarkdown + dependencias de render; no corre por defecto.
# Se restringe a columnas numéricas relevantes (nunca a códigos categóricos).
generar_reporte_dlookr <- FALSE  # cambiar a TRUE para generar el HTML

if (generar_reporte_dlookr) {
  data_sec3a |>
    select(cantidad, porcentaje_hogar, factor_expansion) |>
    eda_report(output_format = "html",
               output_file = "eda_report_sec3a.html",
               output_dir = dir_eda)
}