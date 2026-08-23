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
library(dlookr)

# dlookr fue removido de CRAN en dic-2023 y resubmitido después; se deja
# registrada la versión exacta usada para poder reproducir el análisis
# si el paquete cambia o vuelve a removerse en el futuro.
message(sprintf("dlookr version: %s", as.character(packageVersion("dlookr"))))

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

# 3. Estructura, missingness y estadísticos numéricos (dlookr) --------------
# diagnose(): estructura + missingness de TODAS las columnas -> más completo
# que revisar is.na() variable por variable.
cat("\n== 3. Diagnóstico general (dlookr::diagnose) ==\n")
cat("-- Sec 2 --\n");  print(diagnose(data_sec2))
cat("-- Sec 3A --\n");  print(diagnose(data_sec3a))

# diagnose_numeric() SOLO sobre `cantidad`: min/max/ceros/negativos.
# Restringido a propósito -> id_unidad_medida es un código categórico, no
# una cantidad, y no debe tratarse como variable continua.
cat("\n-- Estadísticos de `cantidad` (Sec 2) --\n")
print(data_sec2 |> select(cantidad) |> diagnose_numeric())
cat("\n-- Estadísticos de `cantidad` (Sec 3A) --\n")
print(data_sec3a |> select(cantidad) |> diagnose_numeric())

# Chequeo global rápido de atípicos (referencia, NO el criterio de decisión;
# ver sección 4 para el criterio agrupado por alimento).
cat("\n-- Atípicos globales de `cantidad`, referencia (dlookr::diagnose_outlier) --\n")
print(data_sec2 |> select(cantidad) |> diagnose_outlier())
print(data_sec3a |> select(cantidad) |> diagnose_outlier())

# 4. Valores atípicos POR ALIMENTO (Paso 7 de la guía WFP) -------------------
# Regla: dentro de cada alimento, marcar como atípico un Q fuera de [P1,P99].
# Es el criterio metodológicamente correcto aquí (ver nota al inicio).
detectar_atipicos <- function(df) {
  df |>
    filter(!is.na(cantidad)) |>
    group_by(alimento) |>
    mutate(
      p01 = quantile(cantidad, 0.01, na.rm = TRUE),
      p99 = quantile(cantidad, 0.99, na.rm = TRUE),
      atipico = cantidad < p01 | cantidad > p99
    ) |>
    ungroup()
}

atipicos_sec2  <- detectar_atipicos(data_sec2)
atipicos_sec3a <- detectar_atipicos(data_sec3a)

cat("\n== 4. Valores atípicos por alimento (P1-P99 dentro de cada alimento) ==\n")
cat(sprintf("Sec 2:  %d de %d registros (%.1f%%)\n",
            sum(atipicos_sec2$atipico), nrow(atipicos_sec2),
            100 * mean(atipicos_sec2$atipico)))
cat(sprintf("Sec 3A: %d de %d registros (%.1f%%)\n",
            sum(atipicos_sec3a$atipico), nrow(atipicos_sec3a),
            100 * mean(atipicos_sec3a$atipico)))

top_atipicos_sec3a <- atipicos_sec3a |>
  filter(atipico) |>
  count(alimento, sort = TRUE, name = "n_atipicos") |>
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